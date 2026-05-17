import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/utils/veil_rating.dart';

class VeilStarRating extends StatelessWidget {
  const VeilStarRating({
    super.key,
    required this.rating,
    this.size = 14,
    this.max = 5,
    this.onChanged,
  });

  final double rating;
  final double size;
  final int max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = normalizeVeilRating(rating, allowUnrated: true);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 1; index <= max; index++)
          GestureDetector(
            onTap: onChanged == null
                ? null
                : () => onChanged!(index.toDouble()),
            behavior: HitTestBehavior.opaque,
            child: SizedBox.square(
              dimension: size + 1,
              child: _FilledStar(
                index: index,
                fill: (normalizedRating - (index - 1)).clamp(0, 1).toDouble(),
                size: size,
              ),
            ),
          ),
      ],
    );
  }
}

class _FilledStar extends StatelessWidget {
  const _FilledStar({
    required this.index,
    required this.fill,
    required this.size,
  });

  final int index;
  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_rounded, size: size, color: VeilColors.bg4),
        if (fill > 0)
          ClipRect(
            child: Align(
              key: ValueKey('veil-star-fill-$index'),
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: Icon(
                Icons.star_rounded,
                size: size,
                color: VeilColors.gold,
              ),
            ),
          ),
      ],
    );
  }
}

class VeilRatingBars extends StatelessWidget {
  const VeilRatingBars({
    super.key,
    required this.rating,
    this.barCount = 10,
    this.height = 54,
  });

  final double rating;
  final int barCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = normalizeVeilRating(rating, allowUnrated: true);
    final active = (normalizedRating * 2).round().clamp(0, barCount);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 1; index <= barCount; index++) ...[
            Expanded(
              child: FractionallySizedBox(
                heightFactor: _heightFactor(index),
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: index <= active
                        ? VeilColors.gold.withValues(alpha: .62)
                        : VeilColors.bg4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            if (index != barCount) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  double _heightFactor(int index) {
    const shape = [.18, .26, .34, .45, .58, .72, .86, 1.0, .84, .68];
    if (index <= shape.length) {
      return shape[index - 1];
    }
    return .5;
  }
}
