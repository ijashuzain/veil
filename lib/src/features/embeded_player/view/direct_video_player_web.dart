// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

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
  late final String _viewType;
  html.VideoElement? _videoElement;
  html.ScriptElement? _scriptElement;
  String? _videoElementId;

  @override
  void initState() {
    super.initState();
    _viewType = 'veil-direct-video-player-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final viewId = identityHashCode(this);
      final videoId = 'veil-direct-video-$viewId';
      final statusId = 'veil-direct-video-status-$viewId';
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.backgroundColor = 'black'
        ..style.overflow = 'hidden';
      final video = html.VideoElement()
        ..id = videoId
        ..controls = true
        ..autoplay = true
        ..preload = 'metadata'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.backgroundColor = 'black'
        ..style.objectFit = 'contain';
      final status = html.DivElement()
        ..id = statusId
        ..text = 'Loading stream...'
        ..style.position = 'absolute'
        ..style.left = '50%'
        ..style.bottom = '20px'
        ..style.maxWidth = 'calc(100% - 32px)'
        ..style.transform = 'translateX(-50%)'
        ..style.padding = '8px 12px'
        ..style.border = '1px solid rgba(255, 255, 255, .18)'
        ..style.borderRadius = '999px'
        ..style.backgroundColor = 'rgba(0, 0, 0, .62)'
        ..style.color = 'rgba(255, 255, 255, .78)'
        ..style.fontSize = '12px'
        ..style.fontWeight = '700'
        ..style.lineHeight = '1.3'
        ..style.textAlign = 'center'
        ..style.pointerEvents = 'none';

      _videoElement = video;
      _videoElementId = videoId;
      container.children.add(video);
      container.children.add(status);
      _attachSource(
        video: video,
        status: status,
        url: widget.url,
        videoId: videoId,
        statusId: statusId,
      );
      return container;
    });
  }

  void _attachSource({
    required html.VideoElement video,
    required html.DivElement status,
    required String url,
    required String videoId,
    required String statusId,
  }) {
    void loadNative() {
      _setStatus(status, '');
      video.src = url;
      video.load();
      unawaited(
        video.play().catchError((Object error) {
          _setStatus(status, 'Tap play to start');
        }),
      );
    }

    _setStatus(status, 'Loading stream...');
    final script = html.ScriptElement()
      ..async = true
      ..src = 'https://cdn.jsdelivr.net/npm/hls.js@1/dist/hls.min.js';
    _scriptElement = script;
    void bootstrap() {
      if (!mounted) return;

      _bootstrapHls(url: url, videoId: videoId, statusId: statusId);
    }

    script.onLoad.first.then((_) => bootstrap());
    script.onError.first.then((_) {
      if (!mounted) return;

      loadNative();
    });
    html.document.head?.append(script);
    Timer.run(bootstrap);
  }

  void _bootstrapHls({
    required String url,
    required String videoId,
    required String statusId,
  }) {
    final script = html.ScriptElement()
      ..text =
          '''
(function () {
  const sourceUrl = ${jsonEncode(url)};
  let networkRecoveries = 0;
  let hlsWaitAttempts = 0;
  let domWaitAttempts = 0;

  function attachWhenReady() {
    const video = document.getElementById(${jsonEncode(videoId)});
    const status = document.getElementById(${jsonEncode(statusId)});
    if (!video || !status) {
      domWaitAttempts += 1;
      if (domWaitAttempts <= 50) {
        setTimeout(attachWhenReady, 100);
      }
      return;
    }

    if (video.__veilHlsBootstrapped) return;
    startHls(video, status);
  }

  function setStatus(status, message) {
    status.textContent = message || '';
    status.style.opacity = message ? '1' : '0';
  }

  function requestPlay(video, status) {
    const promise = video.play();
    if (promise && typeof promise.catch === 'function') {
      promise.catch(function () {
        setStatus(status, 'Tap play to start');
      });
    }
  }

  function loadNative(video, status) {
    setStatus(status, '');
    video.src = sourceUrl;
    video.load();
    requestPlay(video, status);
  }

  function startHls(video, status) {
    if (!window.Hls) {
      hlsWaitAttempts += 1;
      if (hlsWaitAttempts <= 50) {
        setTimeout(function () {
          startHls(video, status);
        }, 100);
        return;
      }

      video.__veilHlsBootstrapped = true;
      loadNative(video, status);
      return;
    }

    if (!window.Hls.isSupported()) {
      video.__veilHlsBootstrapped = true;
      loadNative(video, status);
      return;
    }

    video.__veilHlsBootstrapped = true;
    const hls = new Hls({
      enableWorker: true,
      lowLatencyMode: false,
      backBufferLength: 90
    });
    video.__veilHls = hls;
    hls.loadSource(sourceUrl);
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED, function () {
      setStatus(status, '');
      requestPlay(video, status);
    });
    hls.on(Hls.Events.ERROR, function (_, data) {
      if (!data.fatal) return;

      if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
        networkRecoveries += 1;
        if (networkRecoveries > 2) {
          setStatus(status, 'Trying native playback...');
          hls.destroy();
          video.__veilHls = null;
          loadNative(video, status);
          return;
        }

        setStatus(status, 'Reconnecting stream...');
        hls.startLoad();
        return;
      }

      if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
        setStatus(status, 'Recovering playback...');
        hls.recoverMediaError();
        return;
      }

      setStatus(status, 'Stream could not start');
      hls.destroy();
      video.__veilHls = null;
      loadNative(video, status);
    });
    video.addEventListener('playing', function () {
      setStatus(status, '');
    });
    video.addEventListener('waiting', function () {
      setStatus(status, 'Buffering...');
    });
    video.addEventListener('error', function () {
      setStatus(status, 'Stream could not start');
    });
  }

  attachWhenReady();
})();
''';
    html.document.body?.append(script);
    script.remove();
  }

  void _setStatus(html.DivElement status, String message) {
    status.text = message;
    status.style.opacity = message.isEmpty ? '0' : '1';
  }

  @override
  void dispose() {
    final videoId = _videoElementId;
    if (videoId != null) {
      final disposeScript = html.ScriptElement()
        ..text =
            '''
(function () {
  const video = document.getElementById(${jsonEncode(videoId)});
  if (video && video.__veilHls) {
    video.__veilHls.destroy();
    video.__veilHls = null;
  }
})();
''';
      html.document.body?.append(disposeScript);
      disposeScript.remove();
    }
    _videoElement
      ?..pause()
      ..src = ''
      ..load();
    _scriptElement?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewType),
          if (widget.showCloseButton)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .62),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VeilColors.text3,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
