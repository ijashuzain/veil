import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

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
              child: Icon(
                Icons.star_rounded,
                size: size,
                color: rating >= index ? VeilColors.gold : VeilColors.bg4,
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
    final active = (rating * 2).round().clamp(0, barCount);

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
