import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_tmdb_link_service.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'social_library_view_model.freezed.dart';
part 'social_library_view_model.g.dart';

@freezed
abstract class SocialLibraryViewState with _$SocialLibraryViewState {
  const SocialLibraryViewState._();

  const factory SocialLibraryViewState({
    @Default([]) List<SocialEntry> entries,
    @Default([]) List<SocialEntry> globalReviews,
    @Default(Status.initial()) Status loadStatus,
    @Default(Status.initial()) Status saveStatus,
  }) = _SocialLibraryViewState;

  List<SocialEntry> get diary =>
      entries.where((entry) => entry.watchedOn != null).toList();

  List<SocialEntry> get reviews =>
      entries.where((entry) => entry.review.trim().isNotEmpty).toList();

  List<SocialEntry> get watchlist =>
      entries.where((entry) => entry.inWatchlist).toList();

  List<SocialEntry> get favorites =>
      entries.where((entry) => entry.isFavorite).toList();
}

@riverpod
class SocialLibraryViewModel extends _$SocialLibraryViewModel {
  @override
  SocialLibraryViewState build() {
    Future.microtask(load);
    return const SocialLibraryViewState();
  }

  Future<void> load() async {
    try {
      state = state.copyWith(loadStatus: const Status.loading());
      final repository = ref.read(socialRepositoryProvider);
      final entries = await repository.entries();
      final globalReviews = await repository.globalReviews();
      state = state.copyWith(
        entries: entries,
        globalReviews: globalReviews,
        loadStatus: const Status.success(),
      );
    } catch (error) {
      state = state.copyWith(loadStatus: Status.failure(error.toString()));
    }
  }

  Future<void> logWatched(ContentItem item) {
    return _save(
      () => ref.read(socialRepositoryProvider).setWatched(item, watched: true),
    );
  }

  Future<void> setWatched(
    ContentItem item, {
    required bool watched,
    double rating = 0,
    List<String> tags = const [],
  }) {
    return _save(
      () => ref
          .read(socialRepositoryProvider)
          .setWatched(item, watched: watched, rating: rating, tags: tags),
    );
  }

  Future<void> rate(
    ContentItem item, {
    required double rating,
    List<String> tags = const [],
  }) {
    return _save(
      () => ref
          .read(socialRepositoryProvider)
          .rate(item, rating: rating, tags: tags),
    );
  }

  Future<void> rateReview(
    ContentItem item, {
    required double rating,
    required String review,
    List<String> tags = const [],
  }) {
    return _save(
      () => ref
          .read(socialRepositoryProvider)
          .rateReview(item, rating: rating, review: review, tags: tags),
    );
  }

  Future<void> toggleWatchlist(ContentItem item) {
    return _save(
      () => ref.read(socialRepositoryProvider).toggleWatchlist(item),
    );
  }

  Future<void> setWatchlist(
    ContentItem item, {
    required bool inWatchlist,
    double rating = 0,
  }) {
    return _save(
      () => ref
          .read(socialRepositoryProvider)
          .setWatchlist(item, inWatchlist: inWatchlist, rating: rating),
    );
  }

  Future<void> toggleFavorite(ContentItem item) {
    return _save(() => ref.read(socialRepositoryProvider).toggleFavorite(item));
  }

  Future<SocialImportResult> importEntries(List<SocialEntry> entries) async {
    try {
      state = state.copyWith(saveStatus: const Status.loading());
      final linkResult = await LetterboxdTmdbLinkService.fromRepository(
        ref.read(tmdbRepositoryProvider),
      ).link(entries);
      final result = await ref
          .read(socialRepositoryProvider)
          .importSocialEntries(linkResult.entries);
      await load();
      state = state.copyWith(saveStatus: const Status.success());
      return SocialImportResult(
        added: result.added,
        updated: result.updated,
        skipped: result.skipped,
        entries: result.entries,
        tmdbLinked: linkResult.linkedCount,
        tmdbUnresolved: linkResult.unresolvedCount,
      );
    } catch (error) {
      state = state.copyWith(saveStatus: Status.failure(error.toString()));
      rethrow;
    }
  }

  Future<void> _save(Future<SocialEntry> Function() action) async {
    try {
      state = state.copyWith(saveStatus: const Status.loading());
      final entry = await action();
      final entries = [
        entry,
        ...state.entries.where((candidate) => candidate.id != entry.id),
      ];
      final otherGlobalReviews = state.globalReviews
          .where(
            (candidate) =>
                candidate.id != entry.id || candidate.userId != entry.userId,
          )
          .toList();
      final globalReviews = entry.review.trim().isEmpty
          ? otherGlobalReviews
          : [entry, ...otherGlobalReviews];
      state = state.copyWith(
        entries: entries,
        globalReviews: globalReviews,
        saveStatus: const Status.success(),
      );
    } catch (error) {
      state = state.copyWith(saveStatus: Status.failure(error.toString()));
    }
  }

  Future<void> toggleReviewLike(SocialEntry review) async {
    final updated = await ref
        .read(socialRepositoryProvider)
        .toggleReviewLike(review);
    _replaceReview(updated);
  }

  Future<void> toggleReviewHelpful(SocialEntry review) async {
    final updated = await ref
        .read(socialRepositoryProvider)
        .toggleReviewHelpful(review);
    _replaceReview(updated);
  }

  Future<void> addReviewComment(
    SocialEntry review,
    String body, {
    String? parentCommentId,
    bool isSpoiler = false,
  }) async {
    final updated = await ref
        .read(socialRepositoryProvider)
        .addReviewComment(
          review,
          body,
          parentCommentId: parentCommentId,
          isSpoiler: isSpoiler,
        );
    _replaceReview(updated);
  }

  Future<void> deleteReview(SocialEntry review) {
    return _save(() => ref.read(socialRepositoryProvider).deleteReview(review));
  }

  Future<void> deleteCurrentAccount({required String reason}) async {
    state = state.copyWith(saveStatus: const Status.loading());
    try {
      await ref
          .read(socialRepositoryProvider)
          .deleteCurrentAccount(reason: reason);
      await load();
      state = state.copyWith(saveStatus: const Status.success());
    } catch (error) {
      state = state.copyWith(saveStatus: Status.failure(error.toString()));
      rethrow;
    }
  }

  Future<void> followUser(String userId) async {
    await ref.read(socialRepositoryProvider).followUser(userId);
  }

  Future<void> unfollowUser(String userId) async {
    await ref.read(socialRepositoryProvider).unfollowUser(userId);
  }

  void _replaceReview(SocialEntry updated) {
    List<SocialEntry> replaceIn(
      List<SocialEntry> entries, {
      required bool addIfMissing,
    }) {
      var replaced = false;
      final next = [
        for (final entry in entries)
          if (entry.id == updated.id && entry.userId == updated.userId) ...[
            updated,
          ] else
            entry,
      ];
      replaced = entries.any(
        (entry) => entry.id == updated.id && entry.userId == updated.userId,
      );
      if (addIfMissing && !replaced && updated.review.trim().isNotEmpty) {
        return [updated, ...next];
      }
      return next;
    }

    state = state.copyWith(
      entries: replaceIn(state.entries, addIfMissing: false),
      globalReviews: replaceIn(state.globalReviews, addIfMissing: true),
    );
  }
}
