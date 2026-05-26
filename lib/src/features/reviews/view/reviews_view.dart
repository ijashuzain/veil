import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/review_thread_sheet.dart';
import 'package:veil/src/features/social/widgets/social_review_card.dart';
import 'package:veil/src/shared/components/veil_segmented_tabs.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class ReviewsView extends ConsumerStatefulWidget {
  const ReviewsView({super.key});

  @override
  ConsumerState<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends ConsumerState<ReviewsView> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialLibraryViewModelProvider);
    final vm = ref.read(socialLibraryViewModelProvider.notifier);
    final currentUserId = ref.read(socialRepositoryProvider).currentUserId;
    final reviews = _tab == 0 ? state.globalReviews : state.reviews;

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: RefreshIndicator(
        color: VeilColors.red,
        backgroundColor: VeilColors.bg2,
        onRefresh: vm.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            VeilLayout.pageTopPadding(context),
            0,
            104,
          ),
          children: [
            AdaptiveContent(
              maxWidth: VeilLayout.readableMaxWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  VeilSegmentedTabs<int>(
                    selected: _tab,
                    segments: const [
                      VeilSegment(value: 0, label: 'Community'),
                      VeilSegment(value: 1, label: 'My reviews'),
                    ],
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 18),
                  if (reviews.isEmpty)
                    const _EmptyReviews()
                  else
                    for (final review in reviews)
                      SocialReviewCard(
                        review: review,
                        displayName: _reviewDisplayName(review),
                        onMovie: () {
                          final item = review.toContentItem();
                          DetailRoute(id: item.id, $extra: item).push(context);
                        },
                        onUser: () => UserProfileRoute(
                          id: review.userId,
                          displayName: _reviewDisplayName(review),
                        ).push(context),
                        onLike: () => vm.toggleReviewLike(review),
                        onHelpful: () => vm.toggleReviewHelpful(review),
                        onComment: () => _openCommentThread(review),
                        onDelete: review.userId == currentUserId
                            ? () => vm.deleteReview(review)
                            : null,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCommentThread(SocialEntry review) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewThreadSheet(
        review: review,
        displayName: _reviewDisplayName(review),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Reviews from Veil users will appear here once people start logging films.',
          style: TextStyle(color: VeilColors.text3, height: 1.4),
        ),
      ),
    );
  }
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}

String _reviewDisplayName(SocialEntry review) {
  if (review.authorDisplayName.trim().isNotEmpty) {
    return review.authorDisplayName.trim();
  }
  return _displayName(review.userId);
}
