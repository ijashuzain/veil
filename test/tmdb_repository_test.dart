import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/features/catalog/models/tmdb_media/tmdb_media.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

const _tmdbProxyBaseUrl =
    'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb/3';

void main() {
  test('TMDB media maps movie JSON into a Veil content item', () {
    final media = TmdbMedia.fromJson(const {
      'id': 505642,
      'media_type': 'movie',
      'title': 'Black Panther: Wakanda Forever',
      'overview': 'Wakanda fights to protect itself.',
      'poster_path': '/sv1xJUazXeYqALzczSZ3O6nkH75.jpg',
      'backdrop_path': '/xDMIl84Qo5Tsu62c9DGWhmPI67A.jpg',
      'release_date': '2022-11-09',
      'vote_average': 7.1,
      'genre_ids': [28, 12],
    });

    final item = media.toContentItem(
      genreLookup: const {28: 'Action', 12: 'Adventure'},
    );

    expect(media.title, 'Black Panther: Wakanda Forever');
    expect(media.posterUrl, contains('/w500/sv1xJUazXeYqALzczSZ3O6nkH75.jpg'));
    expect(item.id, 'movie-505642');
    expect(item.remoteId, 505642);
    expect(item.mediaType, 'movie');
    expect(item.year, 2022);
    expect(item.genre, 'Action / Adventure');
    expect(item.posterUrl, media.posterUrl);
    expect(item.backdropUrl, media.backdropUrl);
  });

  test('TMDB repository uses proxy without client TMDB auth', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '$_tmdbProxyBaseUrl/trending/all/week');
      expect(options.headers.containsKey('Authorization'), isFalse);
      expect(options.queryParameters.containsKey('api_key'), isFalse);
      return {
        'results': [
          {
            'id': 1,
            'media_type': 'tv',
            'name': 'Arcane',
            'overview': 'Animated drama.',
            'first_air_date': '2024-01-01',
            'vote_average': 9.0,
            'genre_ids': [16, 18],
          },
        ],
      };
    });

    final repository = TmdbRepository(api: api, readAccessToken: 'test-token');
    final results = await repository.trending();

    expect(results.single.title, 'Arcane');
    expect(results.single.id, 'tv-1');
  });

  test(
    'TMDB repository hides Disney and Pixar titles for tester account',
    () async {
      final api = Api();
      api.general.httpClientAdapter = _FakeAdapter((options) {
        switch (options.path) {
          case '$_tmdbProxyBaseUrl/trending/all/week':
            return {
              'results': [
                {
                  'id': 100,
                  'media_type': 'movie',
                  'title': 'Frozen',
                  'overview': 'A snow queen changes a kingdom.',
                  'release_date': '2013-11-27',
                  'vote_average': 7.2,
                  'genre_ids': [16, 12],
                },
                {
                  'id': 94605,
                  'media_type': 'tv',
                  'name': 'Arcane',
                  'overview': 'Animated drama.',
                  'first_air_date': '2024-01-01',
                  'vote_average': 9.0,
                  'genre_ids': [16, 18],
                },
                {
                  'id': 862,
                  'media_type': 'movie',
                  'title': 'Toy Story',
                  'overview': 'Toys come to life when nobody is around.',
                  'release_date': '1995-11-22',
                  'vote_average': 8.3,
                  'genre_ids': [16, 35],
                },
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/100':
            return {
              'production_companies': [
                {'name': 'Walt Disney Animation Studios'},
              ],
            };
          case '$_tmdbProxyBaseUrl/tv/94605':
            return {
              'networks': [
                {'name': 'Netflix'},
              ],
              'production_companies': const [],
            };
          case '$_tmdbProxyBaseUrl/movie/862':
            return {
              'production_companies': [
                {'name': 'Pixar Animation Studios'},
              ],
            };
        }
        fail('Unexpected path: ${options.path}');
      });

      final repository = TmdbRepository(
        api: api,
        apiKey: 'api-key',
        currentUserEmail: 'tester@vexellab.com',
      );
      final results = await repository.trending();

      expect(results.map((item) => item.title), ['Arcane']);
    },
  );

  test('TMDB repository parses appended movie detail data', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '$_tmdbProxyBaseUrl/movie/505642');
      expect(options.queryParameters['append_to_response'], contains('videos'));
      return {
        'id': 505642,
        'title': 'Black Panther: Wakanda Forever',
        'tagline': 'Forever.',
        'overview': 'Wakanda fights to protect itself.',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release_date': '2022-11-09',
        'runtime': 162,
        'status': 'Released',
        'imdb_id': 'tt9114286',
        'vote_average': 7.1,
        'genres': [
          {'id': 28, 'name': 'Action'},
          {'id': 12, 'name': 'Adventure'},
        ],
        'production_companies': [
          {'name': 'Marvel Studios'},
        ],
        'spoken_languages': [
          {'english_name': 'English'},
        ],
        'videos': {
          'results': [
            {
              'key': 'abc123',
              'site': 'YouTube',
              'type': 'Trailer',
              'name': 'Official Trailer',
              'official': true,
            },
          ],
        },
        'credits': {
          'cast': [
            {'name': 'Letitia Wright', 'character': 'Shuri'},
          ],
        },
        'reviews': {
          'results': [
            {
              'author': 'Reviewer',
              'content': 'A rich sequel.',
              'author_details': {'rating': 8.0},
            },
          ],
        },
        'recommendations': {'results': []},
        'similar': {'results': []},
        'watch/providers': {
          'results': {
            'US': {
              'flatrate': [
                {'provider_name': 'Disney Plus'},
              ],
            },
          },
        },
        'images': {
          'backdrops': [
            {'file_path': '/still.jpg'},
          ],
        },
        'release_dates': {
          'results': [
            {
              'iso_3166_1': 'US',
              'release_dates': [
                {'certification': 'PG-13'},
              ],
            },
          ],
        },
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final detail = await repository.detail(
      const ContentItem(
        id: 'movie-505642',
        remoteId: 505642,
        mediaType: 'movie',
        title: 'Black Panther',
        subtitle: 'Movie',
        year: 2022,
        genre: 'Action',
        type: 'Movie',
        rating: 7,
        palette: [],
        glyph: Icons.movie_rounded,
        description: 'Fallback',
      ),
    );

    expect(detail.item.title, 'Black Panther: Wakanda Forever');
    expect(detail.item.imdbId, 'tt9114286');
    expect(detail.item.runtime, '2h 42m');
    expect(detail.item.trailerKey, 'abc123');
    expect(detail.studio, 'Marvel Studios');
    expect(detail.certification, 'PG-13');
    expect(detail.cast.single.name, 'Letitia Wright');
    expect(detail.reviews.single.title, '8.0 / 10');
    expect(detail.watchProviders.single, 'Disney Plus');
    expect(detail.backdropUrls.single, contains('/w780/still.jpg'));
  });

  test(
    'TMDB repository hides Disney and Pixar recommendations for tester account',
    () async {
      final api = Api();
      api.general.httpClientAdapter = _FakeAdapter((options) {
        switch (options.path) {
          case '$_tmdbProxyBaseUrl/movie/949':
            if (options.queryParameters['append_to_response'] != null) {
              return {
                'id': 949,
                'title': 'Heat',
                'overview': 'A master thief squares off with a detective.',
                'poster_path': '/heat.jpg',
                'backdrop_path': '/heat-bg.jpg',
                'release_date': '1995-12-15',
                'runtime': 170,
                'status': 'Released',
                'vote_average': 7.9,
                'genres': [
                  {'id': 80, 'name': 'Crime'},
                  {'id': 18, 'name': 'Drama'},
                ],
                'production_companies': [
                  {'name': 'Warner Bros.'},
                ],
                'spoken_languages': [
                  {'english_name': 'English'},
                ],
                'videos': {'results': const []},
                'credits': {'cast': const []},
                'reviews': {'results': const []},
                'recommendations': {
                  'results': [
                    {
                      'id': 100,
                      'title': 'Frozen',
                      'overview': 'A snow queen changes a kingdom.',
                      'release_date': '2013-11-27',
                      'vote_average': 7.2,
                      'genre_ids': [16, 12],
                    },
                    {
                      'id': 603,
                      'title': 'The Matrix',
                      'overview': 'A hacker learns the truth.',
                      'release_date': '1999-03-31',
                      'vote_average': 8.2,
                      'genre_ids': [28, 878],
                    },
                  ],
                },
                'similar': {
                  'results': [
                    {
                      'id': 862,
                      'title': 'Toy Story',
                      'overview': 'Toys come to life when nobody is around.',
                      'release_date': '1995-11-22',
                      'vote_average': 8.3,
                      'genre_ids': [16, 35],
                    },
                  ],
                },
                'watch/providers': {'results': const {}},
                'images': {'backdrops': const []},
                'release_dates': {'results': const []},
              };
            }
            return {
              'production_companies': [
                {'name': 'Warner Bros.'},
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/100':
            return {
              'production_companies': [
                {'name': 'Walt Disney Animation Studios'},
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/603':
            return {
              'production_companies': [
                {'name': 'Village Roadshow Pictures'},
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/862':
            return {
              'production_companies': [
                {'name': 'Pixar Animation Studios'},
              ],
            };
        }
        fail('Unexpected path: ${options.path}');
      });

      final repository = TmdbRepository(
        api: api,
        apiKey: 'api-key',
        currentUserEmail: 'tester@vexellab.com',
      );
      final detail = await repository.detail(
        const ContentItem(
          id: 'movie-949',
          remoteId: 949,
          mediaType: 'movie',
          title: 'Heat',
          subtitle: 'Movie',
          year: 1995,
          genre: 'Crime',
          type: 'Movie',
          rating: 7.9,
          palette: [],
          glyph: Icons.movie_rounded,
          description: 'Fallback',
        ),
      );

      expect(detail.recommendations.map((item) => item.title), ['The Matrix']);
      expect(detail.similar, isEmpty);
    },
  );

  test('TMDB repository parses appended TV external IMDb ID', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '$_tmdbProxyBaseUrl/tv/94605');
      expect(
        options.queryParameters['append_to_response'],
        contains('external_ids'),
      );
      return {
        'id': 94605,
        'name': 'Arcane',
        'overview': 'Two sisters fight from opposite sides.',
        'first_air_date': '2021-11-06',
        'episode_run_time': [42],
        'status': 'Returning Series',
        'vote_average': 9.0,
        'genres': [
          {'id': 16, 'name': 'Animation'},
          {'id': 18, 'name': 'Drama'},
        ],
        'networks': [
          {'name': 'Netflix'},
        ],
        'spoken_languages': [
          {'english_name': 'English'},
        ],
        'videos': {'results': []},
        'credits': {'cast': []},
        'reviews': {'results': []},
        'recommendations': {'results': []},
        'similar': {'results': []},
        'watch/providers': {'results': {}},
        'images': {'backdrops': []},
        'content_ratings': {'results': []},
        'external_ids': {'imdb_id': 'tt11126994'},
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final detail = await repository.detail(
      const ContentItem(
        id: 'tv-94605',
        remoteId: 94605,
        mediaType: 'tv',
        title: 'Arcane',
        subtitle: 'Series',
        year: 2021,
        genre: 'Animation',
        type: 'TV Show',
        rating: 9,
        palette: [],
        glyph: Icons.live_tv_rounded,
        description: 'Fallback',
      ),
    );

    expect(detail.item.imdbId, 'tt11126994');
  });

  test('TMDB repository parses movie and TV genre names', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      if (options.path.endsWith('/genre/movie/list')) {
        return {
          'genres': [
            {'id': 28, 'name': 'Action'},
            {'id': 878, 'name': 'Science Fiction'},
          ],
        };
      }
      expect(options.path, '$_tmdbProxyBaseUrl/genre/tv/list');
      return {
        'genres': [
          {'id': 10759, 'name': 'Action & Adventure'},
          {'id': 18, 'name': 'Drama'},
        ],
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final genres = await repository.genres();

    expect(genres, [
      'Action',
      'Science Fiction',
      'Action & Adventure',
      'Drama',
    ]);
  });

  test('TMDB repository reports missing credentials in direct mode', () async {
    final repository = TmdbRepository(api: Api(), usesServerProxy: false);

    expect(
      repository.trending,
      throwsA(isA<MissingTmdbCredentialsException>()),
    );
  });

  test('TMDB repository resolves Letterboxd rows by IMDb id', () async {
    final api = Api();
    final calls = <String>[];
    api.general.httpClientAdapter = _FakeAdapter((options) {
      calls.add(options.path);
      expect(options.path, '$_tmdbProxyBaseUrl/find/tt0113277');
      expect(options.queryParameters['external_source'], 'imdb_id');
      return {
        'movie_results': [
          {
            'id': 949,
            'media_type': 'movie',
            'title': 'Heat',
            'overview': 'A master thief squares off with a detective.',
            'poster_path': '/heat-poster.jpg',
            'backdrop_path': '/heat-backdrop.jpg',
            'release_date': '1995-12-15',
            'vote_average': 7.9,
            'genre_ids': [80, 18],
          },
        ],
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final item = await repository.resolveMovie(
      imdbId: 'tt0113277',
      title: 'Heat',
      year: 1995,
    );

    expect(calls, ['$_tmdbProxyBaseUrl/find/tt0113277']);
    expect(item?.id, 'movie-949');
    expect(item?.remoteId, 949);
    expect(item?.imdbId, 'tt0113277');
    expect(item?.posterUrl, contains('/w500/heat-poster.jpg'));
    expect(item?.genre, 'Crime / Drama');
  });

  test('TMDB repository resolves Letterboxd rows by title and year', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.path, '$_tmdbProxyBaseUrl/search/movie');
      expect(options.queryParameters['query'], 'Heat');
      expect(options.queryParameters['primary_release_year'], 1995);
      return {
        'results': [
          {
            'id': 949,
            'media_type': 'movie',
            'title': 'Heat',
            'overview': 'A master thief squares off with a detective.',
            'poster_path': '/heat-poster.jpg',
            'backdrop_path': '/heat-backdrop.jpg',
            'release_date': '1995-12-15',
            'vote_average': 7.9,
            'genre_ids': [80, 18],
          },
        ],
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final item = await repository.resolveMovie(title: 'Heat', year: 1995);

    expect(item?.remoteId, 949);
    expect(item?.title, 'Heat');
    expect(item?.year, 1995);
    expect(item?.backdropUrl, contains('/w780/heat-backdrop.jpg'));
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
