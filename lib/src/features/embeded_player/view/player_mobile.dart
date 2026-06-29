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
  int? _lastLoggedProgressBucket;
  int _currentUrlIndex = 0;

  static const _wrapperBaseUrl = 'https://flutter-player.local/';
  static const _iOSSafariUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
      'Mobile/15E148 Safari/604.1';
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

    _controller = WebViewController()
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

  Future<void> _configurePlatformWebView() async {
    if (Platform.isAndroid) {
      try {
        await AndroidWebViewController.enableDebugging(false);
      } catch (error) {
        _log('android webview debugging unchanged: $error');
      }
    }

    final platformController = _controller.platform;
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
      onPageFinished: (url) => _log('page finished ${_summarizeUrl(url)}'),
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

    final playerUri = Uri.tryParse(_currentPlayerUrl);
    if (playerUri == null) return false;

    final allowedHosts = {playerUri.host, 'vsembed.ru'};
    return uri.scheme == playerUri.scheme &&
        allowedHosts.contains(uri.host) &&
        uri.path.startsWith('/embed/');
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
