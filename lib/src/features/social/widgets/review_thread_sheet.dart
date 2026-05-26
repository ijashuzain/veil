import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/review_comment.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/spoiler_text.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';

class ReviewThreadSheet extends ConsumerStatefulWidget {
  const ReviewThreadSheet({
    super.key,
    required this.review,
    required this.displayName,
  });

  final SocialEntry review;
  final String displayName;

  @override
  ConsumerState<ReviewThreadSheet> createState() => _ReviewThreadSheetState();
}

class _ReviewThreadSheetState extends ConsumerState<ReviewThreadSheet> {
  final _controller = TextEditingController();
  List<ReviewComment> _comments = const [];
  ReviewComment? _replyingTo;
  var _loading = true;
  var _posting = false;
  var _isSpoiler = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadComments);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = !_posting && _controller.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: VeilSheetScaffold(
        title: 'Comments',
        trailing: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
          color: VeilColors.text2,
        ),
        footer: _CommentComposer(
          controller: _controller,
          replyingTo: _replyingTo,
          isSpoiler: _isSpoiler,
          canPost: canPost,
          posting: _posting,
          onChanged: () => setState(() {}),
          onClearReply: () => setState(() => _replyingTo = null),
          onToggleSpoiler: () => setState(() => _isSpoiler = !_isSpoiler),
          onPost: _postComment,
        ),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: VeilColors.red),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: VeilColors.text3),
          ),
        ),
      );
    }

    final roots = _comments.where((comment) => !comment.isReply).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final repliesByParent = <String, List<ReviewComment>>{};
    for (final reply in _comments.where((comment) => comment.isReply)) {
      repliesByParent.putIfAbsent(reply.parentCommentId!, () => []).add(reply);
    }
    for (final replies in repliesByParent.values) {
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      children: [
        _ReviewPreview(review: widget.review, displayName: widget.displayName),
        const SizedBox(height: 18),
        if (roots.isEmpty)
          const _EmptyThread()
        else
          for (final comment in roots) ...[
            _CommentTile(
              comment: comment,
              onReply: () => setState(() => _replyingTo = comment),
            ),
            for (final reply in repliesByParent[comment.id] ?? const [])
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: _CommentTile(
                  comment: reply,
                  isReply: true,
                  onReply: () => setState(() => _replyingTo = comment),
                ),
              ),
          ],
      ],
    );
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });
      final comments = await ref
          .read(socialRepositoryProvider)
          .reviewComments(widget.review);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load comments. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await ref
          .read(socialLibraryViewModelProvider.notifier)
          .addReviewComment(
            widget.review,
            body,
            parentCommentId: _replyingTo?.id,
            isSpoiler: _isSpoiler,
          );
      _controller.clear();
      _replyingTo = null;
      _isSpoiler = false;
      await _loadComments();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.review, required this.displayName});

  final SocialEntry review;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              review.title,
              style: const TextStyle(
                color: VeilColors.text3,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SpoilerText(
              text: review.review,
              isSpoiler: review.hasSpoilers,
              style: const TextStyle(color: VeilColors.text2, height: 1.42),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    this.isReply = false,
  });

  final ReviewComment comment;
  final VoidCallback onReply;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final displayName = comment.authorDisplayName.trim().isEmpty
        ? _displayName(comment.userId)
        : comment.authorDisplayName.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 10 : 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isReply
              ? VeilColors.panelRaised.withValues(alpha: .62)
              : VeilColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VeilColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: VeilColors.redSoft,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (comment.isSpoiler)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: VeilColors.gold,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SpoilerText(
                text: comment.body,
                isSpoiler: comment.isSpoiler,
                style: const TextStyle(color: VeilColors.text2, height: 1.42),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: VeilColors.text3,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.replyingTo,
    required this.isSpoiler,
    required this.canPost,
    required this.posting,
    required this.onChanged,
    required this.onClearReply,
    required this.onToggleSpoiler,
    required this.onPost,
  });

  final TextEditingController controller;
  final ReviewComment? replyingTo;
  final bool isSpoiler;
  final bool canPost;
  final bool posting;
  final VoidCallback onChanged;
  final VoidCallback onClearReply;
  final VoidCallback onToggleSpoiler;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final replyingToName = replyingTo == null
        ? ''
        : replyingTo!.authorDisplayName.trim().isEmpty
        ? _displayName(replyingTo!.userId)
        : replyingTo!.authorDisplayName.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replyingTo != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: VeilColors.panelRaised,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to $replyingToName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VeilColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClearReply,
                  borderRadius: BorderRadius.circular(999),
                  child: const Icon(
                    Icons.close_rounded,
                    color: VeilColors.text3,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          minLines: 1,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: replyingTo == null ? 'Join the conversation' : 'Reply...',
            prefixIcon: const Icon(
              Icons.mode_comment_outlined,
              color: VeilColors.text3,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            FilterChip(
              label: const Text('Spoiler'),
              avatar: const Icon(Icons.warning_amber_rounded, size: 16),
              selected: isSpoiler,
              onSelected: (_) => onToggleSpoiler(),
              selectedColor: VeilColors.redSoft,
              checkmarkColor: VeilColors.gold,
              labelStyle: TextStyle(
                color: isSpoiler ? VeilColors.gold : VeilColors.text2,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: isSpoiler
                    ? VeilColors.red.withValues(alpha: .46)
                    : VeilColors.hairline,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: canPost ? onPost : null,
              child: Text(posting ? 'Posting' : 'Post'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No comments yet. Start the conversation with a thoughtful reply.',
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
