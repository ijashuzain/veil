import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/social_review_card.dart';
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
      backgroundColor: VeilColors.bg1,
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
                  _ReviewTabs(
                    active: _tab,
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
                        onComment: () => _openCommentSheet(review),
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

  void _openCommentSheet(SocialEntry review) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeilColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .86,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a comment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Join the conversation',
                      hintStyle: const TextStyle(color: VeilColors.text3),
                      filled: true,
                      fillColor: VeilColors.bg2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: VeilColors.hairline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await ref
                            .read(socialLibraryViewModelProvider.notifier)
                            .addReviewComment(review, controller.text);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: VeilColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Post comment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }
}

class _ReviewTabs extends StatelessWidget {
  const _ReviewTabs({required this.active, required this.onChanged});

  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Row(
        children: [
          _TabChoice(
            label: 'Community',
            selected: active == 0,
            onTap: () => onChanged(0),
          ),
          _TabChoice(
            label: 'My reviews',
            selected: active == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabChoice extends StatelessWidget {
  const _TabChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? VeilColors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : VeilColors.text3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
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
