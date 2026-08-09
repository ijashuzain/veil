import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/components/poster_art.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = 124,
    this.height = 178,
    this.showMeta = true,
  });

  final ContentItem item;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .34),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: PosterArt(
                item: item,
                width: width,
                height: height,
                radius: 14,
                showTitle: false,
              ),
            ),
            if (showMeta) ...[
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: VeilColors.gold,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: VeilColors.text2,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      '  ·  ',
                      style: TextStyle(color: VeilColors.text4, fontSize: 10),
                    ),
                    Text(
                      '${item.year}',
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: VeilColors.panelRaised.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeilColors.hairlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: icon == Icons.star_rounded
                  ? VeilColors.gold
                  : Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCircle extends StatelessWidget {
  const ActionCircle({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: VeilColors.panelRaised.withValues(alpha: .74),
            side: BorderSide(
              color: badge ? VeilColors.redSoft : VeilColors.hairlineStrong,
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: VeilColors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: VeilColors.bg1, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
