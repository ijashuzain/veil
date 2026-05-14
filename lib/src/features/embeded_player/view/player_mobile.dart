import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullscreenLandscapeWebPlayer extends StatefulWidget {
  const FullscreenLandscapeWebPlayer({
    super.key,
    required this.url,
    this.fallbackUrls = const [],
    this.showCloseButton = true,
  });

  final String url;
  final List<Uri> fallbackUrls;
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
  int? _lastLoggedProgressBucket;
  int _currentUrlIndex = 0;

  static const _wrapperBaseUrl = 'https://flutter-player.local/';

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
      ..setOnConsoleMessage(
        (message) => _log(
          'console level=${message.level.name} message='
          '${_singleLine(message.message)}',
        ),
      )
      ..setNavigationDelegate(_buildNavigationDelegate());

    _loadCurrentPlayerHtml();
    unawaited(_logInitialUserAgent());
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: (request) {
        // Block attempts to replace the wrapper page itself.
        // Sub-frame navigations are allowed so the embedded player can load.
        final isAllowed =
            !request.isMainFrame || _isAllowedMainFrameUrl(request.url);
        _log(
          '${isAllowed ? 'allow' : 'block'} navigation '
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
    _loadCurrentPlayerHtml();
  }

  void _loadCurrentPlayerHtml() {
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

  static bool _isAllowedMainFrameUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.scheme == 'about' ||
        uri.scheme == 'data' ||
        url.startsWith(_wrapperBaseUrl);
  }

  static String _buildSandboxedPlayerHtml(String url) {
    final escapedUrl = htmlEscape.convert(url);
    final summarizedUrl = jsonEncode(_summarizeUrl(url));

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
    sandbox="allow-scripts allow-same-origin allow-forms allow-presentation"
    allow="autoplay; fullscreen; picture-in-picture; encrypted-media"
    referrerpolicy="origin">
  </iframe>
  <script>
    (function () {
      const frame = document.querySelector('iframe');
      console.log('[wrapper] boot iframe=' + $summarizedUrl);

      frame.addEventListener('load', function () {
        console.log('[wrapper] iframe load event src=' + frame.src);
      });

      frame.addEventListener('error', function () {
        console.error('[wrapper] iframe error event src=' + frame.src);
      });

      window.addEventListener('error', function (event) {
        console.error(
          '[wrapper] error ' + event.message +
          ' at ' + event.filename + ':' + event.lineno
        );
      });

      window.addEventListener('unhandledrejection', function (event) {
        const reason = event.reason && event.reason.message
          ? event.reason.message
          : String(event.reason);
        console.error('[wrapper] unhandled rejection ' + reason);
      });

      window.addEventListener('pagehide', function () {
        console.log('[wrapper] pagehide');
      });

      document.addEventListener('visibilitychange', function () {
        console.log('[wrapper] visibility=' + document.visibilityState);
      });
    })();
  </script>
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
