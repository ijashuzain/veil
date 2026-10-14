import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veil/src/features/embeded_player/utils/playback_webview_policy.dart';
import 'package:veil/src/features/embeded_player/view/mobile_playback_webview.dart';

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
  late final List<String> _playerUrls;
  int _currentUrlIndex = 0;
  int _loadGeneration = 0;
  bool _isLoading = true;
  bool _hasStalled = false;
  bool _mediaReady = false;
  bool _hasFailed = false;
  Timer? _loadWatchdog;

  static const _loadWatchdogTimeout = Duration(seconds: 25);

  @override
  void initState() {
    super.initState();
    _playerUrls = {
      widget.url,
      for (final url in widget.fallbackUrls) url.toString(),
    }.toList();
    unawaited(_setFullscreen(true));
    _startLoadWatchdog();
  }

  void _startLoadWatchdog() {
    _loadWatchdog?.cancel();
    _loadWatchdog = Timer(_loadWatchdogTimeout, () {
      if (!mounted || _mediaReady) return;
      // Page completion is not proof that an embedded video started. Never
      // auto-replace a loaded player the user may be interacting with.
      if (_isLoading && _currentUrlIndex < _playerUrls.length - 1) {
        _retry(nextFallback: true);
      } else {
        setState(() => _hasStalled = true);
      }
    });
  }

  void _retry({bool nextFallback = false}) {
    if (!mounted) return;
    setState(() {
      if (nextFallback) _currentUrlIndex += 1;
      _loadGeneration += 1;
      _isLoading = true;
      _hasStalled = false;
      _mediaReady = false;
      _hasFailed = false;
    });
    _startLoadWatchdog();
  }

  void _handleFailure(int generation, {bool force = false}) {
    if (!mounted || generation != _loadGeneration || (_mediaReady && !force)) {
      return;
    }
    if (_currentUrlIndex < _playerUrls.length - 1) {
      _retry(nextFallback: true);
    } else {
      _loadWatchdog?.cancel();
      setState(() {
        _mediaReady = false;
        _hasStalled = true;
        _hasFailed = true;
      });
    }
  }

  void _markReady(int generation, {bool media = false}) {
    if (!mounted || generation != _loadGeneration) return;
    if (media) _loadWatchdog?.cancel();
    setState(() {
      _isLoading = false;
      if (media) {
        _mediaReady = true;
        _hasStalled = false;
        _hasFailed = false;
      }
    });
  }

  void _markAwaitingPlay(int generation) {
    if (!mounted || generation != _loadGeneration || _mediaReady) return;
    _loadWatchdog?.cancel();
    setState(() {
      _isLoading = false;
      _hasStalled = false;
      _hasFailed = false;
    });
  }

  void _markPlayRequested(int generation) {
    if (!mounted || generation != _loadGeneration || _mediaReady) return;
    setState(() => _hasStalled = false);
    _startLoadWatchdog();
  }

  Future<void> _setFullscreen(bool fullscreen) async {
    try {
      await SystemChrome.setPreferredOrientations(
        fullscreen
            ? [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : DeviceOrientation.values,
      );
      if (fullscreen && !mounted) return;
      await SystemChrome.setEnabledSystemUIMode(
        fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } catch (error) {
      debugPrint('[EmbedPlayer] fullscreen configuration failed: $error');
    }
  }

  @override
  void dispose() {
    _loadWatchdog?.cancel();
    unawaited(_setFullscreen(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = _loadGeneration;
    final url = _playerUrls[_currentUrlIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobilePlaybackWebView(
              key: ValueKey('playback-webview-$generation'),
              policy: PlaybackWebViewPolicy(
                playerUrl: url,
                loadAsPage: widget.loadAsPage,
              ),
              html: widget.loadAsPage ? null : _buildSandboxedPlayerHtml(url),
              onPageReady: () => _markReady(generation),
              onMediaReady: () => _markReady(generation, media: true),
              onFailure: () => _handleFailure(generation),
              onRendererFailure: () => _handleFailure(generation, force: true),
              onAwaitingPlay: () => _markAwaitingPlay(generation),
              onPlayRequested: () => _markPlayRequested(generation),
              onMediaError: (_) => _handleFailure(generation, force: true),
            ),
          ),
          // Page subresources can hang even after video starts. Never put an
          // opaque, input-catching layer over the player while waiting for them.
          if (_isLoading && !_hasStalled)
            const Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: IgnorePointer(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          if (_hasStalled)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Center(
                  child: Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _hasFailed
                                ? 'This server could not play this video.\n'
                                      'Try another server or retry.'
                                : 'Playback is taking longer than expected.\n'
                                      'Tap play, retry, or choose another server.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const ValueKey('embed-player-retry'),
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _buildSandboxedPlayerHtml(String url) =>
      '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    html, body, iframe { margin: 0; width: 100%; height: 100%; border: 0;
      display: block; overflow: hidden; background: #000; }
  </style>
</head>
<body>
  <iframe src="${htmlEscape.convert(url)}"
    sandbox="$playbackIframeSandbox"
    allow="autoplay; fullscreen; picture-in-picture; encrypted-media"
    referrerpolicy="origin"></iframe>
</body>
</html>
''';
}
