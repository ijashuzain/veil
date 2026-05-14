import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/shared/data/mock_catalog.dart';

void main() {
  test('fallback catalog contains the design sections', () {
    expect(VeilCatalog.featured.title, 'Dune: Part Two');
    expect(VeilCatalog.continueWatching, isNotEmpty);
    expect(VeilCatalog.globalTrending.length, greaterThanOrEqualTo(5));
    expect(VeilCatalog.newThisWeek, isNotEmpty);
  });

  test('search matches title, subtitle, genre, and type', () {
    final wakanda = VeilCatalog.search('wakanda');
    expect(wakanda.single.title, 'Wakanda Forever');

    final animation = VeilCatalog.search('animation');
    expect(animation.map((item) => item.title), contains('Arcane'));

    final movie = VeilCatalog.search('movie');
    expect(movie.length, greaterThan(3));
  });
}
