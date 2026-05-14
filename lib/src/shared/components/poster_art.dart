import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/models/content_item.dart';

class PosterArt extends StatelessWidget {
  const PosterArt({
    super.key,
    required this.item,
    this.width = 128,
    this.height = 184,
    this.radius = 12,
    this.showTitle = true,
  });

  final ContentItem item;
  final double width;
  final double height;
  final double radius;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.posterUrl;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageUrl == null
            ? _GeneratedArtwork(
                item: item,
                showTitle: showTitle,
                compact: width < 120,
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: _cacheExtent(
                      width,
                      MediaQuery.devicePixelRatioOf(context),
                    ),
                    placeholder: (context, url) =>
                        SkeletonBox(width: width, height: height, radius: 0),
                    errorWidget: (context, url, error) => _GeneratedArtwork(
                      item: item,
                      showTitle: showTitle,
                      compact: width < 120,
                    ),
                  ),
                  if (showTitle) ...[
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                          stops: [.55, 1],
                        ),
                      ),
                    ),
                    _PosterTitle(item: item, compact: width < 120),
                  ],
                ],
              ),
      ),
    );
  }
}

class BackdropArt extends StatelessWidget {
  const BackdropArt({
    super.key,
    required this.item,
    this.width,
    this.height = 176,
    this.radius = 16,
    this.child,
  });

  final ContentItem item;
  final double? width;
  final double height;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.backdropUrl ?? item.posterUrl;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageUrl == null
            ? _GeneratedBackdrop(item: item, height: height, child: child)
            : Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: _cacheExtent(
                      width,
                      MediaQuery.devicePixelRatioOf(context),
                      fallback: MediaQuery.sizeOf(context).width,
                    ),
                    placeholder: (context, url) =>
                        SkeletonBox(width: width, height: height, radius: 0),
                    errorWidget: (context, url, error) =>
                        _GeneratedBackdrop(item: item, height: height),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE6000000)],
                        stops: [.30, 1],
                      ),
                    ),
                  ),
                  ?child,
                ],
              ),
      ),
    );
  }
}

class _GeneratedArtwork extends StatelessWidget {
  const _GeneratedArtwork({
    required this.item,
    required this.showTitle,
    required this.compact,
  });

  final ContentItem item;
  final bool showTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ArtworkGradient(item: item),
        CustomPaint(painter: _GrainPainter()),
        Align(
          alignment: const Alignment(0.34, -0.34),
          child: Icon(
            item.glyph,
            color: Colors.white.withValues(alpha: .42),
            size: 72,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6000000)],
              stops: [.45, 1],
            ),
          ),
        ),
        if (showTitle) _PosterTitle(item: item, compact: compact),
      ],
    );
  }
}

class _GeneratedBackdrop extends StatelessWidget {
  const _GeneratedBackdrop({
    required this.item,
    required this.height,
    this.child,
  });

  final ContentItem item;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ArtworkGradient(item: item),
        CustomPaint(painter: _GrainPainter()),
        Positioned(
          right: 20,
          top: 20,
          child: Icon(
            item.glyph,
            color: Colors.white.withValues(alpha: .38),
            size: height * .56,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6000000)],
              stops: [.30, 1],
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _ArtworkGradient extends StatelessWidget {
  const _ArtworkGradient({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final colors = item.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first,
            colors.length > 1 ? colors[1] : colors.first,
            colors.length > 2 ? colors[2] : VeilColors.red,
            VeilColors.bg0,
          ],
          stops: const [0, .38, .72, 1],
        ),
      ),
    );
  }
}

class _PosterTitle extends StatelessWidget {
  const _PosterTitle({required this.item, required this.compact});

  final ContentItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          if (!compact && item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              item.subtitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VeilColors.text2,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .055);
    for (var i = 0; i < 36; i++) {
      final dx = ((i * 37) % 100) / 100 * size.width;
      final dy = ((i * 53) % 100) / 100 * size.height;
      canvas.drawCircle(Offset(dx, dy), .7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

int? _cacheExtent(
  double? logicalWidth,
  double devicePixelRatio, {
  double? fallback,
}) {
  final width = logicalWidth;
  final resolved = width != null && width.isFinite ? width : fallback;
  if (resolved == null || !resolved.isFinite || resolved <= 0) return null;
  return (resolved * devicePixelRatio).round();
}
