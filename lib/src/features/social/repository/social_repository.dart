import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/movie_suggestion.dart';
import 'package:veil/src/features/social/models/review_comment.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/utils/veil_rating.dart';

part 'social_repository.g.dart';

@riverpod
SocialRepository socialRepository(Ref ref) {
  return SocialRepository(client: SupabaseService.client);
}

class SocialRepository {
  SocialRepository({SupabaseClient? client, String localUserId = 'local-user'})
    : _client = client,
      _localUserId = localUserId;

  static const _storageKey = 'veil_social_entries_v1';
  static const _followStorageKey = 'veil_user_follows_v1';
  static const _followRequestStorageKey = 'veil_follow_requests_v1';
  static const _suggestionStorageKey = 'veil_movie_suggestions_v1';
  static const _profileStorageKey = 'veil_user_profiles_v1';
  static const _reviewCommentStorageKey = 'veil_review_comments_v1';
  static const _blockedUserStorageKey = 'veil_blocked_users_v1';
  static const _communityReportStorageKey = 'veil_community_reports_v1';
  static const _table = 'film_entries';
  static const _likesTable = 'review_likes';
  static const _commentsTable = 'review_comments';
  static const _reactionsTable = 'review_reactions';
  static const _followsTable = 'user_follows';
  static const _followRequestsTable = 'follow_requests';
  static const _suggestionsTable = 'movie_suggestions';
  static const _profilesTable = 'user_profiles';
  static const _blocksTable = 'user_blocks';
  static const _reportsTable = 'community_reports';
  static const deletedUserDisplayName = 'Deleted user';

  final SupabaseClient? _client;
  final String _localUserId;

  String get currentUserId => _userId;

  String get _userId => _client?.auth.currentUser?.id ?? _localUserId;

  bool get _hasAuthenticatedSupabaseUser =>
      _client != null && _client.auth.currentUser != null;

  Future<List<SocialEntry>> entries() async {
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('updated_at', ascending: false);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(SocialEntry.fromSupabaseJson)
          .toList();
    }
    return _localEntries();
  }

  Future<List<SocialEntry>> diary() async {
    final all = await entries();
    return all.where((entry) => entry.watchedOn != null).toList();
  }

  Future<List<SocialEntry>> reviews() async {
    final all = await entries();
    return all.where((entry) => entry.review.trim().isNotEmpty).toList();
  }

  Future<List<SocialEntry>> globalReviews() async {
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_table)
          .select()
          .neq('review', '')
          .order('updated_at', ascending: false)
          .limit(100);
      final reviews = rows
          .whereType<Map<String, dynamic>>()
          .map(SocialEntry.fromSupabaseJson)
          .toList();
      return _filterBlockedEntries(
        _withReviewInteractions(await _withAuthorDisplayNames(reviews)),
      );
    }
    return _filterBlockedEntries(reviews());
  }

  Future<List<SocialEntry>> entriesForUser(String userId) async {
    if (await isUserBlocked(userId)) return const [];
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(SocialEntry.fromSupabaseJson)
          .toList();
    }
    return (await entries()).where((entry) => entry.userId == userId).toList();
  }

  Future<List<SocialEntry>> watchlist() async {
    final all = await entries();
    return all.where((entry) => entry.inWatchlist).toList();
  }

  Future<List<SocialEntry>> favorites() async {
    final all = await entries();
    return all.where((entry) => entry.isFavorite).toList();
  }

  Future<SocialImportResult> importSocialEntries(
    List<SocialEntry> importedEntries,
  ) async {
    final all = await entries();
    final updatedEntries = [...all];
    var added = 0;
    var updated = 0;
    var skipped = 0;
    final changedIds = <String>{};

    for (final imported in importedEntries) {
      if (imported.title.trim().isEmpty) {
        skipped++;
        continue;
      }

      final index = _findImportMatch(updatedEntries, imported);
      final existing = index == -1 ? null : updatedEntries[index];
      final next = _mergeImportedEntry(existing, imported);

      if (index == -1) {
        added++;
        updatedEntries.insert(0, next);
      } else {
        updated++;
        updatedEntries[index] = next;
      }
      changedIds.add(next.id);
    }

    final ordered = [
      ...updatedEntries.where((entry) => changedIds.contains(entry.id)),
      ...updatedEntries.where((entry) => !changedIds.contains(entry.id)),
    ];

    if (_hasAuthenticatedSupabaseUser) {
      for (final entry in ordered.where(
        (entry) => changedIds.contains(entry.id),
      )) {
        await _client!
            .from(_table)
            .upsert(entry.toSupabaseJson(userId: _userId));
      }
    } else {
      await _saveLocalEntries(ordered);
    }

    return SocialImportResult(
      added: added,
      updated: updated,
      skipped: skipped,
      entries: ordered,
    );
  }

  Future<SocialEntry> logWatched(
    ContentItem item, {
    double rating = 0,
    String review = '',
    List<String> tags = const [],
    DateTime? watchedOn,
  }) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        return (existing ?? fresh).copyWith(
          rating: _normalizeOptionalRating(rating),
          review: review,
          tags: tags,
          watchedOn: watchedOn ?? DateTime.now(),
          inWatchlist: false,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> rateReview(
    ContentItem item, {
    required double rating,
    required String review,
    List<String> tags = const [],
  }) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        return base.copyWith(
          rating: _clampRating(rating),
          review: review,
          tags: _mergeReviewTags(base.tags, tags),
          watchedOn: base.watchedOn ?? DateTime.now(),
          inWatchlist: false,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> rate(
    ContentItem item, {
    required double rating,
    List<String> tags = const [],
  }) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        return base.copyWith(
          rating: _clampRating(rating),
          tags: tags.isEmpty ? base.tags : tags,
          watchedOn: base.watchedOn ?? DateTime.now(),
          inWatchlist: false,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> setWatched(
    ContentItem item, {
    required bool watched,
    double rating = 0,
    List<String> tags = const [],
  }) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        return base.copyWith(
          rating: watched
              ? rating == 0
                    ? base.rating
                    : _clampRating(rating)
              : 0,
          tags: tags.isEmpty ? base.tags : tags,
          watchedOn: watched ? base.watchedOn ?? DateTime.now() : null,
          inWatchlist: watched ? false : base.inWatchlist,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> toggleWatchlist(ContentItem item) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        final next = !base.inWatchlist;
        return base.copyWith(
          inWatchlist: next,
          rating: next ? 0 : base.rating,
          watchedOn: next ? null : base.watchedOn,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> setWatchlist(
    ContentItem item, {
    required bool inWatchlist,
    double rating = 0,
  }) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        return base.copyWith(
          inWatchlist: inWatchlist,
          rating: inWatchlist
              ? 0
              : rating == 0
              ? base.rating
              : _clampRating(rating),
          watchedOn: inWatchlist ? null : base.watchedOn,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> toggleFavorite(ContentItem item) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        final base = existing ?? fresh;
        return base.copyWith(
          isFavorite: !base.isFavorite,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<SocialEntry> setLiked(ContentItem item, {required bool liked}) {
    return _upsertFromItem(
      item,
      transform: (existing, fresh) {
        return (existing ?? fresh).copyWith(
          liked: liked,
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> remove(SocialEntry entry) async {
    if (_hasAuthenticatedSupabaseUser) {
      await _client!
          .from(_table)
          .delete()
          .eq('id', entry.id)
          .eq('user_id', _userId);
      return;
    }
    final remaining = (await _localEntries())
        .where((candidate) => candidate.id != entry.id)
        .toList();
    await _saveLocalEntries(remaining);
  }

  Future<SocialEntry> deleteReview(SocialEntry review) {
    return _upsertFromItem(
      review.toContentItem(),
      transform: (existing, fresh) {
        final base = existing ?? review;
        return base.copyWith(
          review: '',
          tags: const [],
          updatedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> deleteCurrentAccount({required String reason}) async {
    final trimmedReason = reason.trim();
    if (_hasAuthenticatedSupabaseUser) {
      await _client!.rpc(
        'delete_current_account',
        params: {'delete_reason': trimmedReason},
      );
      return;
    }

    final now = DateTime.now();
    final retainedReviews = (await _localEntries())
        .where((entry) => entry.review.trim().isNotEmpty)
        .map(
          (entry) => entry.copyWith(
            watchedOn: null,
            isFavorite: false,
            inWatchlist: false,
            liked: false,
            helpful: false,
            authorDisplayName: deletedUserDisplayName,
            updatedAt: now,
          ),
        )
        .toList();
    await _saveLocalEntries(retainedReviews);

    final follows = await _localFollows();
    await _saveLocalFollows(
      follows
          .where(
            (follow) =>
                follow.followerId != _userId && follow.followingId != _userId,
          )
          .toList(),
    );

    final requests = await _localFollowRequests();
    await _saveLocalFollowRequests(
      requests
          .where(
            (request) =>
                request.requesterId != _userId &&
                request.recipientId != _userId,
          )
          .toList(),
    );

    final suggestions = await _localMovieSuggestions();
    await _saveLocalMovieSuggestions(
      suggestions
          .where(
            (suggestion) =>
                suggestion.senderId != _userId &&
                suggestion.recipientId != _userId,
          )
          .toList(),
    );
  }

  Future<SocialEntry> toggleReviewLike(SocialEntry review) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      final base = await _localReviewInteractionBase(review);
      final liked = !base.liked;
      final likeCount = (base.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 31);
      final next = base.copyWith(
        liked: liked,
        likeCount: likeCount,
        updatedAt: DateTime.now(),
      );
      await _saveLocalInteraction(next);
      return next;
    }
    final existing = await client
        .from(_likesTable)
        .select()
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (existing == null) {
      await client.from(_likesTable).insert({
        'review_user_id': review.userId,
        'review_id': review.id,
        'user_id': _userId,
      });
    } else {
      await client
          .from(_likesTable)
          .delete()
          .eq('review_user_id', review.userId)
          .eq('review_id', review.id)
          .eq('user_id', _userId);
    }
    return review.copyWith(
      liked: existing == null,
      likeCount: await reviewLikeCount(review),
      updatedAt: DateTime.now(),
    );
  }

  Future<SocialEntry> toggleReviewHelpful(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      final base = await _localReviewInteractionBase(review);
      final helpful = !base.helpful;
      final helpfulCount = (base.helpfulCount + (helpful ? 1 : -1)).clamp(
        0,
        1 << 31,
      );
      final next = base.copyWith(
        helpful: helpful,
        helpfulCount: helpfulCount,
        updatedAt: DateTime.now(),
      );
      await _saveLocalInteraction(next);
      return next;
    }

    final client = _client!;
    final existing = await client
        .from(_reactionsTable)
        .select()
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .eq('user_id', _userId)
        .eq('reaction_type', 'helpful')
        .maybeSingle();
    if (existing == null) {
      await client.from(_reactionsTable).insert({
        'review_user_id': review.userId,
        'review_id': review.id,
        'user_id': _userId,
        'reaction_type': 'helpful',
      });
    } else {
      await client
          .from(_reactionsTable)
          .delete()
          .eq('review_user_id', review.userId)
          .eq('review_id', review.id)
          .eq('user_id', _userId)
          .eq('reaction_type', 'helpful');
    }
    return review.copyWith(
      helpful: existing == null,
      helpfulCount: await reviewHelpfulCount(review),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<ReviewComment>> reviewComments(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      final comments = await _localReviewComments();
      return (await _filterBlockedComments(
        comments
            .where(
              (comment) =>
                  comment.reviewUserId == review.userId &&
                  comment.reviewId == review.id,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      )).toList();
    }

    final rows = await _client!
        .from(_commentsTable)
        .select()
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .order('created_at', ascending: true);
    final comments = rows
        .whereType<Map<String, dynamic>>()
        .map(ReviewComment.fromSupabaseJson)
        .toList();
    return _filterBlockedComments(_withCommentAuthorDisplayNames(comments));
  }

  Future<List<String>> blockedUserIds() async {
    final blockedIds = <String>{
      for (final block in await _localUserBlocks())
        if (block.blockerId == _userId) block.blockedUserId,
    };

    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_blocksTable)
          .select('blocked_user_id')
          .eq('blocker_id', _userId);
      blockedIds.addAll(
        rows
            .whereType<Map<String, dynamic>>()
            .map((row) => row['blocked_user_id'] as String?)
            .whereType<String>(),
      );
    }

    return blockedIds.toList();
  }

  Future<bool> isUserBlocked(String userId) async {
    if (userId.trim().isEmpty || userId == _userId) return false;
    return (await blockedUserIds()).contains(userId);
  }

  Future<void> blockUser(String userId, {String displayName = ''}) async {
    if (userId.trim().isEmpty || userId == _userId) return;

    final block = _UserBlock(
      blockerId: _userId,
      blockedUserId: userId,
      blockedDisplayName: displayName,
      createdAt: DateTime.now(),
    );

    if (_hasAuthenticatedSupabaseUser) {
      await _client!.from(_blocksTable).upsert(block.toSupabaseInsertJson());
      await unfollowUser(userId);
    }

    final existing = await _localUserBlocks();
    await _saveLocalUserBlocks([
      block,
      ...existing.where(
        (candidate) =>
            candidate.blockerId != _userId || candidate.blockedUserId != userId,
      ),
    ]);
    await _removeLocalConnections(userId);
  }

  Future<void> unblockUser(String userId) async {
    if (userId.trim().isEmpty || userId == _userId) return;

    if (_hasAuthenticatedSupabaseUser) {
      await _client!
          .from(_blocksTable)
          .delete()
          .eq('blocker_id', _userId)
          .eq('blocked_user_id', userId);
    }

    final existing = await _localUserBlocks();
    await _saveLocalUserBlocks(
      existing
          .where(
            (candidate) =>
                candidate.blockerId != _userId ||
                candidate.blockedUserId != userId,
          )
          .toList(),
    );
  }

  Future<void> reportReview(
    SocialEntry review, {
    required String reason,
    String details = '',
  }) {
    return _saveCommunityReport(
      _CommunityReport.create(
        reporterId: _userId,
        targetType: 'review',
        targetUserId: review.userId,
        contentId: review.id,
        parentContentId: review.tmdbId?.toString(),
        reason: reason,
        details: details,
      ),
    );
  }

  Future<void> reportComment(
    ReviewComment comment, {
    required String reason,
    String details = '',
  }) {
    return _saveCommunityReport(
      _CommunityReport.create(
        reporterId: _userId,
        targetType: 'comment',
        targetUserId: comment.userId,
        contentId: comment.id,
        parentContentId: comment.reviewId,
        reason: reason,
        details: details,
      ),
    );
  }

  Future<void> reportUser(
    String userId, {
    required String reason,
    String details = '',
  }) {
    return _saveCommunityReport(
      _CommunityReport.create(
        reporterId: _userId,
        targetType: 'profile',
        targetUserId: userId,
        contentId: userId,
        reason: reason,
        details: details,
      ),
    );
  }

  Future<SocialEntry> addReviewComment(
    SocialEntry review,
    String body, {
    String? parentCommentId,
    bool isSpoiler = false,
  }) async {
    if (body.trim().isEmpty) return review;
    if (!_hasAuthenticatedSupabaseUser) {
      final comment = ReviewComment.create(
        reviewUserId: review.userId,
        reviewId: review.id,
        userId: _userId,
        body: body,
        parentCommentId: parentCommentId,
        isSpoiler: isSpoiler,
        authorDisplayName: _displayName(_userId),
      );
      final comments = await _localReviewComments();
      await _saveLocalReviewComments([...comments, comment]);
      final base = await _localReviewInteractionBase(review);
      final next = base.copyWith(
        commentCount: base.commentCount + 1,
        updatedAt: DateTime.now(),
      );
      await _saveLocalInteraction(next);
      return next;
    }
    await _client!.from(_commentsTable).insert({
      'review_user_id': review.userId,
      'review_id': review.id,
      'user_id': _userId,
      'body': body.trim(),
      'parent_comment_id': parentCommentId,
      'is_spoiler': isSpoiler,
    });
    return review.copyWith(
      commentCount: await reviewCommentCount(review),
      updatedAt: DateTime.now(),
    );
  }

  Future<int> reviewLikeCount(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      return (await _localReviewInteractionBase(review)).likeCount;
    }
    final rows = await _client!
        .from(_likesTable)
        .select('user_id')
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id);
    return rows.length;
  }

  Future<int> reviewCommentCount(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      return (await _localReviewInteractionBase(review)).commentCount;
    }
    final rows = await _client!
        .from(_commentsTable)
        .select('id')
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id);
    return rows.length;
  }

  Future<int> reviewHelpfulCount(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      return (await _localReviewInteractionBase(review)).helpfulCount;
    }
    final rows = await _client!
        .from(_reactionsTable)
        .select('user_id')
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .eq('reaction_type', 'helpful');
    return rows.length;
  }

  Future<List<SocialEntry>> _withReviewInteractions(
    List<SocialEntry> reviews,
  ) async {
    if (!_hasAuthenticatedSupabaseUser || reviews.isEmpty) return reviews;
    return Future.wait(
      reviews.map((review) async {
        return review.copyWith(
          liked: await _hasReviewLike(review),
          likeCount: await reviewLikeCount(review),
          helpful: await _hasReviewReaction(review, 'helpful'),
          helpfulCount: await reviewHelpfulCount(review),
          commentCount: await reviewCommentCount(review),
        );
      }),
    );
  }

  Future<bool> _hasReviewLike(SocialEntry review) async {
    if (!_hasAuthenticatedSupabaseUser) {
      return (await _localReviewInteractionBase(review)).liked;
    }
    final row = await _client!
        .from(_likesTable)
        .select('user_id')
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .eq('user_id', _userId)
        .maybeSingle();
    return row != null;
  }

  Future<bool> _hasReviewReaction(
    SocialEntry review,
    String reactionType,
  ) async {
    if (!_hasAuthenticatedSupabaseUser) {
      final base = await _localReviewInteractionBase(review);
      return reactionType == 'helpful' && base.helpful;
    }
    final row = await _client!
        .from(_reactionsTable)
        .select('user_id')
        .eq('review_user_id', review.userId)
        .eq('review_id', review.id)
        .eq('user_id', _userId)
        .eq('reaction_type', reactionType)
        .maybeSingle();
    return row != null;
  }

  Future<List<ReviewComment>> _withCommentAuthorDisplayNames(
    List<ReviewComment> comments,
  ) async {
    if (comments.isEmpty) return comments;
    final deletedUserIds = await _deletedUserIdsFor(
      comments.map((comment) => comment.userId),
    );
    final profiles = await userProfilesForIds(
      comments.map((comment) => comment.userId).toSet().toList(),
    );
    final namesById = {
      for (final profile in profiles) profile.userId: profile.displayName,
    };
    return [
      for (final comment in comments)
        comment.copyWith(
          authorDisplayName: deletedUserIds.contains(comment.userId)
              ? deletedUserDisplayName
              : namesById[comment.userId] ?? _displayName(comment.userId),
        ),
    ];
  }

  Future<List<SocialEntry>> _withAuthorDisplayNames(
    List<SocialEntry> entries,
  ) async {
    if (!_hasAuthenticatedSupabaseUser || entries.isEmpty) return entries;
    final deletedUserIds = await _deletedUserIdsFor(
      entries.map((entry) => entry.userId),
    );
    if (deletedUserIds.isEmpty) return entries;
    return [
      for (final entry in entries)
        deletedUserIds.contains(entry.userId)
            ? entry.copyWith(authorDisplayName: deletedUserDisplayName)
            : entry,
    ];
  }

  Future<Set<String>> _deletedUserIdsFor(Iterable<String> userIds) async {
    if (!_hasAuthenticatedSupabaseUser) return const <String>{};
    final deletedUserIds = <String>{};
    for (final userId in userIds.toSet()) {
      try {
        final row = await _client!
            .from(_profilesTable)
            .select('is_deleted')
            .eq('user_id', userId)
            .maybeSingle();
        if (row?['is_deleted'] == true) {
          deletedUserIds.add(userId);
        }
      } catch (_) {
        return const <String>{};
      }
    }
    return deletedUserIds;
  }

  Future<void> cacheUserProfile(UserProfileSummary profile) async {
    if (profile.userId.trim().isEmpty) return;
    final profiles = await _localUserProfiles();
    final next = [
      profile,
      ...profiles.where((candidate) => candidate.userId != profile.userId),
    ];
    await _saveLocalUserProfiles(next);
  }

  Future<List<UserProfileSummary>> searchUserProfiles(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    if (_hasAuthenticatedSupabaseUser) {
      try {
        final rows = await _client!.rpc(
          'search_user_profiles',
          params: {'search_query': trimmed, 'max_results': limit},
        );
        if (rows is List) {
          return _filterBlockedProfiles(
            rows
                .whereType<Map<String, dynamic>>()
                .map(UserProfileSummary.fromSupabaseJson)
                .where((profile) => profile.userId.isNotEmpty)
                .toList(),
          );
        }
      } catch (_) {
        // Fall through to the local cache so search still works in tests and
        // while Supabase migrations are being rolled out.
      }
    }

    final normalized = trimmed.toLowerCase();
    final profiles = await _localUserProfiles();
    return _filterBlockedProfiles(
      profiles
          .where(
            (profile) =>
                profile.userId.toLowerCase().contains(normalized) ||
                profile.displayName.toLowerCase().contains(normalized),
          )
          .take(limit)
          .toList(),
    );
  }

  Future<List<UserProfileSummary>> userProfilesForIds(
    List<String> userIds,
  ) async {
    final blockedIds = (await blockedUserIds()).toSet();
    final ids = userIds
        .where((id) => id.trim().isNotEmpty && !blockedIds.contains(id))
        .toSet()
        .toList();
    if (ids.isEmpty) return const [];

    if (_hasAuthenticatedSupabaseUser) {
      try {
        final rows = await _client!.rpc(
          'user_profiles_by_ids',
          params: {'profile_ids': ids},
        );
        if (rows is List) {
          final profiles = rows
              .whereType<Map<String, dynamic>>()
              .map(UserProfileSummary.fromSupabaseJson)
              .where((profile) => profile.userId.isNotEmpty)
              .toList();
          final visibleProfiles = await _filterBlockedProfiles(profiles);
          if (visibleProfiles.length == ids.length) return visibleProfiles;
          return _mergeProfileFallbacks(ids, visibleProfiles);
        }
      } catch (_) {
        // Fall through to local cache and id-derived labels.
      }
    }

    return _mergeProfileFallbacks(
      ids,
      await _filterBlockedProfiles(await _localUserProfiles()),
    );
  }

  Future<void> followUser(
    String userId, {
    String requesterDisplayName = '',
    String recipientDisplayName = '',
  }) async {
    if (userId == _userId) return;
    if (await isUserBlocked(userId)) return;
    if (_hasAuthenticatedSupabaseUser) {
      final request = FollowRequest.create(
        requesterId: _userId,
        recipientId: userId,
        requesterDisplayName: requesterDisplayName,
        recipientDisplayName: recipientDisplayName,
      );
      await _client!
          .from(_followRequestsTable)
          .upsert(
            request.toSupabaseInsertJson(),
            onConflict: 'requester_id,recipient_id',
          );
      return;
    }

    await cacheUserProfile(
      UserProfileSummary(
        userId: _userId,
        displayName: requesterDisplayName.isEmpty
            ? _displayName(_userId)
            : requesterDisplayName,
      ),
    );
    await cacheUserProfile(
      UserProfileSummary(
        userId: userId,
        displayName: recipientDisplayName.isEmpty
            ? _displayName(userId)
            : recipientDisplayName,
      ),
    );

    final requests = await _localFollowRequests();
    final request = FollowRequest.create(
      requesterId: _userId,
      recipientId: userId,
      requesterDisplayName: requesterDisplayName,
      recipientDisplayName: recipientDisplayName,
    );
    final existingIndex = requests.indexWhere(
      (candidate) =>
          candidate.requesterId == _userId && candidate.recipientId == userId,
    );
    if (existingIndex == -1) {
      await _saveLocalFollowRequests([request, ...requests]);
      return;
    }
    final existing = requests[existingIndex];
    if (existing.status == FollowRequestStatus.accepted ||
        existing.status == FollowRequestStatus.pending) {
      return;
    }
    final next = [...requests];
    next[existingIndex] = request;
    await _saveLocalFollowRequests(next);
  }

  Future<void> unfollowUser(String userId) async {
    if (_hasAuthenticatedSupabaseUser) {
      final client = _client!;
      await client
          .from(_followsTable)
          .delete()
          .eq('follower_id', _userId)
          .eq('following_id', userId);
      await client
          .from(_followRequestsTable)
          .delete()
          .eq('requester_id', _userId)
          .eq('recipient_id', userId);
      return;
    }

    final follows = await _localFollows();
    await _saveLocalFollows(
      follows
          .where(
            (follow) =>
                follow.followerId != _userId || follow.followingId != userId,
          )
          .toList(),
    );
    final requests = await _localFollowRequests();
    await _saveLocalFollowRequests(
      requests
          .where(
            (request) =>
                request.requesterId != _userId || request.recipientId != userId,
          )
          .toList(),
    );
  }

  Future<bool> isFollowing(String userId) async {
    if (await isUserBlocked(userId)) return false;
    if (_hasAuthenticatedSupabaseUser) {
      final row = await _client!
          .from(_followsTable)
          .select('following_id')
          .eq('follower_id', _userId)
          .eq('following_id', userId)
          .maybeSingle();
      return row != null;
    }

    final follows = await _localFollows();
    return follows.any(
      (follow) => follow.followerId == _userId && follow.followingId == userId,
    );
  }

  Future<List<String>> following(String userId) async {
    final blockedIds = (await blockedUserIds()).toSet();
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_followsTable)
          .select('following_id')
          .eq('follower_id', userId);
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => row['following_id'] as String?)
          .whereType<String>()
          .where((id) => !blockedIds.contains(id))
          .toList();
    }

    final follows = await _localFollows();
    return follows
        .where((follow) => follow.followerId == userId)
        .map((follow) => follow.followingId)
        .where((id) => !blockedIds.contains(id))
        .toList();
  }

  Future<List<String>> followers(String userId) async {
    final blockedIds = (await blockedUserIds()).toSet();
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_followsTable)
          .select('follower_id')
          .eq('following_id', userId);
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => row['follower_id'] as String?)
          .whereType<String>()
          .where((id) => !blockedIds.contains(id))
          .toList();
    }

    final follows = await _localFollows();
    return follows
        .where((follow) => follow.followingId == userId)
        .map((follow) => follow.followerId)
        .where((id) => !blockedIds.contains(id))
        .toList();
  }

  Future<FollowRequestStatus?> followRequestStatus(String userId) async {
    if (await isUserBlocked(userId)) return null;
    if (_hasAuthenticatedSupabaseUser) {
      final row = await _client!
          .from(_followRequestsTable)
          .select()
          .eq('requester_id', _userId)
          .eq('recipient_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return FollowRequestStatus.fromJson(row['status']);
    }

    final requests = await _localFollowRequests();
    for (final request in requests) {
      if (request.requesterId == _userId && request.recipientId == userId) {
        return request.status;
      }
    }
    return null;
  }

  Future<List<FollowRequest>> followRequestsForAlerts() async {
    final blockedIds = (await blockedUserIds()).toSet();
    if (_hasAuthenticatedSupabaseUser) {
      final client = _client!;
      final incoming = await client
          .from(_followRequestsTable)
          .select()
          .eq('recipient_id', _userId)
          .eq('status', FollowRequestStatus.pending.name)
          .order('created_at', ascending: false);
      final accepted = await client
          .from(_followRequestsTable)
          .select()
          .eq('requester_id', _userId)
          .eq('status', FollowRequestStatus.accepted.name)
          .order('responded_at', ascending: false);
      return _sortFollowRequests([
        ...incoming.whereType<Map<String, dynamic>>().map(
          FollowRequest.fromSupabaseJson,
        ),
        ...accepted.whereType<Map<String, dynamic>>().map(
          FollowRequest.fromSupabaseJson,
        ),
      ]).where((request) {
        final otherUserId = request.requesterId == _userId
            ? request.recipientId
            : request.requesterId;
        return !blockedIds.contains(otherUserId);
      }).toList();
    }

    final requests = await _localFollowRequests();
    return _sortFollowRequests(
      requests
          .where(
            (request) =>
                (request.recipientId == _userId &&
                    request.status == FollowRequestStatus.pending) ||
                (request.requesterId == _userId &&
                    request.status == FollowRequestStatus.accepted),
          )
          .where(
            (request) => !blockedIds.contains(
              request.requesterId == _userId
                  ? request.recipientId
                  : request.requesterId,
            ),
          )
          .toList(),
    );
  }

  Future<void> acceptFollowRequest(String requestId) async {
    if (_hasAuthenticatedSupabaseUser) {
      await _client!.rpc(
        'accept_follow_request',
        params: {'request_id': requestId},
      );
      return;
    }

    final requests = await _localFollowRequests();
    final index = requests.indexWhere(
      (request) => request.id == requestId && request.recipientId == _userId,
    );
    if (index == -1) return;
    final request = requests[index];
    final now = DateTime.now();
    final nextRequests = [...requests];
    nextRequests[index] = request.copyWith(
      status: FollowRequestStatus.accepted,
      respondedAt: now,
    );
    await _saveLocalFollowRequests(nextRequests);

    final follows = await _localFollows();
    final exists = follows.any(
      (follow) =>
          follow.followerId == request.requesterId &&
          follow.followingId == request.recipientId,
    );
    if (!exists) {
      await _saveLocalFollows([
        _UserFollow(
          followerId: request.requesterId,
          followingId: request.recipientId,
        ),
        ...follows,
      ]);
    }
  }

  Future<void> declineFollowRequest(String requestId) async {
    if (_hasAuthenticatedSupabaseUser) {
      await _client!
          .from(_followRequestsTable)
          .update({
            'status': FollowRequestStatus.declined.name,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('recipient_id', _userId);
      return;
    }

    final requests = await _localFollowRequests();
    final index = requests.indexWhere(
      (request) => request.id == requestId && request.recipientId == _userId,
    );
    if (index == -1) return;
    final next = [...requests];
    next[index] = next[index].copyWith(
      status: FollowRequestStatus.declined,
      respondedAt: DateTime.now(),
    );
    await _saveLocalFollowRequests(next);
  }

  Future<void> suggestMovie(
    ContentItem item, {
    required List<String> recipientIds,
    required String senderDisplayName,
  }) async {
    final blockedIds = (await blockedUserIds()).toSet();
    final uniqueRecipients = recipientIds
        .where(
          (id) =>
              id.trim().isNotEmpty && id != _userId && !blockedIds.contains(id),
        )
        .toSet()
        .toList();
    if (uniqueRecipients.isEmpty) return;

    final followerIds = (await followers(_userId)).toSet();
    final suggestions = [
      for (final recipientId in uniqueRecipients)
        if (followerIds.contains(recipientId))
          MovieSuggestion.create(
            senderId: _userId,
            recipientId: recipientId,
            senderDisplayName: senderDisplayName,
            content: item,
          ),
    ];
    if (suggestions.isEmpty) return;

    if (_hasAuthenticatedSupabaseUser) {
      await _client!
          .from(_suggestionsTable)
          .insert(
            suggestions
                .map((suggestion) => suggestion.toSupabaseInsertJson())
                .toList(),
          );
      return;
    }

    final existing = await _localMovieSuggestions();
    await _saveLocalMovieSuggestions([...suggestions, ...existing]);
  }

  Future<List<MovieSuggestion>> movieSuggestions() async {
    final blockedIds = (await blockedUserIds()).toSet();
    if (_hasAuthenticatedSupabaseUser) {
      final rows = await _client!
          .from(_suggestionsTable)
          .select()
          .eq('recipient_id', _userId)
          .order('created_at', ascending: false);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(MovieSuggestion.fromSupabaseJson)
          .where((suggestion) => !blockedIds.contains(suggestion.senderId))
          .toList();
    }

    final suggestions = await _localMovieSuggestions();
    return suggestions
        .where(
          (suggestion) =>
              suggestion.recipientId == _userId &&
              !blockedIds.contains(suggestion.senderId),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markMovieSuggestionRead(String suggestionId) async {
    final now = DateTime.now();
    if (_hasAuthenticatedSupabaseUser) {
      await _client!
          .from(_suggestionsTable)
          .update({'read_at': now.toIso8601String()})
          .eq('id', suggestionId)
          .eq('recipient_id', _userId);
      return;
    }

    final suggestions = await _localMovieSuggestions();
    await _saveLocalMovieSuggestions([
      for (final suggestion in suggestions)
        suggestion.id == suggestionId && suggestion.recipientId == _userId
            ? suggestion.copyWith(readAt: now)
            : suggestion,
    ]);
  }

  Future<void> _saveCommunityReport(_CommunityReport report) async {
    final existing = await _localCommunityReports();
    await _saveLocalCommunityReports([report, ...existing]);

    if (_hasAuthenticatedSupabaseUser) {
      await _client!.from(_reportsTable).insert(report.toSupabaseInsertJson());
    }
  }

  Future<void> _removeLocalConnections(String userId) async {
    final follows = await _localFollows();
    await _saveLocalFollows(
      follows
          .where(
            (follow) =>
                (follow.followerId != _userId ||
                    follow.followingId != userId) &&
                (follow.followerId != userId || follow.followingId != _userId),
          )
          .toList(),
    );

    final requests = await _localFollowRequests();
    await _saveLocalFollowRequests(
      requests
          .where(
            (request) =>
                (request.requesterId != _userId ||
                    request.recipientId != userId) &&
                (request.requesterId != userId ||
                    request.recipientId != _userId),
          )
          .toList(),
    );
  }

  Future<List<SocialEntry>> _filterBlockedEntries(
    FutureOr<List<SocialEntry>> entriesFuture,
  ) async {
    final entries = await entriesFuture;
    if (entries.isEmpty) return entries;
    final blockedIds = (await blockedUserIds()).toSet();
    if (blockedIds.isEmpty) return entries;
    return entries
        .where((entry) => !blockedIds.contains(entry.userId))
        .toList();
  }

  Future<List<ReviewComment>> _filterBlockedComments(
    FutureOr<List<ReviewComment>> commentsFuture,
  ) async {
    final comments = await commentsFuture;
    if (comments.isEmpty) return comments;
    final blockedIds = (await blockedUserIds()).toSet();
    if (blockedIds.isEmpty) return comments;
    return comments
        .where((comment) => !blockedIds.contains(comment.userId))
        .toList();
  }

  Future<List<UserProfileSummary>> _filterBlockedProfiles(
    List<UserProfileSummary> profiles,
  ) async {
    if (profiles.isEmpty) return profiles;
    final blockedIds = (await blockedUserIds()).toSet();
    if (blockedIds.isEmpty) return profiles;
    return profiles
        .where((profile) => !blockedIds.contains(profile.userId))
        .toList();
  }

  Future<SocialEntry> _upsertFromItem(
    ContentItem item, {
    required SocialEntry Function(SocialEntry? existing, SocialEntry fresh)
    transform,
  }) async {
    final all = await entries();
    final fresh = SocialEntry.fromContentItem(item, userId: _userId);
    final existingIndex = _findImportMatch(all, fresh);
    final existing = existingIndex == -1 ? null : all[existingIndex];
    final next = transform(existing, fresh);

    if (_hasAuthenticatedSupabaseUser) {
      await _client!.from(_table).upsert(next.toSupabaseJson(userId: _userId));
    } else {
      final updated = [
        next,
        for (var index = 0; index < all.length; index++)
          if (index != existingIndex && all[index].id != next.id) all[index],
      ];
      await _saveLocalEntries(updated);
    }
    return next;
  }

  int _findImportMatch(List<SocialEntry> entries, SocialEntry imported) {
    final idIndex = entries.indexWhere((entry) => entry.id == imported.id);
    if (idIndex != -1) return idIndex;

    if (imported.tmdbId != null) {
      final tmdbIndex = entries.indexWhere(
        (entry) =>
            entry.mediaType == imported.mediaType &&
            entry.tmdbId == imported.tmdbId,
      );
      if (tmdbIndex != -1) return tmdbIndex;
    }

    if (imported.imdbId != null && imported.imdbId!.isNotEmpty) {
      final imdbIndex = entries.indexWhere(
        (entry) =>
            entry.mediaType == imported.mediaType &&
            entry.imdbId == imported.imdbId,
      );
      if (imdbIndex != -1) return imdbIndex;
    }

    final importedTitle = _normalizeImportTitle(imported.title);
    return entries.indexWhere(
      (entry) =>
          entry.mediaType == imported.mediaType &&
          entry.year == imported.year &&
          _normalizeImportTitle(entry.title) == importedTitle,
    );
  }

  SocialEntry _mergeImportedEntry(SocialEntry? existing, SocialEntry imported) {
    final now = DateTime.now();
    final base = existing ?? imported;
    final isWatchlistOnly =
        imported.inWatchlist &&
        imported.watchedOn == null &&
        imported.rating == 0 &&
        imported.review.trim().isEmpty;

    if (isWatchlistOnly) {
      return base.copyWith(
        id: base.id,
        userId: _userId,
        tmdbId: base.tmdbId ?? imported.tmdbId,
        imdbId: base.imdbId ?? imported.imdbId,
        mediaType: imported.mediaType,
        title: _preferImportedText(base.title, imported.title),
        year: base.year == 0 ? imported.year : base.year,
        type: _preferImportedText(base.type, imported.type),
        rating: 0,
        review: '',
        tags: imported.tags.isEmpty ? base.tags : imported.tags,
        watchedOn: null,
        inWatchlist: true,
        createdAt: existing?.createdAt ?? imported.createdAt,
        updatedAt: now,
      );
    }

    final nextRating = imported.rating > 0
        ? _clampRating(imported.rating)
        : base.rating;
    final nextReview = imported.review.trim().isNotEmpty
        ? imported.review.trim()
        : base.review;
    final nextTags = imported.tags.isEmpty
        ? base.tags
        : _mergeReviewTags(base.tags, imported.tags);
    final nextWatchedOn =
        imported.watchedOn ??
        base.watchedOn ??
        (nextRating > 0 || nextReview.trim().isNotEmpty ? now : null);

    return base.copyWith(
      id: base.id,
      userId: _userId,
      tmdbId: base.tmdbId ?? imported.tmdbId,
      imdbId: base.imdbId ?? imported.imdbId,
      mediaType: imported.mediaType,
      title: _preferImportedText(base.title, imported.title),
      subtitle: base.subtitle.isEmpty ? imported.subtitle : base.subtitle,
      year: base.year == 0 ? imported.year : base.year,
      genre: base.genre.isEmpty ? imported.genre : base.genre,
      type: _preferImportedText(base.type, imported.type),
      tmdbRating: base.tmdbRating == 0 ? imported.tmdbRating : base.tmdbRating,
      posterUrl: base.posterUrl ?? imported.posterUrl,
      backdropUrl: base.backdropUrl ?? imported.backdropUrl,
      description: base.description.isEmpty
          ? imported.description
          : base.description,
      rating: nextRating,
      review: nextReview,
      tags: nextTags,
      watchedOn: nextWatchedOn,
      inWatchlist: false,
      createdAt: existing?.createdAt ?? imported.createdAt,
      updatedAt: now,
    );
  }

  Future<List<SocialEntry>> _localEntries() async {
    final raw = LocalStorage.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SocialEntry.fromJson)
        .toList();
  }

  Future<void> _saveLocalEntries(List<SocialEntry> entries) async {
    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await LocalStorage.setString(_storageKey, encoded);
  }

  Future<SocialEntry> _localReviewInteractionBase(SocialEntry review) async {
    final all = await _localEntries();
    return all
            .where(
              (entry) => entry.id == review.id && entry.userId == review.userId,
            )
            .firstOrNull ??
        review;
  }

  Future<void> _saveLocalInteraction(SocialEntry next) async {
    final all = await _localEntries();
    final index = all.indexWhere(
      (entry) => entry.id == next.id && entry.userId == next.userId,
    );
    if (index == -1) return;
    final updated = [...all];
    updated[index] = next;
    await _saveLocalEntries(updated);
  }

  Future<List<ReviewComment>> _localReviewComments() async {
    final raw = LocalStorage.getString(_reviewCommentStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ReviewComment.fromJson)
        .where((comment) => comment.id.isNotEmpty)
        .toList();
  }

  Future<void> _saveLocalReviewComments(List<ReviewComment> comments) async {
    final encoded = jsonEncode(
      comments.map((comment) => comment.toJson()).toList(),
    );
    await LocalStorage.setString(_reviewCommentStorageKey, encoded);
  }

  Future<List<_UserFollow>> _localFollows() async {
    final raw = LocalStorage.getString(_followStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_UserFollow.fromJson)
        .toList();
  }

  Future<void> _saveLocalFollows(List<_UserFollow> follows) async {
    final encoded = jsonEncode(
      follows.map((follow) => follow.toJson()).toList(),
    );
    await LocalStorage.setString(_followStorageKey, encoded);
  }

  Future<List<FollowRequest>> _localFollowRequests() async {
    final raw = LocalStorage.getString(_followRequestStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(FollowRequest.fromJson)
        .toList();
  }

  Future<void> _saveLocalFollowRequests(List<FollowRequest> requests) async {
    final encoded = jsonEncode(
      requests.map((request) => request.toJson()).toList(),
    );
    await LocalStorage.setString(_followRequestStorageKey, encoded);
  }

  Future<List<MovieSuggestion>> _localMovieSuggestions() async {
    final raw = LocalStorage.getString(_suggestionStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MovieSuggestion.fromJson)
        .toList();
  }

  Future<void> _saveLocalMovieSuggestions(
    List<MovieSuggestion> suggestions,
  ) async {
    final encoded = jsonEncode(
      suggestions.map((suggestion) => suggestion.toJson()).toList(),
    );
    await LocalStorage.setString(_suggestionStorageKey, encoded);
  }

  Future<List<UserProfileSummary>> _localUserProfiles() async {
    final raw = LocalStorage.getString(_profileStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(UserProfileSummary.fromJson)
        .toList();
  }

  Future<void> _saveLocalUserProfiles(List<UserProfileSummary> profiles) async {
    final encoded = jsonEncode(
      profiles.map((profile) => profile.toJson()).toList(),
    );
    await LocalStorage.setString(_profileStorageKey, encoded);
  }

  Future<List<_UserBlock>> _localUserBlocks() async {
    final raw = LocalStorage.getString(_blockedUserStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_UserBlock.fromJson)
        .toList();
  }

  Future<void> _saveLocalUserBlocks(List<_UserBlock> blocks) async {
    final encoded = jsonEncode(blocks.map((block) => block.toJson()).toList());
    await LocalStorage.setString(_blockedUserStorageKey, encoded);
  }

  Future<List<_CommunityReport>> _localCommunityReports() async {
    final raw = LocalStorage.getString(_communityReportStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_CommunityReport.fromJson)
        .toList();
  }

  Future<void> _saveLocalCommunityReports(
    List<_CommunityReport> reports,
  ) async {
    final encoded = jsonEncode(
      reports.map((report) => report.toJson()).toList(),
    );
    await LocalStorage.setString(_communityReportStorageKey, encoded);
  }
}

class SocialImportResult {
  const SocialImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
    required this.entries,
    this.tmdbLinked = 0,
    this.tmdbUnresolved = 0,
  });

  final int added;
  final int updated;
  final int skipped;
  final List<SocialEntry> entries;
  final int tmdbLinked;
  final int tmdbUnresolved;

  int get applied => added + updated;
}

double _normalizeOptionalRating(double rating) {
  return normalizeVeilRating(rating, allowUnrated: true);
}

double _clampRating(double rating) {
  return normalizeVeilRating(rating);
}

const _watchKindTags = {'first-time', 'rewatch'};

List<String> _mergeReviewTags(List<String> existing, List<String> next) {
  final merged = <String>[];
  final nextWatchKind = _firstWatchKind(next) ?? _firstWatchKind(existing);
  if (nextWatchKind != null) merged.add(nextWatchKind);

  final nextCustom = next
      .where((tag) => !_watchKindTags.contains(tag))
      .where((tag) => tag.trim().isNotEmpty)
      .toList();
  final customTags = nextCustom.isEmpty
      ? existing.where((tag) => !_watchKindTags.contains(tag))
      : nextCustom;

  for (final tag in customTags) {
    if (!merged.contains(tag)) merged.add(tag);
  }
  return merged;
}

String? _firstWatchKind(List<String> tags) {
  for (final tag in tags) {
    if (_watchKindTags.contains(tag)) return tag;
  }
  return null;
}

String _normalizeImportTitle(String title) {
  return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _preferImportedText(String existing, String imported) {
  return existing.trim().isEmpty ? imported.trim() : existing;
}

List<UserProfileSummary> _mergeProfileFallbacks(
  List<String> userIds,
  List<UserProfileSummary> profiles,
) {
  final byId = {
    for (final profile in profiles)
      if (profile.userId.isNotEmpty) profile.userId: profile,
  };
  return [
    for (final userId in userIds)
      byId[userId] ??
          UserProfileSummary(userId: userId, displayName: _displayName(userId)),
  ];
}

List<FollowRequest> _sortFollowRequests(List<FollowRequest> requests) {
  return [...requests]..sort((a, b) {
    final aDate = a.respondedAt ?? a.createdAt;
    final bDate = b.respondedAt ?? b.createdAt;
    return bDate.compareTo(aDate);
  });
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}

class _UserFollow {
  const _UserFollow({required this.followerId, required this.followingId});

  factory _UserFollow.fromJson(Map<String, dynamic> json) {
    return _UserFollow(
      followerId: json['follower_id'] as String? ?? '',
      followingId: json['following_id'] as String? ?? '',
    );
  }

  final String followerId;
  final String followingId;

  Map<String, dynamic> toJson() {
    return {'follower_id': followerId, 'following_id': followingId};
  }
}

class _UserBlock {
  const _UserBlock({
    required this.blockerId,
    required this.blockedUserId,
    required this.blockedDisplayName,
    required this.createdAt,
  });

  factory _UserBlock.fromJson(Map<String, dynamic> json) {
    return _UserBlock(
      blockerId: json['blocker_id'] as String? ?? '',
      blockedUserId: json['blocked_user_id'] as String? ?? '',
      blockedDisplayName: json['blocked_display_name'] as String? ?? '',
      createdAt: _repositoryParseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  final String blockerId;
  final String blockedUserId;
  final String blockedDisplayName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'blocker_id': blockerId,
      'blocked_user_id': blockedUserId,
      'blocked_display_name': blockedDisplayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsertJson() {
    return {
      'blocker_id': blockerId,
      'blocked_user_id': blockedUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class _CommunityReport {
  const _CommunityReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetUserId,
    required this.contentId,
    this.parentContentId,
    required this.reason,
    required this.details,
    required this.createdAt,
  });

  factory _CommunityReport.create({
    required String reporterId,
    required String targetType,
    required String targetUserId,
    required String contentId,
    String? parentContentId,
    required String reason,
    String details = '',
  }) {
    return _CommunityReport(
      id: 'report_${DateTime.now().microsecondsSinceEpoch}',
      reporterId: reporterId,
      targetType: targetType,
      targetUserId: targetUserId,
      contentId: contentId,
      parentContentId: parentContentId,
      reason: reason.trim().isEmpty ? 'other' : reason.trim(),
      details: details.trim(),
      createdAt: DateTime.now(),
    );
  }

  factory _CommunityReport.fromJson(Map<String, dynamic> json) {
    return _CommunityReport(
      id: json['id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? 'review',
      targetUserId: json['target_user_id'] as String? ?? '',
      contentId: json['content_id'] as String? ?? '',
      parentContentId: json['parent_content_id'] as String?,
      reason: json['reason'] as String? ?? 'other',
      details: json['details'] as String? ?? '',
      createdAt: _repositoryParseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  final String id;
  final String reporterId;
  final String targetType;
  final String targetUserId;
  final String contentId;
  final String? parentContentId;
  final String reason;
  final String details;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_user_id': targetUserId,
      'content_id': contentId,
      'parent_content_id': parentContentId,
      'reason': reason,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsertJson() {
    return {
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_user_id': targetUserId,
      'content_id': contentId,
      'parent_content_id': parentContentId,
      'reason': reason,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

DateTime? _repositoryParseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
