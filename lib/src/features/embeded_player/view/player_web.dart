// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

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
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'veil-web-player-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final urls = [
        widget.url,
        for (final fallbackUrl in widget.fallbackUrls) fallbackUrl.toString(),
      ];
      var currentUrlIndex = 0;
      final frame = html.IFrameElement()
        ..allow = 'autoplay; fullscreen; picture-in-picture; encrypted-media'
        ..referrerPolicy = 'origin'
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-forms allow-presentation '
              'allow-popups allow-popups-to-escape-sandbox',
        )
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.backgroundColor = 'black';
      frame.onError.listen((_) {
        if (currentUrlIndex >= urls.length - 1) return;

        currentUrlIndex += 1;
        frame.src = urls[currentUrlIndex];
      });
      frame.src = urls[currentUrlIndex];
      return frame;
    });
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
                    onPressed: () => context.pop(),
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
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 18),
                child: Text(
                  'Player',
                  style: TextStyle(
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
