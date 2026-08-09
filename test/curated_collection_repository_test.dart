import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/catalog/repository/curated_collection_repository.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  test('maps defensive collection metadata from Shegu root', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.uri.toString(), 'https://lists.shegu.st/joy');
      expect(options.headers['Authorization'], isNull);
      return {
        'collections': [
          {
            'id': 'psychological-thrillers',
            'title': ' Psychological Thrillers ',
            'description': 'Slow-burn thrillers.',
            'tags': [' genre ', 42, '', 'thriller'],
            'path': '/joy/ignored',
          },
          {'id': '', 'title': 'Missing ID'},
          {'id': 'missing-title'},
          'invalid',
        ],
        'count': 99,
      };
    });
    final repository = CuratedCollectionRepository(
      api: api,
      tmdbRepository: _FilteringTmdbRepository(),
    );

    final collections = await repository.collections();

    expect(collections, hasLength(1));
    expect(collections.single.id, 'psychological-thrillers');
    expect(collections.single.title, 'Psychological Thrillers');
    expect(collections.single.description, 'Slow-burn thrillers.');
    expect(collections.single.tags, ['genre', 'thriller']);
  });

  test('malformed Shegu roots and envelopes return empty lists', () async {
    final roots = <Object?>[
      const [],
      const {'collections': 'invalid'},
      const {'items': 'invalid'},
    ];
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((_) => roots.removeAt(0));
    final repository = CuratedCollectionRepository(
      api: api,
      tmdbRepository: _FilteringTmdbRepository(),
    );

    expect(await repository.collections(), isEmpty);
    expect(await repository.collections(), isEmpty);
    expect(await repository.items('malformed'), isEmpty);
  });

  test(
    'maps approved movie and TV fields and rejects invalid TMDB identities',
    () async {
      final api = Api();
      api.general.httpClientAdapter = _FakeAdapter((options) {
        expect(
          options.uri.toString(),
          'https://lists.shegu.st/joy/psychological-thrillers?limit=12',
        );
        expect(options.uri.queryParameters, {'limit': '12'});
        expect(options.headers['Authorization'], isNull);
        return {
          'items': [
            {
              'type': 'movie',
              'title': 'Movie Pick',
              'year': 2026,
              'description': 'Movie description',
              'poster': 'https://image.tmdb.org/t/p/w200/movie.jpg',
              'score': 12.75,
              'ids': {'tmdb': 101, 'imdb': 'tt0000101'},
              'ratings': {
                'imdb': {'value': 1},
              },
              'parental': {'age_rating': 99},
              'streaming': {
                'provider': 'Ignored',
                'url': 'https://click.example',
              },
              'justwatch': {'url': 'https://click.example'},
            },
            {
              'type': 'TV_series',
              'title': 'TV Pick',
              'year': 2024,
              'description': 'TV description',
              'poster': '   ',
              'score': -4,
              'ids': {'tmdb': 202, 'imdb': 1234},
            },
            {
              'type': 'movie',
              'title': 'Missing TMDB',
              'ids': {'imdb': 'tt1'},
            },
            {
              'type': 'movie',
              'title': 'Zero TMDB',
              'ids': {'tmdb': 0},
            },
            {
              'type': 'movie',
              'title': 'Fractional TMDB',
              'ids': {'tmdb': 3.5},
            },
            {
              'type': 'podcast',
              'title': 'Unknown type',
              'ids': {'tmdb': 303},
            },
            {
              'type': 'movie',
              'title': '',
              'ids': {'tmdb': 404},
            },
          ],
        };
      });
      final repository = CuratedCollectionRepository(
        api: api,
        tmdbRepository: _FilteringTmdbRepository(),
      );

      final items = await repository.items('psychological-thrillers');

      expect(items.map((item) => item.id), ['movie-101', 'tv-202']);
      final movie = items.first;
      expect(movie.remoteId, 101);
      expect(movie.mediaType, 'movie');
      expect(movie.type, 'Movie');
      expect(movie.subtitle, 'Movie');
      expect(movie.imdbId, 'tt0000101');
      expect(movie.rating, 10);
      expect(movie.palette, const [VeilColors.bg2, VeilColors.bg4]);
      expect(movie.glyph, Icons.movie_rounded);
      expect(
        movie.posterUrl,
        AppEnvironment.resolveTmdbImageUrl(
          'https://image.tmdb.org/t/p/w200/movie.jpg',
        ),
      );
      expect(movie.backdropUrl, isNull);
      expect(movie.trailerKey, isNull);
      expect(movie.progress, 0);
      expect(movie.progressLabel, isEmpty);

      final tv = items.last;
      expect(tv.mediaType, 'tv');
      expect(tv.type, 'TV Show');
      expect(tv.subtitle, 'TV Show');
      expect(tv.imdbId, isNull);
      expect(tv.rating, 0);
      expect(tv.posterUrl, isNull);
      expect(tv.glyph, Icons.live_tv_rounded);
    },
  );

  test('applies current-user TMDB restriction to every valid item', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((_) {
      return {
        'items': [
          _itemJson(tmdbId: 101, title: 'Visible'),
          _itemJson(tmdbId: 202, title: 'Hidden'),
        ],
      };
    });
    final tmdbRepository = _FilteringTmdbRepository(hiddenIds: const {202});
    final repository = CuratedCollectionRepository(
      api: api,
      tmdbRepository: tmdbRepository,
    );

    final items = await repository.items('restricted');

    expect(items.map((item) => item.title), ['Visible']);
    expect(tmdbRepository.checkedIds, [101, 202]);
  });

  test(
    'caches successes by encoded collection and limit but not errors',
    () async {
      var requests = 0;
      var failNext = true;
      final uris = <Uri>[];
      final api = Api();
      api.general.httpClientAdapter = _FakeAdapter((options) {
        requests += 1;
        uris.add(options.uri);
        if (failNext) {
          failNext = false;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'offline',
          );
        }
        return {
          'items': [_itemJson(tmdbId: requests, title: 'Request $requests')],
        };
      });
      final repository = CuratedCollectionRepository(
        api: api,
        tmdbRepository: _FilteringTmdbRepository(),
      );

      await expectLater(
        repository.items('mind / games'),
        throwsA(isA<DioException>()),
      );
      final first = await repository.items('mind / games');
      final cached = await repository.items('mind / games');
      final differentLimit = await repository.items('mind / games', limit: 6);

      expect(requests, 3);
      expect(identical(first, cached), isTrue);
      expect(differentLimit.single.id, 'movie-3');
      expect(
        uris.first.toString(),
        'https://lists.shegu.st/joy/mind%20%2F%20games?limit=12',
      );
      expect(uris.last.queryParameters, {'limit': '6'});
    },
  );

  test('rejects empty collection IDs and non-positive limits', () async {
    final repository = CuratedCollectionRepository(
      api: Api(),
      tmdbRepository: _FilteringTmdbRepository(),
    );

    expect(() => repository.items('  '), throwsArgumentError);
    expect(() => repository.items('valid', limit: 0), throwsArgumentError);
  });
}

Map<String, Object?> _itemJson({required int tmdbId, required String title}) {
  return {
    'type': 'movie',
    'title': title,
    'year': 2026,
    'description': '$title description',
    'poster': '',
    'score': 7.5,
    'ids': {'tmdb': tmdbId},
  };
}

class _FilteringTmdbRepository extends TmdbRepository {
  _FilteringTmdbRepository({this.hiddenIds = const {}}) : super(api: Api());

  final Set<int> hiddenIds;
  final List<int> checkedIds = [];

  @override
  Future<bool> shouldHideForCurrentUser(ContentItem item) async {
    checkedIds.add(item.remoteId!);
    return hiddenIds.contains(item.remoteId);
  }
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Object? Function(RequestOptions options) handler;

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
