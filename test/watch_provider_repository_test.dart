import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/catalog/view_model/provider_catalog_providers.dart';
import 'package:veil/src/shared/models/content_item.dart';

const _tmdbProxyBaseUrl =
    'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb/3';

void main() {
  test('watch providers merge movie and TV lists using US priority', () async {
    final api = Api();
    api.general.httpClientAdapter = _FakeAdapter((options) {
      expect(options.queryParameters, containsPair('watch_region', 'US'));
      expect(options.queryParameters, containsPair('language', 'en-US'));
      switch (options.path) {
        case '$_tmdbProxyBaseUrl/watch/providers/movie':
          return {
            'results': [
              {
                'provider_id': 8,
                'provider_name': 'Netflix',
                'logo_path': '',
                'display_priority': 40,
                'display_priorities': {'US': 5},
              },
              {
                'provider_id': 15,
                'provider_name': 'Hulu',
                'logo_path': '/hulu.jpg',
                'display_priority': 30,
                'display_priorities': {'US': 2},
              },
              {
                'provider_id': 350,
                'provider_name': 'Apple TV Plus',
                'logo_path': '/apple.jpg',
                'display_priority': 3,
              },
            ],
          };
        case '$_tmdbProxyBaseUrl/watch/providers/tv':
          return {
            'results': [
              {
                'provider_id': 8,
                'provider_name': 'Netflix',
                'logo_path': '/netflix.jpg',
                'display_priority': 20,
                'display_priorities': {'US': 1},
              },
              {
                'provider_id': 337,
                'provider_name': 'Disney Plus',
                'logo_path': '/disney.jpg',
                'display_priority': 30,
                'display_priorities': {'US': 2},
              },
            ],
          };
      }
      fail('Unexpected path: ${options.path}');
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final providers = await repository.watchProviders();

    expect(providers.map((provider) => provider.id), [8, 337, 15, 350]);
    expect(providers.first.displayPriority, 1);
    expect(providers.first.logoPath, '/netflix.jpg');
    expect(providers.first.logoUrl, contains('/w154/netflix.jpg'));
    expect(providers.last.displayPriority, 3);
  });

  test('discover by provider sends movie and TV query parameters', () async {
    final api = Api();
    final calls = <RequestOptions>[];
    api.general.httpClientAdapter = _FakeAdapter((options) {
      calls.add(options);
      return {
        'results': [
          if (options.path.endsWith('/movie'))
            {
              'id': 949,
              'title': 'Heat',
              'release_date': '1995-12-15',
              'vote_average': 7.9,
              'genre_ids': [80],
            }
          else
            {
              'id': 94605,
              'name': 'Arcane',
              'first_air_date': '2021-11-06',
              'vote_average': 9.0,
              'genre_ids': [16],
            },
        ],
      };
    });

    final repository = TmdbRepository(api: api, apiKey: 'api-key');
    final movies = await repository.discoverByProvider(
      providerId: 8,
      mediaType: 'movie',
      page: 2,
    );
    final tv = await repository.discoverByProvider(
      providerId: 8,
      mediaType: 'tv',
    );

    expect(movies.single.id, 'movie-949');
    expect(tv.single.id, 'tv-94605');
    expect(calls.map((call) => call.path), [
      '$_tmdbProxyBaseUrl/discover/movie',
      '$_tmdbProxyBaseUrl/discover/tv',
    ]);
    for (final call in calls) {
      expect(call.queryParameters, containsPair('watch_region', 'US'));
      expect(call.queryParameters, containsPair('with_watch_providers', 8));
      expect(
        call.queryParameters,
        containsPair('with_watch_monetization_types', 'flatrate|free|ads'),
      );
      expect(call.queryParameters, containsPair('include_adult', false));
      expect(call.queryParameters, containsPair('sort_by', 'popularity.desc'));
    }
    expect(calls.first.queryParameters, containsPair('page', 2));
    expect(calls.last.queryParameters, containsPair('page', 1));
  });

  test(
    'provider discovery preserves tester Disney and Pixar restriction',
    () async {
      final api = Api();
      api.general.httpClientAdapter = _FakeAdapter((options) {
        switch (options.path) {
          case '$_tmdbProxyBaseUrl/discover/movie':
            return {
              'results': [
                {
                  'id': 100,
                  'title': 'Frozen',
                  'release_date': '2013-11-27',
                  'vote_average': 7.2,
                  'genre_ids': [16],
                },
                {
                  'id': 949,
                  'title': 'Heat',
                  'release_date': '1995-12-15',
                  'vote_average': 7.9,
                  'genre_ids': [80],
                },
              ],
            };
          case '$_tmdbProxyBaseUrl/discover/tv':
            return {
              'results': [
                {
                  'id': 200,
                  'name': 'Pixar Stories',
                  'first_air_date': '2020-01-01',
                  'vote_average': 8.0,
                  'genre_ids': [16],
                },
                {
                  'id': 94605,
                  'name': 'Arcane',
                  'first_air_date': '2021-11-06',
                  'vote_average': 9.0,
                  'genre_ids': [16],
                },
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/100':
            return {
              'production_companies': [
                {'name': 'Walt Disney Animation Studios'},
              ],
            };
          case '$_tmdbProxyBaseUrl/movie/949':
            return {
              'production_companies': [
                {'name': 'Warner Bros.'},
              ],
            };
          case '$_tmdbProxyBaseUrl/tv/200':
            return {
              'networks': [
                {'name': 'Pixar Television'},
              ],
              'production_companies': const [],
            };
          case '$_tmdbProxyBaseUrl/tv/94605':
            return {
              'networks': [
                {'name': 'Netflix'},
              ],
              'production_companies': const [],
            };
        }
        fail('Unexpected path: ${options.path}');
      });

      final repository = TmdbRepository(
        api: api,
        apiKey: 'api-key',
        currentUserEmail: 'tester@vexellab.com',
      );
      final movies = await repository.discoverByProvider(
        providerId: 8,
        mediaType: 'movie',
      );
      final tv = await repository.discoverByProvider(
        providerId: 8,
        mediaType: 'tv',
      );

      expect(movies.map((item) => item.title), ['Heat']);
      expect(tv.map((item) => item.title), ['Arcane']);
    },
  );

  test('discover by provider rejects unsupported media types', () {
    final repository = TmdbRepository(api: Api(), apiKey: 'api-key');

    expect(
      () => repository.discoverByProvider(providerId: 8, mediaType: 'person'),
      throwsArgumentError,
    );
  });

  group('provider catalog notifier', () {
    test('loads page 1 as initial state', () async {
      final repository = _FakeTmdbRepository((request) {
        expect(request, (providerId: 8, mediaType: 'movie', page: 1));
        return [_item('movie-1'), _item('movie-2')];
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(provider.notifier).loadInitial();

      final state = container.read(provider);
      expect(state.items.map((item) => item.id), ['movie-1', 'movie-2']);
      expect(state.page, 1);
      expect(state.canLoadMore, isTrue);
      expect(state.loadStatus, isA<StatusSuccess>());
      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
      ]);
    });

    test('appends page 2 and deduplicates items by id', () async {
      final repository = _FakeTmdbRepository((request) {
        return switch (request.page) {
          1 => [_item('movie-1'), _item('movie-2')],
          2 => [_item('movie-2'), _item('movie-3'), _item('movie-3')],
          _ => fail('Unexpected request: $request'),
        };
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(provider.notifier).loadInitial();
      await container.read(provider.notifier).loadMore();

      expect(container.read(provider).items.map((item) => item.id), [
        'movie-1',
        'movie-2',
        'movie-3',
      ]);
      expect(container.read(provider).page, 2);
      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
        (providerId: 8, mediaType: 'movie', page: 2),
      ]);
    });

    test('empty page marks catalog complete', () async {
      final repository = _FakeTmdbRepository((request) {
        return request.page == 1 ? [_item('movie-1')] : const [];
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(provider.notifier).loadInitial();
      await container.read(provider.notifier).loadMore();
      await container.read(provider.notifier).loadMore();

      final state = container.read(provider);
      expect(state.items.map((item) => item.id), ['movie-1']);
      expect(state.page, 2);
      expect(state.canLoadMore, isFalse);
      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
        (providerId: 8, mediaType: 'movie', page: 2),
      ]);
    });

    test(
      'load-more failure preserves items and blocks automatic calls',
      () async {
        final repository = _FakeTmdbRepository((request) {
          if (request.page == 1) return [_item('movie-1')];
          throw StateError('page 2 failed');
        });
        final container = _catalogContainer(repository);
        addTearDown(container.dispose);
        final provider = providerCatalogProvider(8, 'movie');
        final subscription = container.listen(
          provider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        await container.read(provider.notifier).loadInitial();
        await container.read(provider.notifier).loadMore();
        await container.read(provider.notifier).loadMore();

        final state = container.read(provider);
        expect(state.items.map((item) => item.id), ['movie-1']);
        expect(state.page, 1);
        expect(state.canLoadMore, isTrue);
        expect(state.isLoadingMore, isFalse);
        expect(state.loadMoreError, contains('page 2 failed'));
        expect(repository.requests, [
          (providerId: 8, mediaType: 'movie', page: 1),
          (providerId: 8, mediaType: 'movie', page: 2),
        ]);
      },
    );

    test('retry clears load-more error and retries failed page', () async {
      var page2Attempts = 0;
      final repository = _FakeTmdbRepository((request) {
        if (request.page == 1) return [_item('movie-1')];
        page2Attempts++;
        if (page2Attempts == 1) throw StateError('temporary failure');
        return [_item('movie-2')];
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(provider.notifier).loadInitial();
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).loadMoreError, isNotEmpty);

      await container.read(provider.notifier).retryLoadMore();

      final state = container.read(provider);
      expect(state.items.map((item) => item.id), ['movie-1', 'movie-2']);
      expect(state.page, 2);
      expect(state.loadMoreError, isEmpty);
      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
        (providerId: 8, mediaType: 'movie', page: 2),
        (providerId: 8, mediaType: 'movie', page: 2),
      ]);
    });

    test('concurrent load-more calls issue one request', () async {
      final page2 = Completer<List<ContentItem>>();
      final repository = _FakeTmdbRepository((request) {
        if (request.page == 1) return [_item('movie-1')];
        return page2.future;
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final notifier = container.read(provider.notifier);
      await notifier.loadInitial();

      final first = notifier.loadMore();
      final second = notifier.loadMore();

      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
        (providerId: 8, mediaType: 'movie', page: 2),
      ]);
      page2.complete([_item('movie-2')]);
      await Future.wait([first, second]);
      expect(container.read(provider).items.map((item) => item.id), [
        'movie-1',
        'movie-2',
      ]);
    });

    test('movie and TV families keep independent state', () async {
      final repository = _FakeTmdbRepository((request) {
        return [_item('${request.mediaType}-${request.page}')];
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final movies = providerCatalogProvider(8, 'movie');
      final tv = providerCatalogProvider(8, 'tv');
      final movieSubscription = container.listen(
        movies,
        (_, _) {},
        fireImmediately: true,
      );
      final tvSubscription = container.listen(
        tv,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(movieSubscription.close);
      addTearDown(tvSubscription.close);

      await Future.wait([
        container.read(movies.notifier).loadInitial(),
        container.read(tv.notifier).loadInitial(),
      ]);
      await container.read(movies.notifier).loadMore();

      expect(container.read(movies).items.map((item) => item.id), [
        'movie-1',
        'movie-2',
      ]);
      expect(container.read(movies).page, 2);
      expect(container.read(tv).items.map((item) => item.id), ['tv-1']);
      expect(container.read(tv).page, 1);
      expect(
        repository.requests,
        containsAll([
          (providerId: 8, mediaType: 'movie', page: 1),
          (providerId: 8, mediaType: 'tv', page: 1),
          (providerId: 8, mediaType: 'movie', page: 2),
        ]),
      );
    });

    test('keeps loaded tab state alive without listeners', () async {
      final repository = _FakeTmdbRepository((request) {
        return [_item('movie-${request.page}')];
      });
      final container = _catalogContainer(repository);
      addTearDown(container.dispose);
      final provider = providerCatalogProvider(8, 'movie');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );

      await container.read(provider.notifier).loadInitial();
      subscription.close();
      await pumpEventQueue();

      expect(container.read(provider).items.map((item) => item.id), [
        'movie-1',
      ]);
      expect(container.read(provider).page, 1);
      expect(repository.requests, [
        (providerId: 8, mediaType: 'movie', page: 1),
      ]);
    });
  });
}

typedef _CatalogRequest = ({int providerId, String mediaType, int page});

ProviderContainer _catalogContainer(_FakeTmdbRepository repository) {
  return ProviderContainer(
    overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
  );
}

ContentItem _item(String id) {
  return ContentItem(
    id: id,
    title: id,
    subtitle: '',
    year: 2026,
    genre: 'Drama',
    type: 'Movie',
    rating: 4,
    palette: const [Colors.black, Colors.white],
    glyph: Icons.movie,
    description: '',
  );
}

class _FakeTmdbRepository extends TmdbRepository {
  _FakeTmdbRepository(this.handler) : super(api: Api(), usesServerProxy: true);

  final FutureOr<List<ContentItem>> Function(_CatalogRequest request) handler;
  final List<_CatalogRequest> requests = [];

  @override
  Future<List<ContentItem>> discoverByProvider({
    required int providerId,
    required String mediaType,
    String region = 'US',
    int page = 1,
  }) async {
    final request = (providerId: providerId, mediaType: mediaType, page: page);
    requests.add(request);
    return handler(request);
  }
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
