import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';

class SocialReviewCard extends StatelessWidget {
  const SocialReviewCard({
    super.key,
    required this.review,
    required this.displayName,
    required this.onLike,
    required this.onComment,
    this.onMovie,
    this.onUser,
    this.onDelete,
    this.showMovieTitle = true,
  });

  final SocialEntry review;
  final String displayName;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onMovie;
  final VoidCallback? onUser;
  final VoidCallback? onDelete;
  final bool showMovieTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onUser,
                borderRadius: BorderRadius.circular(999),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: VeilColors.red.withValues(alpha: .18),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onUser,
                  child: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Text(
                '${review.rating.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Delete review',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: VeilColors.text3,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          if (showMovieTitle) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onMovie,
              child: Text(
                review.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review.review,
            style: const TextStyle(color: VeilColors.text2, height: 1.42),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ReviewAction(
                icon: review.liked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                label: review.liked ? 'Liked' : _likeLabel(review.likeCount),
                selected: review.liked,
                onTap: onLike,
              ),
              const SizedBox(width: 10),
              _ReviewAction(
                icon: Icons.mode_comment_outlined,
                label: _commentLabel(review.commentCount),
                onTap: onComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? VeilColors.red : Colors.white,
        side: BorderSide(
          color: selected ? VeilColors.red : VeilColors.hairlineStrong,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

String _likeLabel(int count) {
  if (count <= 0) return 'Like';
  if (count == 1) return '1 like';
  return '$count likes';
}

String _commentLabel(int count) {
  if (count <= 0) return 'Comment';
  if (count == 1) return '1 comment';
  return '$count comments';
}
