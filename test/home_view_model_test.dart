import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  test('selected genre pagination appends pages until an empty page', () async {
    final repository = _PagedTmdbRepository({
      1: [_item('movie-1', 'First page')],
      2: [_item('movie-2', 'Second page')],
      3: const [],
    });
    final container = ProviderContainer(
      overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(homeViewModelProvider.notifier);
    await notifier.selectGenre(const TmdbGenre(id: 28, name: 'Action'));

    expect(_genreResultIds(container), ['movie-1']);
    expect(container.read(homeViewModelProvider).genrePage, 1);
    expect(container.read(homeViewModelProvider).genreCanLoadMore, isTrue);

    await notifier.loadMoreSelectedGenre();

    expect(_genreResultIds(container), ['movie-1', 'movie-2']);
    expect(container.read(homeViewModelProvider).genrePage, 2);
    expect(container.read(homeViewModelProvider).genreCanLoadMore, isTrue);

    await notifier.loadMoreSelectedGenre();

    expect(_genreResultIds(container), ['movie-1', 'movie-2']);
    expect(container.read(homeViewModelProvider).genrePage, 2);
    expect(container.read(homeViewModelProvider).genreCanLoadMore, isFalse);
    expect(repository.requestedPages, [1, 2, 3]);
  });
}

List<String> _genreResultIds(ProviderContainer container) {
  return container
      .read(homeViewModelProvider)
      .genreResults
      .map((item) => item.id)
      .toList();
}

ContentItem _item(String id, String title) {
  return ContentItem(
    id: id,
    remoteId: int.parse(id.split('-').last),
    mediaType: 'movie',
    title: title,
    subtitle: 'Movie',
    year: 2026,
    genre: 'Action',
    type: 'Movie',
    rating: 7,
    palette: const [Colors.black, Colors.red],
    glyph: Icons.movie_rounded,
    description: '$title description',
  );
}

class _PagedTmdbRepository extends TmdbRepository {
  _PagedTmdbRepository(this.pages) : super(api: Api());

  final Map<int, List<ContentItem>> pages;
  final List<int> requestedPages = [];

  @override
  Future<List<ContentItem>> trending() async => const [];

  @override
  Future<List<ContentItem>> upcomingMovies() async => const [];

  @override
  Future<List<ContentItem>> popularMovies() async => const [];

  @override
  Future<List<ContentItem>> topRatedMovies() async => const [];

  @override
  Future<List<ContentItem>> topRatedTv() async => const [];

  @override
  Future<List<ContentItem>> airingTodayTv() async => const [];

  @override
  Future<List<TmdbGenre>> genresDetailed() async {
    return const [TmdbGenre(id: 28, name: 'Action')];
  }

  @override
  Future<List<ContentItem>> sectionPage(
    String section, {
    int page = 1,
    int? genreId,
    double minRating = 0,
  }) async {
    requestedPages.add(page);
    return pages[page] ?? const [];
  }
}
