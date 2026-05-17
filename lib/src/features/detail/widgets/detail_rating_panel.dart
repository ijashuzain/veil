import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/ratings_display.dart';
import 'package:veil/src/shared/utils/veil_rating.dart';

class DetailRatingPanel extends StatelessWidget {
  const DetailRatingPanel({
    super.key,
    required this.rating,
    required this.isFavorite,
    required this.isInWatchlist,
    required this.isWatched,
    required this.onTap,
  });

  final double rating;
  final bool isFavorite;
  final bool isInWatchlist;
  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RATINGS',
          style: TextStyle(
            color: VeilColors.text3,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: VeilColors.gold, size: 18),
            const SizedBox(width: 10),
            Expanded(child: VeilRatingBars(rating: rating)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating > 0 ? formatVeilRating(rating) : '-',
                  style: const TextStyle(
                    color: VeilColors.text2,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                VeilStarRating(rating: rating, size: 19),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: VeilColors.panelRaised,
              borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
              border: Border.all(color: VeilColors.hairline),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: VeilColors.panel,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: VeilColors.text4,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Rate, log, review + more',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isWatched || isFavorite || isInWatchlist) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isWatched
                        ? Icons.visibility_rounded
                        : isFavorite
                        ? Icons.favorite_rounded
                        : Icons.watch_later_rounded,
                    color: VeilColors.red,
                    size: 18,
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(Icons.more_horiz_rounded, color: VeilColors.text2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
