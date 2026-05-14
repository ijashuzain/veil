import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/features/search/view_model/search_view_model/search_view_model.dart';

void main() {
  test('home state starts empty while TMDB sections load', () {
    final state = HomeViewState.initial();

    expect(state.featured, isNull);
    expect(state.globalTrending, isEmpty);
    expect(state.newThisWeek, isEmpty);
    expect(state.popularMovies, isEmpty);
    expect(state.genres, isEmpty);
  });

  test('search state starts without bundled mock results', () {
    final state = SearchViewState.initial();

    expect(state.query, isEmpty);
    expect(state.results, isEmpty);
    expect(state.genres, isEmpty);
  });
}
