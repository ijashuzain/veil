import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullscreenLandscapeDirectVideoPlayer extends StatefulWidget {
  const FullscreenLandscapeDirectVideoPlayer({
    super.key,
    required this.url,
    this.title = 'Player',
    this.showCloseButton = true,
  });

  final String url;
  final String title;
  final bool showCloseButton;

  @override
  State<FullscreenLandscapeDirectVideoPlayer> createState() =>
      _FullscreenLandscapeDirectVideoPlayerState();
}

class _FullscreenLandscapeDirectVideoPlayerState
    extends State<FullscreenLandscapeDirectVideoPlayer> {
  late final WebViewController _controller;
  bool _isDisposed = false;
  int? _lastLoggedProgressBucket;

  static const _wrapperBaseUrl = 'https://cine.su/';

  @override
  void initState() {
    super.initState();

    _log('init direct=${_summarizeUrl(widget.url)}');
    unawaited(_enterFullscreenLandscape());

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

    _loadPlayerHtml();
    unawaited(_logInitialUserAgent());
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: (request) {
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

  void _loadPlayerHtml() {
    _log('load direct wrapper base=$_wrapperBaseUrl');
    unawaited(
      _controller.loadHtmlString(
        _buildDirectPlayerHtml(widget.url),
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

  static String _buildDirectPlayerHtml(String url) {
    final escapedUrl = htmlEscape.convert(url);
    final encodedUrl = jsonEncode(url);
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
      color: #fff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    body {
      display: flex;
      align-items: center;
      justify-content: center;
    }

    video {
      width: 100%;
      height: 100%;
      display: block;
      background: #000;
      object-fit: contain;
    }

    .status {
      position: fixed;
      left: 50%;
      bottom: 20px;
      max-width: calc(100% - 32px);
      transform: translateX(-50%);
      padding: 8px 12px;
      border: 1px solid rgba(255, 255, 255, .18);
      border-radius: 999px;
      background: rgba(0, 0, 0, .62);
      color: rgba(255, 255, 255, .78);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.3;
      text-align: center;
      opacity: 0;
      pointer-events: none;
      transition: opacity .18s ease;
    }

    .status.visible {
      opacity: 1;
    }
  </style>
</head>
<body>
  <video
    id="player"
    controls
    autoplay
    playsinline
    webkit-playsinline
    preload="metadata">
    <source src="$escapedUrl" type="application/vnd.apple.mpegurl">
  </video>
  <div id="status" class="status">Loading stream...</div>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1/dist/hls.min.js"></script>
  <script>
    (function () {
      const sourceUrl = $encodedUrl;
      const video = document.getElementById('player');
      const status = document.getElementById('status');
      let hls = null;
      let networkRecoveries = 0;

      console.log('[direct] boot stream=' + $summarizedUrl);

      function setStatus(message) {
        status.textContent = message || '';
        status.classList.toggle('visible', Boolean(message));
      }

      function requestPlay() {
        const promise = video.play();
        if (promise && typeof promise.catch === 'function') {
          promise.catch(function (error) {
            console.warn('[direct] autoplay paused ' + error);
            setStatus('Tap play to start');
          });
        }
      }

      function loadNative() {
        console.log('[direct] using native hls video source');
        video.src = sourceUrl;
        video.load();
        requestPlay();
      }

      function recoverFatalHlsError(data) {
        if (!hls) return;

        if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
          networkRecoveries += 1;
          if (networkRecoveries > 2) {
            console.warn('[direct] hls network retry limit reached');
            setStatus('Trying native playback...');
            hls.destroy();
            hls = null;
            loadNative();
            return;
          }

          console.warn('[direct] hls network error; retrying');
          setStatus('Reconnecting stream...');
          hls.startLoad();
          return;
        }

        if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
          console.warn('[direct] hls media error; recovering');
          setStatus('Recovering playback...');
          hls.recoverMediaError();
          return;
        }

        console.error('[direct] unrecoverable hls error');
        setStatus('Stream could not start');
        hls.destroy();
        hls = null;
        loadNative();
      }

      function loadWithHlsJs() {
        if (!window.Hls || !window.Hls.isSupported()) {
          loadNative();
          return;
        }

        console.log('[direct] using hls.js');
        setStatus('Loading stream...');
        hls = new Hls({
          enableWorker: true,
          lowLatencyMode: false,
          backBufferLength: 90
        });
        hls.loadSource(sourceUrl);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function () {
          console.log('[direct] manifest parsed');
          setStatus('');
          requestPlay();
        });
        hls.on(Hls.Events.ERROR, function (_, data) {
          console.error(
            '[direct] hls error type=' + data.type +
            ' details=' + data.details +
            ' fatal=' + data.fatal
          );
          if (data.fatal) recoverFatalHlsError(data);
        });
      }

      function start() {
        const nativeSupport =
          video.canPlayType('application/vnd.apple.mpegurl') ||
          video.canPlayType('application/x-mpegURL');
        if (nativeSupport) {
          loadNative();
        } else {
          loadWithHlsJs();
        }
      }

      video.addEventListener('loadedmetadata', function () {
        console.log(
          '[direct] metadata width=' + video.videoWidth +
          ' height=' + video.videoHeight +
          ' duration=' + video.duration
        );
      });

      video.addEventListener('playing', function () {
        console.log('[direct] playing');
        setStatus('');
      });

      video.addEventListener('waiting', function () {
        console.log('[direct] waiting');
        setStatus('Buffering...');
      });

      video.addEventListener('error', function () {
        const error = video.error;
        const code = error ? error.code : 'unknown';
        console.error('[direct] video error code=' + code);
        setStatus('Stream could not start');
      });

      window.addEventListener('error', function (event) {
        console.error(
          '[direct] error ' + event.message +
          ' at ' + event.filename + ':' + event.lineno
        );
      });

      window.addEventListener('unhandledrejection', function (event) {
        const reason = event.reason && event.reason.message
          ? event.reason.message
          : String(event.reason);
        console.error('[direct] unhandled rejection ' + reason);
      });

      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
      } else {
        start();
      }
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
    debugPrint('[DirectVideoPlayer] $message');
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
