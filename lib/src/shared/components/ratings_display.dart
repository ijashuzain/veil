import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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

    if (onChanged != null) {
      return RatingBar.builder(
        initialRating: normalizedRating,
        minRating: .5,
        maxRating: max.toDouble(),
        allowHalfRating: true,
        glow: false,
        itemCount: max,
        itemSize: size,
        unratedColor: VeilColors.bg4,
        itemBuilder: (context, _) =>
            const Icon(Icons.star_rounded, color: VeilColors.gold),
        onRatingUpdate: onChanged!,
      );
    }

    return RatingBarIndicator(
      rating: normalizedRating,
      itemCount: max,
      itemSize: size,
      unratedColor: VeilColors.bg4,
      itemBuilder: (context, _) =>
          const Icon(Icons.star_rounded, color: VeilColors.gold),
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
