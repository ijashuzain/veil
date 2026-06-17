import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/widgets/spoiler_text.dart';

class SocialReviewCard extends StatelessWidget {
  const SocialReviewCard({
    super.key,
    required this.review,
    required this.displayName,
    required this.onLike,
    required this.onHelpful,
    required this.onComment,
    this.onMovie,
    this.onUser,
    this.onDelete,
    this.onReport,
    this.onBlockUser,
    this.showMovieTitle = true,
  });

  final SocialEntry review;
  final String displayName;
  final VoidCallback onLike;
  final VoidCallback onHelpful;
  final VoidCallback onComment;
  final VoidCallback? onMovie;
  final VoidCallback? onUser;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlockUser;
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
              ] else if (onReport != null || onBlockUser != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<_ReviewMenuAction>(
                  tooltip: 'More actions',
                  color: VeilColors.panelRaised,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: VeilColors.text3,
                    size: 20,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _ReviewMenuAction.report:
                        onReport?.call();
                        return;
                      case _ReviewMenuAction.blockUser:
                        onBlockUser?.call();
                        return;
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (onReport != null)
                        const PopupMenuItem(
                          value: _ReviewMenuAction.report,
                          child: Text('Report review'),
                        ),
                      if (onBlockUser != null)
                        const PopupMenuItem(
                          value: _ReviewMenuAction.blockUser,
                          child: Text('Block user'),
                        ),
                    ];
                  },
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
          SpoilerText(
            text: review.review,
            isSpoiler: review.hasSpoilers,
            style: const TextStyle(color: VeilColors.text2, height: 1.42),
          ),
          if (review.hasSpoilers) ...[
            const SizedBox(height: 8),
            const _SpoilerBadge(),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ReviewAction(
                icon: review.liked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                label: review.liked ? 'Liked' : _likeLabel(review.likeCount),
                selected: review.liked,
                onTap: onLike,
              ),
              _ReviewAction(
                icon: review.helpful
                    ? Icons.verified_rounded
                    : Icons.verified_outlined,
                label: review.helpful
                    ? 'Helpful'
                    : _helpfulLabel(review.helpfulCount),
                selected: review.helpful,
                onTap: onHelpful,
              ),
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

class _SpoilerBadge extends StatelessWidget {
  const _SpoilerBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panelRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: VeilColors.gold, size: 13),
            SizedBox(width: 5),
            Text(
              'Spoilers',
              style: TextStyle(
                color: VeilColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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

String _helpfulLabel(int count) {
  if (count <= 0) return 'Helpful';
  if (count == 1) return '1 helpful';
  return '$count helpful';
}

enum _ReviewMenuAction { report, blockUser }
