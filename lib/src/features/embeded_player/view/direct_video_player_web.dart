// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player_script.dart';

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
  html.DivElement? _overlay;
  html.VideoElement? _videoElement;
  html.ScriptElement? _hlsScriptElement;
  String? _videoElementId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPlayerOverlay();
    });
  }

  void _showPlayerOverlay() {
    final viewId = identityHashCode(this);
    final videoId = 'veil-direct-video-$viewId';
    final statusId = 'veil-direct-video-status-$viewId';
    final overlay = html.DivElement()
      ..id = 'veil-direct-player-overlay-$viewId'
      ..style.position = 'fixed'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.backgroundColor = 'black'
      ..style.zIndex = '2147483647'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.overflow = 'hidden';
    overlay.style.setProperty('height', '100dvh');

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

    overlay.children.add(video);
    overlay.children.add(status);

    if (widget.title.isNotEmpty) {
      overlay.children.add(_buildTitleElement(widget.title));
    }

    _overlay = overlay;
    _videoElement = video;
    _videoElementId = videoId;
    html.document.body?.append(overlay);
    _attachSource(url: widget.url, videoId: videoId, statusId: statusId);
  }

  html.DivElement _buildTitleElement(String title) {
    return html.DivElement()
      ..text = title
      ..style.position = 'absolute'
      ..style.left = '50%'
      ..style.top = 'calc(env(safe-area-inset-top, 0px) + 18px)'
      ..style.maxWidth = 'calc(100% - 96px)'
      ..style.transform = 'translateX(-50%)'
      ..style.color = 'rgba(255, 255, 255, .62)'
      ..style.fontSize = '11px'
      ..style.fontWeight = '900'
      ..style.letterSpacing = '1.2px'
      ..style.overflow = 'hidden'
      ..style.textOverflow = 'ellipsis'
      ..style.whiteSpace = 'nowrap'
      ..style.pointerEvents = 'none';
  }

  void _attachSource({
    required String url,
    required String videoId,
    required String statusId,
  }) {
    final hlsScript = html.ScriptElement()
      ..async = true
      ..src = 'https://cdn.jsdelivr.net/npm/hls.js@latest';
    _hlsScriptElement = hlsScript;

    void bootstrap() {
      if (!mounted) return;
      final script = html.ScriptElement()
        ..text = buildDirectPlayerBootstrapScript(
          url: url,
          videoId: videoId,
          statusId: statusId,
        );
      html.document.body?.append(script);
      script.remove();
    }

    hlsScript.onLoad.first.then((_) => bootstrap());
    hlsScript.onError.first.then((_) {
      if (!mounted) return;
      final video = _videoElement;
      if (video == null) return;
      video.src = url;
      video.load();
      unawaited(video.play());
    });
    html.document.head?.append(hlsScript);
    Timer.run(bootstrap);
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
    _hlsScriptElement?.remove();
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.black);
  }
}
