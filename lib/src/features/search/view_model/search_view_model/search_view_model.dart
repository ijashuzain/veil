import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'search_view_model.freezed.dart';
part 'search_view_model.g.dart';

@freezed
abstract class SearchViewState with _$SearchViewState {
  const SearchViewState._();

  const factory SearchViewState({
    @Default('') String query,
    @Default([]) List<ContentItem> results,
    @Default([]) List<UserProfileSummary> users,
    @Default([]) List<String> genres,
    @Default(Status.initial()) Status searchStatus,
  }) = _SearchViewState;

  factory SearchViewState.initial() => const SearchViewState();
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  @override
  SearchViewState build() {
    Future.microtask(loadInitial);
    return SearchViewState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(searchStatus: const Status.loading());
    try {
      final repository = ref.read(tmdbRepositoryProvider);
      final results = await Future.wait([
        repository.trending(),
        repository.genres(),
      ]);
      if (state.query.isNotEmpty) return;
      state = state.copyWith(
        results: results[0] as List<ContentItem>,
        users: const [],
        genres: results[1] as List<String>,
        searchStatus: const Status.success(),
      );
    } catch (error) {
      if (state.query.isNotEmpty) return;
      state = state.copyWith(searchStatus: Status.failure(error.toString()));
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    state = state.copyWith(query: query, searchStatus: const Status.loading());
    if (trimmed.isEmpty) {
      await loadInitial();
      return;
    }
    try {
      final remoteResults = await ref
          .read(tmdbRepositoryProvider)
          .search(query);
      var users = const <UserProfileSummary>[];
      try {
        users = await ref
            .read(socialRepositoryProvider)
            .searchUserProfiles(trimmed);
      } catch (_) {
        users = const [];
      }
      if (state.query != query) return;
      state = state.copyWith(
        results: remoteResults,
        users: users,
        searchStatus: const Status.success(),
      );
    } catch (error) {
      if (state.query != query) return;
      state = state.copyWith(searchStatus: Status.failure(error.toString()));
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    unawaited(search(''));
  }
}
