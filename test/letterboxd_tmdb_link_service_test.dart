import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_tmdb_link_service.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  test('links imported Letterboxd rows to TMDB movie data', () async {
    final service = LetterboxdTmdbLinkService(
      resolveMovie: ({imdbId, title = '', tmdbId, year = 0}) async {
        expect(title, 'Heat');
        expect(year, 1995);
        return const ContentItem(
          id: 'movie-949',
          remoteId: 949,
          mediaType: 'movie',
          imdbId: 'tt0113277',
          title: 'Heat',
          subtitle: 'Movie',
          year: 1995,
          genre: 'Crime / Drama',
          type: 'Movie',
          rating: 7.9,
          palette: [Colors.black, Colors.red],
          glyph: Icons.movie_rounded,
          description: 'A master thief squares off with a detective.',
          posterUrl: 'https://image.tmdb.org/t/p/w500/heat-poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w780/heat-backdrop.jpg',
        );
      },
    );

    final result = await service.link([
      SocialEntry(
        id: 'movie_heat_1995',
        userId: 'letterboxd-import',
        imdbId: 'tt0113277',
        mediaType: 'movie',
        title: 'Heat',
        year: 1995,
        type: 'Movie',
        rating: 4.5,
        review: 'Perfect pressure.',
        tags: const ['rewatch', 'crime'],
        watchedOn: DateTime(2024, 2, 1),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ]);

    expect(result.linkedCount, 1);
    expect(result.unresolvedCount, 0);
    final entry = result.entries.single;
    expect(entry.id, 'movie_949');
    expect(entry.tmdbId, 949);
    expect(entry.imdbId, 'tt0113277');
    expect(entry.posterUrl, contains('/w500/heat-poster.jpg'));
    expect(entry.backdropUrl, contains('/w780/heat-backdrop.jpg'));
    expect(entry.rating, 4.5);
    expect(entry.tmdbRating, 7.9);
    expect(entry.review, 'Perfect pressure.');
    expect(entry.tags, ['rewatch', 'crime']);
    expect(entry.watchedOn, DateTime(2024, 2, 1));
  });

  test('skips original row when TMDB cannot resolve a movie', () async {
    final original = SocialEntry(
      id: 'movie_unknown_2024',
      userId: 'letterboxd-import',
      mediaType: 'movie',
      title: 'Unknown Festival Cut',
      year: 2024,
      type: 'Movie',
      inWatchlist: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final service = LetterboxdTmdbLinkService(
      resolveMovie: ({imdbId, title = '', tmdbId, year = 0}) async => null,
    );

    final result = await service.link([original]);

    expect(result.linkedCount, 0);
    expect(result.unresolvedCount, 1);
    expect(result.entries, isEmpty);
  });
}
