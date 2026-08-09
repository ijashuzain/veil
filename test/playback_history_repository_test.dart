import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/src/features/auth/repository/auth_repository.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/features/playback_history/repository/playback_history_repository.dart';
import 'package:veil/src/features/playback_history/view_model/playback_history_view_model.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('history entry round trips TV request and manual JSON fields', () {
    final startedAt = DateTime.utc(2026, 8, 8, 12, 30);
    final entry = PlaybackHistoryEntry.fromRequest(
      const PlaybackRequest(
        item: _tv,
        server: PlaybackServer.four,
        season: 0,
        episode: -2,
      ),
      startedAt,
    );

    expect(entry.entryKey, 'tv:94997:four:1:1');
    expect(
      entry.toJson().values.every(
        (value) =>
            value == null || value is String || value is num || value is bool,
      ),
      isTrue,
    );

    final restored = PlaybackHistoryEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    );
    final item = restored.toContentItem();
    final request = restored.toRequest();

    expect(restored.startedAt, startedAt);
    expect(item.id, 'tv-94997');
    expect(item.remoteId, 94997);
    expect(item.imdbId, 'tt7654321');
    expect(item.title, 'Series');
    expect(item.posterUrl, 'https://image.test/tv-poster.jpg');
    expect(item.backdropUrl, 'https://image.test/tv-backdrop.jpg');
    expect(item.runtime, '45m');
    expect(item.glyph, Icons.live_tv_rounded);
    expect(item.palette, const [
      Color(0xFF1B1B1D),
      Color(0xFF8B1018),
      Color(0xFF050505),
    ]);
    expect(request.server, PlaybackServer.four);
    expect(request.season, 1);
    expect(request.episode, 1);
  });

  test('parsed season and episode are clamped to one', () {
    final json =
        PlaybackHistoryEntry.fromRequest(
            _movieRequest,
            DateTime.utc(2026, 8, 8),
          ).toJson()
          ..['season'] = -3
          ..['episode'] = 0;

    final entry = PlaybackHistoryEntry.fromJson(json);

    expect(entry.season, 1);
    expect(entry.episode, 1);
  });

  test('record keeps newest first, deduplicates, and isolates users', () async {
    final times = [
      DateTime.utc(2026, 8, 8, 12),
      DateTime.utc(2026, 8, 8, 13),
      DateTime.utc(2026, 8, 8, 14),
    ];
    var clockIndex = 0;
    final repository = PlaybackHistoryRepository(
      now: () => times[clockIndex++],
    );

    await repository.record('user-a', _movieRequest);
    await repository.record('user-a', _tvRequest);
    final entries = await repository.record('user-a', _movieRequest);

    expect(entries.map((entry) => entry.tmdbId), [1284041, 94997]);
    expect(entries.first.startedAt, times.last);
    expect(repository.load('user-a'), hasLength(2));
    expect(repository.load('user-b'), isEmpty);
    expect(
      LocalStorage.getString(PlaybackHistoryRepository.storageKeyFor('user-a')),
      isNotNull,
    );
    expect(
      PlaybackHistoryRepository.storageKeyFor('user-a'),
      'veil.playback_history.v1.user-a',
    );
  });

  test('load sorts, deduplicates, and skips malformed rows', () async {
    final older = PlaybackHistoryEntry.fromRequest(
      _movieRequest,
      DateTime.utc(2026, 8, 8, 10),
    );
    final newer = PlaybackHistoryEntry.fromRequest(
      _movieRequest,
      DateTime.utc(2026, 8, 8, 12),
    );
    final tv = PlaybackHistoryEntry.fromRequest(
      _tvRequest,
      DateTime.utc(2026, 8, 8, 11),
    );
    await LocalStorage.setString(
      PlaybackHistoryRepository.storageKeyFor('user-a'),
      jsonEncode([
        older.toJson(),
        {...tv.toJson(), 'tmdbId': 0},
        {...tv.toJson(), 'title': ''},
        {...tv.toJson(), 'server': 'five'},
        'not-an-object',
        tv.toJson(),
        newer.toJson(),
      ]),
    );

    final entries = PlaybackHistoryRepository().load('user-a');

    expect(entries.map((entry) => entry.tmdbId), [1284041, 94997]);
    expect(entries.first.startedAt, newer.startedAt);
  });

  test(
    'malformed local JSON returns empty history and record recovers',
    () async {
      final key = PlaybackHistoryRepository.storageKeyFor('user-a');
      await LocalStorage.setString(key, '{broken');
      final repository = PlaybackHistoryRepository(
        now: () => DateTime.utc(2026, 8, 8, 12),
      );

      expect(repository.load('user-a'), isEmpty);

      await repository.record('user-a', _movieRequest);

      expect(repository.load('user-a'), hasLength(1));
      expect(jsonDecode(LocalStorage.getString(key)!), isA<List<dynamic>>());

      await LocalStorage.setString(key, jsonEncode({'entries': []}));
      expect(repository.load('user-a'), isEmpty);
    },
  );

  test('record caps history at twenty newest entries', () async {
    var minute = 0;
    final repository = PlaybackHistoryRepository(
      now: () => DateTime.utc(2026, 8, 8, 12).add(Duration(minutes: minute++)),
    );

    for (var id = 1; id <= 21; id += 1) {
      await repository.record(
        'user-a',
        PlaybackRequest(
          item: _movie.copyWith(id: 'movie-$id', remoteId: id),
          server: PlaybackServer.two,
        ),
      );
    }

    expect(
      repository.load('user-a').map((entry) => entry.tmdbId),
      List.generate(20, (index) => 21 - index),
    );
  });

  test('remove deletes one entry and clear removes user storage', () async {
    var hour = 12;
    final repository = PlaybackHistoryRepository(
      now: () => DateTime.utc(2026, 8, 8, hour++),
    );
    await repository.record('user-a', _movieRequest);
    await repository.record('user-a', _tvRequest);
    final movieKey = repository
        .load('user-a')
        .singleWhere((entry) => entry.tmdbId == _movie.remoteId)
        .entryKey;

    final remaining = await repository.remove('user-a', movieKey);

    expect(remaining, hasLength(1));
    expect(remaining.single.tmdbId, _tv.remoteId);

    await repository.clear('user-a');

    expect(repository.load('user-a'), isEmpty);
    expect(
      LocalStorage.getString(PlaybackHistoryRepository.storageKeyFor('user-a')),
      isNull,
    );
  });

  test('repository ignores requests without positive TMDB ids', () async {
    final repository = PlaybackHistoryRepository();
    final request = PlaybackRequest(
      item: _movie.copyWith(id: 'imdb-only', remoteId: 0),
      server: PlaybackServer.one,
    );

    expect(await repository.record('user-a', request), isEmpty);
    expect(repository.load('user-a'), isEmpty);
  });

  test('history notifier no-ops without an authenticated user', () async {
    final repository = _SpyPlaybackHistoryRepository();
    final container = ProviderContainer(
      overrides: [
        authViewModelProvider.overrideWithValue(const AuthViewState()),
        playbackHistoryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      playbackHistoryViewModelProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final notifier = container.read(playbackHistoryViewModelProvider.notifier);

    await notifier.record(_movieRequest);
    await notifier.remove('movie:1284041:two:1:1');
    await notifier.clear();

    expect(container.read(playbackHistoryViewModelProvider), isEmpty);
    expect(repository.loadCalls, 0);
    expect(repository.mutationCalls, 0);
  });

  test(
    'history notifier does not publish stale account mutation results',
    () async {
      final userA = _user('user-a');
      final userB = _user('user-b');
      final userBEntry = PlaybackHistoryEntry.fromRequest(
        _tvRequest,
        DateTime.utc(2026, 8, 8, 13),
      );
      final staleUserAEntry = PlaybackHistoryEntry.fromRequest(
        _movieRequest,
        DateTime.utc(2026, 8, 8, 12),
      );
      final repository = _DelayedPlaybackHistoryRepository(userBEntry);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SwitchingAuthRepository(userA, userB),
          ),
          playbackHistoryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        playbackHistoryViewModelProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final pendingRecord = container
          .read(playbackHistoryViewModelProvider.notifier)
          .record(_movieRequest);
      await container
          .read(authViewModelProvider.notifier)
          .submit(email: 'b@example.com', password: 'password');

      expect(
        container.read(playbackHistoryViewModelProvider).single.tmdbId,
        userBEntry.tmdbId,
      );

      repository.recordCompleter.complete([staleUserAEntry]);
      await pendingRecord;

      expect(repository.recordedUserIds, ['user-a']);
      expect(
        container.read(playbackHistoryViewModelProvider).single.tmdbId,
        userBEntry.tmdbId,
      );
    },
  );
}

const _movie = ContentItem(
  id: 'movie-1284041',
  remoteId: 1284041,
  mediaType: 'movie',
  imdbId: 'tt1234567',
  title: 'Movie',
  subtitle: 'A film',
  year: 2026,
  genre: 'Drama',
  type: 'Movie',
  rating: 8.2,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'Movie fixture',
  posterUrl: 'https://image.test/movie-poster.jpg',
  backdropUrl: 'https://image.test/movie-backdrop.jpg',
  runtime: '2h',
);

const _tv = ContentItem(
  id: 'tv-94997',
  remoteId: 94997,
  mediaType: 'tv',
  imdbId: 'tt7654321',
  title: 'Series',
  subtitle: 'A show',
  year: 2025,
  genre: 'Mystery',
  type: 'TV Show',
  rating: 7.8,
  palette: [Colors.black, Colors.blue],
  glyph: Icons.live_tv_rounded,
  description: 'TV fixture',
  posterUrl: 'https://image.test/tv-poster.jpg',
  backdropUrl: 'https://image.test/tv-backdrop.jpg',
  runtime: '45m',
);

const _movieRequest = PlaybackRequest(item: _movie, server: PlaybackServer.two);

const _tvRequest = PlaybackRequest(
  item: _tv,
  server: PlaybackServer.three,
  season: 2,
  episode: 3,
);

User _user(String id) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: '$id@example.com',
    createdAt: '2026-08-08T00:00:00Z',
  );
}

class _SpyPlaybackHistoryRepository extends PlaybackHistoryRepository {
  var loadCalls = 0;
  var mutationCalls = 0;

  @override
  List<PlaybackHistoryEntry> load(String userId) {
    loadCalls += 1;
    return const [];
  }

  @override
  Future<List<PlaybackHistoryEntry>> record(
    String userId,
    PlaybackRequest request,
  ) async {
    mutationCalls += 1;
    return const [];
  }

  @override
  Future<List<PlaybackHistoryEntry>> remove(
    String userId,
    String entryKey,
  ) async {
    mutationCalls += 1;
    return const [];
  }

  @override
  Future<void> clear(String userId) async {
    mutationCalls += 1;
  }
}

class _DelayedPlaybackHistoryRepository extends PlaybackHistoryRepository {
  _DelayedPlaybackHistoryRepository(this.userBEntry);

  final PlaybackHistoryEntry userBEntry;
  final recordCompleter = Completer<List<PlaybackHistoryEntry>>();
  final recordedUserIds = <String>[];

  @override
  List<PlaybackHistoryEntry> load(String userId) {
    return userId == 'user-b' ? [userBEntry] : const [];
  }

  @override
  Future<List<PlaybackHistoryEntry>> record(
    String userId,
    PlaybackRequest request,
  ) {
    recordedUserIds.add(userId);
    return recordCompleter.future;
  }
}

class _SwitchingAuthRepository extends AuthRepository {
  _SwitchingAuthRepository(this._currentUser, this._nextUser);

  User? _currentUser;
  final User _nextUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    _currentUser = _nextUser;
    return _nextUser;
  }
}
