import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key, required this.item, this.onClose});

  final ContentItem item;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final trailerKey = item.trailerKey;
    final gutter = VeilLayout.pageGutter(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return BackdropArt(
                item: item,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                radius: 0,
              );
            },
          ),
          if (trailerKey != null && trailerKey.isNotEmpty)
            CachedNetworkImage(
              imageUrl:
                  'https://img.youtube.com/vi/$trailerKey/maxresdefault.jpg',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .52),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose ?? () => context.pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .55),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Trailer',
                          style: TextStyle(
                            color: VeilColors.text3,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .55),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: VeilColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VeilColors.red.withValues(alpha: .35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  trailerKey == null || trailerKey.isEmpty
                      ? 'Preview unavailable'
                      : 'Trailer preview',
                  style: const TextStyle(
                    color: VeilColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: gutter,
            right: gutter,
            bottom: 30,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('0:42', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                value: .28,
                                minHeight: 3,
                                backgroundColor: Color(0x33FFFFFF),
                                color: VeilColors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('2:31', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.replay_10_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 22),
                              Icon(
                                Icons.forward_10_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.subtitles_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 22),
                              Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
