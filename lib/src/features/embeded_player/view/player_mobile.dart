import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adblocker_webview/adblocker_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FullscreenLandscapeWebPlayer extends StatefulWidget {
  const FullscreenLandscapeWebPlayer({
    super.key,
    required this.url,
    this.fallbackUrls = const [],
    this.loadAsPage = false,
    this.showCloseButton = true,
  });

  final String url;
  final List<Uri> fallbackUrls;
  final bool loadAsPage;
  final bool showCloseButton;

  @override
  State<FullscreenLandscapeWebPlayer> createState() =>
      _FullscreenLandscapeWebPlayerState();
}

class _FullscreenLandscapeWebPlayerState
    extends State<FullscreenLandscapeWebPlayer> {
  late final WebViewController _controller;
  late final List<String> _playerUrls;
  bool _isDisposed = false;
  bool _isAdBlockerReady = false;
  bool _isPlayerPageLoading = true;
  bool _hasStalled = false;
  int? _lastLoggedProgressBucket;
  int _currentUrlIndex = 0;
  Timer? _loadWatchdog;

  static const _wrapperBaseUrl = 'https://flutter-player.local/';
  static const _iOSSafariUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
      'Mobile/15E148 Safari/604.1';
  static const _loadWatchdogTimeout = Duration(seconds: 25);
  static final AdBlockerWebviewController _adBlocker =
      AdBlockerWebviewController.instance;
  static Future<void>? _adBlockerInitialization;

  @override
  void initState() {
    super.initState();

    _log('init iframe=${_summarizeUrl(widget.url)}');
    unawaited(_enterFullscreenLandscape());
    _playerUrls = [
      widget.url,
      for (final fallbackUrl in widget.fallbackUrls) fallbackUrl.toString(),
    ];

    _controller = _createController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(_buildNavigationDelegate());

    unawaited(_prepareAndLoadPlayer());
  }

  Future<void> _prepareAndLoadPlayer() async {
    await _configurePlatformWebView();
    unawaited(_initializeAdBlocker());

    if (_isDisposed) return;
    _loadCurrentPlayer();
    unawaited(_logInitialUserAgent());
  }

  Future<void> _initializeAdBlocker() async {
    try {
      await _ensureAdBlockerInitialized();
      if (_isDisposed) return;

      _isAdBlockerReady = true;
      _adBlocker.resetStatistics();
    } catch (error) {
      _log('adblocker unavailable: $error');
    }
  }

  /// Web players (JW/Plyr based embeds) call `video.play()` as soon as their
  /// manifest resolves. WebKit blocks that by default and shows an endless
  /// spinner, so inline playback without a user gesture has to be enabled at
  /// controller-creation time.
  static WebViewController _createController() {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      return WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      );
    }

    return WebViewController();
  }

  Future<void> _configurePlatformWebView() async {
    final platformController = _controller.platform;

    if (Platform.isAndroid) {
      try {
        await AndroidWebViewController.enableDebugging(false);
      } catch (error) {
        _log('android webview debugging unchanged: $error');
      }

      if (platformController is AndroidWebViewController) {
        try {
          // Same reason as the WebKit configuration above: without this the
          // embed keeps buffering because autoplay never starts.
          await platformController.setMediaPlaybackRequiresUserGesture(false);
        } catch (error) {
          _log('android autoplay gesture unchanged: $error');
        }
      }
    }

    if (platformController is WebKitWebViewController) {
      try {
        await platformController.setInspectable(false);
      } catch (error) {
        _log('ios webview inspectability unchanged: $error');
      }

      try {
        await _controller.setUserAgent(_iOSSafariUserAgent);
      } catch (error) {
        _log('ios user agent unchanged: $error');
      }
    }
  }

  static Future<void> _ensureAdBlockerInitialized() {
    return _adBlockerInitialization ??= _adBlocker.initialize(
      FilterConfig(
        filterTypes: const [FilterType.easyList, FilterType.adGuard],
        blockedDomains: const ['theajack.github.io'],
      ),
    );
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: (request) {
        // Block attempts to replace the wrapper page itself.
        // Sub-frame navigations are allowed so the embedded player can load.
        final isBlockedResource = _shouldBlockResource(request.url);
        final isAllowed =
            !isBlockedResource &&
            (!request.isMainFrame || _isAllowedMainFrameUrl(request.url));
        _log(
          '${isAllowed ? 'allow' : 'block'} navigation '
          '${isBlockedResource ? 'reason=adblock ' : ''}'
          'frame=${request.isMainFrame ? 'main' : 'sub'} '
          'url=${_summarizeUrl(request.url)}',
        );
        return isAllowed
            ? NavigationDecision.navigate
            : NavigationDecision.prevent;
      },
      onPageStarted: (url) => _log('page started ${_summarizeUrl(url)}'),
      onPageFinished: (url) {
        _log('page finished ${_summarizeUrl(url)}');
        _markPlayerPageLoaded();
      },
      onProgress: (progress) {
        final bucket = progress ~/ 25;
        if (_lastLoggedProgressBucket == bucket && progress != 100) return;

        _lastLoggedProgressBucket = bucket;
        _log('load progress $progress%');
      },
      onWebResourceError: (error) {
        _log(
          'resource error code=${error.errorCode} '
          'type=${error.errorType?.name ?? 'unknown'} '
          'mainFrame=${error.isForMainFrame} '
          'url=${_summarizeUrl(error.url)} '
          'description=${_singleLine(error.description)}',
        );
      },
      onUrlChange: (change) {
        _log('url changed ${_summarizeUrl(change.url)}');
      },
      onHttpError: (error) {
        _log(
          'http error status=${error.response?.statusCode} '
          'request=${_summarizeUrl(error.request?.uri.toString())} '
          'response=${_summarizeUrl(error.response?.uri?.toString())}',
        );
        _handleHttpError(error);
      },
      onHttpAuthRequest: (request) {
        _log(
          'http auth requested host=${request.host} '
          'realm=${request.realm ?? '<none>'}; cancelling',
        );
        request.onCancel();
      },
      onSslAuthError: (error) {
        _log('ssl auth error; cancelling');
        unawaited(error.cancel());
      },
    );
  }

  bool _shouldBlockResource(String url) {
    if (!_isAdBlockerReady) return false;

    // EasyList/AdGuard rules match on generic keywords ("player", "embed",
    // "video-ads"), so they also match the provider's own scripts and frames.
    // Blocking those is what leaves the player spinning forever, so first-party
    // requests are always allowed and only third-party ads get filtered.
    if (_isFirstPartyUrl(url)) return false;

    try {
      return _adBlocker.shouldBlockResource(url);
    } catch (error) {
      _log('adblock check failed for ${_summarizeUrl(url)}: $error');
      return false;
    }
  }

  void _handleHttpError(HttpResponseError error) {
    if (error.response?.statusCode != 404) return;

    final requestUrl = error.request?.uri.toString();
    final responseUrl = error.response?.uri?.toString();
    if (!_isCurrentPlayerUrl(requestUrl) && !_isCurrentPlayerUrl(responseUrl)) {
      return;
    }

    _loadNextFallback();
  }

  bool _isCurrentPlayerUrl(String? url) => url == _currentPlayerUrl;

  String get _currentPlayerUrl => _playerUrls[_currentUrlIndex];

  void _loadNextFallback() {
    if (_isDisposed || _currentUrlIndex >= _playerUrls.length - 1) return;

    _currentUrlIndex += 1;
    _log('load fallback iframe=${_summarizeUrl(_currentPlayerUrl)}');
    _loadCurrentPlayer();
  }

  void _loadCurrentPlayer() {
    _lastLoggedProgressBucket = null;
    _startLoadWatchdog();

    if (widget.loadAsPage) {
      _log('load page=${_summarizeUrl(_currentPlayerUrl)}');
      unawaited(_controller.loadRequest(Uri.parse(_currentPlayerUrl)));
      return;
    }

    _log('load wrapper base=$_wrapperBaseUrl');
    unawaited(
      _controller.loadHtmlString(
        _buildSandboxedPlayerHtml(_currentPlayerUrl),
        baseUrl: _wrapperBaseUrl,
      ),
    );
  }

  void _startLoadWatchdog() {
    _loadWatchdog?.cancel();
    if (_isDisposed) return;

    _safeSetState(() {
      _isPlayerPageLoading = true;
      _hasStalled = false;
    });

    _loadWatchdog = Timer(_loadWatchdogTimeout, _handleLoadStalled);
  }

  void _markPlayerPageLoaded() {
    _loadWatchdog?.cancel();
    _loadWatchdog = null;
    if (_isDisposed || !_isPlayerPageLoading) return;

    _safeSetState(() {
      _isPlayerPageLoading = false;
      _hasStalled = false;
    });
  }

  void _handleLoadStalled() {
    if (_isDisposed) return;

    _log('load stalled after ${_loadWatchdogTimeout.inSeconds}s');
    if (_currentUrlIndex < _playerUrls.length - 1) {
      _loadNextFallback();
      return;
    }

    _safeSetState(() => _hasStalled = true);
  }

  void _safeSetState(VoidCallback update) {
    if (_isDisposed || !mounted) {
      update();
      return;
    }

    setState(update);
  }

  void _reloadCurrentPlayer() {
    if (_isDisposed) return;

    _log('manual retry iframe=${_summarizeUrl(_currentPlayerUrl)}');
    _loadCurrentPlayer();
  }

  Future<void> _logInitialUserAgent() async {
    try {
      final userAgent = await _controller.getUserAgent();
      if (!_isDisposed) {
        _log('userAgent=${_singleLine(userAgent ?? '<null>')}');
      }
    } catch (error) {
      _log('userAgent unavailable: $error');
    }
  }

  bool _isAllowedMainFrameUrl(String url) {
    if (widget.loadAsPage) return _isAllowedPlayerPageUrl(url);

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.scheme == 'about' ||
        uri.scheme == 'data' ||
        url.startsWith(_wrapperBaseUrl);
  }

  bool _isAllowedPlayerPageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data') return true;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;

    // Providers route between their own paths (consent gates, locale
    // redirects, /watch -> /embed hops) while the player boots. Pinning the
    // allowlist to exact paths stalls those hops, so any page on the
    // provider's own domain is allowed and everything off-domain - the ad
    // redirects - stays blocked.
    return _isFirstPartyUrl(url);
  }

  /// True when [url] belongs to the current provider's registrable domain.
  bool _isFirstPartyUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;

    final playerHost = Uri.tryParse(_currentPlayerUrl)?.host ?? '';
    if (playerHost.isEmpty) return false;

    for (final allowedHost in {playerHost, ..._extraAllowedHosts}) {
      if (_matchesHost(uri.host, allowedHost)) return true;
    }
    return false;
  }

  // Hosts the providers redirect to while resolving a stream.
  static const _extraAllowedHosts = {'vsembed.ru'};

  static bool _matchesHost(String host, String allowedHost) {
    if (host == allowedHost) return true;

    final root = _registrableDomain(allowedHost);
    return host == root || host.endsWith('.$root');
  }

  static String _registrableDomain(String host) {
    final labels = host.split('.');
    if (labels.length <= 2) return host;

    return labels.sublist(labels.length - 2).join('.');
  }

  static String _buildSandboxedPlayerHtml(String url) {
    final escapedUrl = htmlEscape.convert(url);

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta
    name="viewport"
    content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"
  >
  <style>
    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #000;
    }

    iframe {
      width: 100%;
      height: 100%;
      border: 0;
      display: block;
      background: #000;
    }
  </style>
</head>
<body>
  <iframe
    src="$escapedUrl"
    sandbox="allow-scripts allow-same-origin allow-forms allow-presentation allow-popups allow-popups-to-escape-sandbox"
    allow="autoplay; fullscreen; picture-in-picture; encrypted-media"
    referrerpolicy="origin">
  </iframe>
</body>
</html>
''';
  }

  Future<void> _enterFullscreenLandscape() async {
    _log('enter fullscreen landscape');

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _log('entered fullscreen landscape');
    } catch (error) {
      _log('enter fullscreen landscape failed: $error');
    }
  }

  Future<void> _exitFullscreenLandscape() async {
    _log('exit fullscreen landscape');

    try {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _log('exited fullscreen landscape');
    } catch (error) {
      _log('exit fullscreen landscape failed: $error');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadWatchdog?.cancel();
    _loadWatchdog = null;
    _log('dispose');
    unawaited(_exitFullscreenLandscape());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _controller)),
          if (_isPlayerPageLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: _hasStalled
                      ? _StalledPlayerMessage(onRetry: _reloadCurrentPlayer)
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          if (widget.showCloseButton)
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _log('close button pressed');
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _log(String message) {
    debugPrint('[EmbedPlayer] $message');
  }

  static String _summarizeUrl(String? url) {
    if (url == null || url.isEmpty) return '<none>';

    final uri = Uri.tryParse(url);
    if (uri == null) return _singleLine(url);

    if (uri.scheme == 'data') return 'data:length=${url.length}';
    if (uri.scheme == 'about') return url;

    if (uri.host.isEmpty) return _singleLine(url);

    final buffer = StringBuffer()
      ..write(uri.scheme)
      ..write('://')
      ..write(uri.host);

    if (uri.hasPort) {
      buffer
        ..write(':')
        ..write(uri.port);
    }

    buffer.write(uri.path.isEmpty ? '/' : uri.path);

    if (uri.hasQuery) {
      buffer.write('?queryLength=${uri.query.length}');
    }

    if (uri.hasFragment) {
      buffer.write('#fragmentLength=${uri.fragment.length}');
    }

    return buffer.toString();
  }

  static String _singleLine(String value, {int maxLength = 300}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;

    return '${compact.substring(0, maxLength)}...';
  }
}

class _StalledPlayerMessage extends StatelessWidget {
  const _StalledPlayerMessage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'This server is taking too long to respond.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Retry, or close and pick another server.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('embed-player-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
