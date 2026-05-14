import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'home_view_model.freezed.dart';
part 'home_view_model.g.dart';

@freezed
abstract class HomeViewState with _$HomeViewState {
  const HomeViewState._();

  const factory HomeViewState({
    ContentItem? featured,
    @Default([]) List<ContentItem> globalTrending,
    @Default([]) List<ContentItem> newThisWeek,
    @Default([]) List<ContentItem> popularMovies,
    @Default([]) List<ContentItem> topRatedMovies,
    @Default([]) List<ContentItem> topRatedTv,
    @Default([]) List<ContentItem> airingToday,
    @Default([]) List<TmdbGenre> genres,
    TmdbGenre? selectedGenre,
    @Default([]) List<ContentItem> genreResults,
    @Default(1) int genrePage,
    @Default(true) bool genreCanLoadMore,
    @Default(false) bool genreLoadingMore,
    @Default(Status.initial()) Status loadStatus,
    @Default(Status.initial()) Status genreStatus,
  }) = _HomeViewState;

  factory HomeViewState.initial() => const HomeViewState();
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeViewState build() {
    Future.microtask(load);
    return HomeViewState.initial();
  }

  Future<void> load() async {
    if (state.loadStatus is StatusLoading) return;

    try {
      state = state.copyWith(loadStatus: const Status.loading());
      final repository = ref.read(tmdbRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.trending(),
        repository.upcomingMovies(),
        repository.popularMovies(),
        repository.topRatedMovies(),
        repository.topRatedTv(),
        repository.airingTodayTv(),
        repository.genresDetailed(),
      ]);
      final trending = results[0] as List<ContentItem>;
      final upcoming = results[1] as List<ContentItem>;
      final popularMovies = results[2] as List<ContentItem>;
      final topRatedMovies = results[3] as List<ContentItem>;
      final topRatedTv = results[4] as List<ContentItem>;
      final airingToday = results[5] as List<ContentItem>;
      final genres = results[6] as List<TmdbGenre>;

      state = state.copyWith(
        featured: trending.firstOrNull,
        globalTrending: trending,
        newThisWeek: upcoming,
        popularMovies: popularMovies,
        topRatedMovies: topRatedMovies,
        topRatedTv: topRatedTv,
        airingToday: airingToday,
        genres: genres,
        loadStatus: const Status.success(),
      );
    } catch (error) {
      state = state.copyWith(loadStatus: Status.failure(error.toString()));
    }
  }

  Future<void> selectGenre(TmdbGenre? genre) async {
    if (genre == null) {
      state = state.copyWith(
        selectedGenre: null,
        genreResults: const [],
        genrePage: 1,
        genreCanLoadMore: true,
        genreLoadingMore: false,
        genreStatus: const Status.initial(),
      );
      return;
    }

    state = state.copyWith(
      selectedGenre: genre,
      genreResults: const [],
      genrePage: 1,
      genreCanLoadMore: true,
      genreLoadingMore: false,
      genreStatus: const Status.loading(),
    );
    try {
      final items = await ref
          .read(tmdbRepositoryProvider)
          .sectionPage('popular_movies', genreId: genre.id, page: 1);
      if (state.selectedGenre?.id != genre.id) return;
      state = state.copyWith(
        genreResults: items,
        genreCanLoadMore: items.isNotEmpty,
        genreStatus: const Status.success(),
      );
    } catch (error) {
      if (state.selectedGenre?.id != genre.id) return;
      state = state.copyWith(
        genreCanLoadMore: false,
        genreStatus: Status.failure(error.toString()),
      );
    }
  }

  Future<void> loadMoreSelectedGenre() async {
    final genre = state.selectedGenre;
    if (genre == null ||
        state.genreStatus is StatusLoading ||
        state.genreLoadingMore ||
        !state.genreCanLoadMore) {
      return;
    }

    final nextPage = state.genrePage + 1;
    state = state.copyWith(genreLoadingMore: true);

    try {
      final items = await ref
          .read(tmdbRepositoryProvider)
          .sectionPage('popular_movies', genreId: genre.id, page: nextPage);
      if (state.selectedGenre?.id != genre.id) return;

      state = state.copyWith(
        genreResults: [...state.genreResults, ...items],
        genrePage: items.isEmpty ? state.genrePage : nextPage,
        genreCanLoadMore: items.isNotEmpty,
        genreLoadingMore: false,
        genreStatus: const Status.success(),
      );
    } catch (error) {
      if (state.selectedGenre?.id != genre.id) return;
      state = state.copyWith(
        genreLoadingMore: false,
        genreStatus: Status.failure(error.toString()),
      );
    }
  }
}
