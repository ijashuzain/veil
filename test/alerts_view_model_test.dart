import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/alerts/view_model/alerts_view_model.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/movie_suggestion.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  test('alerts view model builds real alerts from TMDB sections', () async {
    final repository = _AlertsTmdbRepository();
    final container = ProviderContainer(
      overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(alertsViewModelProvider.notifier).load();
    final state = container.read(alertsViewModelProvider);

    expect(state.loadStatus, const Status.success());
    expect(state.alerts, hasLength(5));
    expect(state.alerts.map((alert) => alert.tag), [
      'TRENDING',
      'TRENDING',
      'COMING SOON',
      'NEW EPISODE',
      'CRITICS PICK',
    ]);
    expect(state.alerts.first.content.title, 'Swapped');
    expect(state.alerts.first.title, contains('Swapped'));
    expect(state.unreadCount, 5);
  });

  test('mark all read clears unread alerts without dropping content', () async {
    final container = ProviderContainer(
      overrides: [
        tmdbRepositoryProvider.overrideWithValue(_AlertsTmdbRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(alertsViewModelProvider.notifier).load();
    container.read(alertsViewModelProvider.notifier).markAllRead();
    final state = container.read(alertsViewModelProvider);

    expect(state.alerts, isNotEmpty);
    expect(state.unreadCount, 0);
    expect(state.alerts.every((alert) => !alert.unread), isTrue);
  });

  test('alerts view model loads follow alerts and movie suggestions', () async {
    final container = ProviderContainer(
      overrides: [
        tmdbRepositoryProvider.overrideWithValue(_AlertsTmdbRepository()),
        socialRepositoryProvider.overrideWithValue(_AlertsSocialRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(alertsViewModelProvider.notifier).load();
    final state = container.read(alertsViewModelProvider);

    expect(state.followRequests, hasLength(1));
    expect(state.followRequests.single.requesterDisplayName, 'Mira');
    expect(state.suggestions, hasLength(1));
    expect(state.suggestions.single.senderDisplayName, 'Ijas');
    expect(state.suggestionUnreadCount, 1);
  });

  test('alerts view model exposes failures instead of dummy data', () async {
    final container = ProviderContainer(
      overrides: [
        tmdbRepositoryProvider.overrideWithValue(_FailingTmdbRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(alertsViewModelProvider.notifier).load();
    final state = container.read(alertsViewModelProvider);

    expect(state.alerts, isEmpty);
    expect(state.loadStatus.errorMessage, contains('network down'));
  });
}

class _AlertsSocialRepository extends SocialRepository {
  @override
  Future<List<FollowRequest>> followRequestsForAlerts() async {
    return [
      FollowRequest.create(
        requesterId: 'member-2',
        recipientId: 'local-user',
        requesterDisplayName: 'Mira',
        recipientDisplayName: 'Ijas',
      ),
    ];
  }

  @override
  Future<List<MovieSuggestion>> movieSuggestions() async {
    return [
      MovieSuggestion.create(
        senderId: 'member-3',
        recipientId: 'local-user',
        senderDisplayName: 'Ijas',
        content: _item('movie-7', 'Sinners'),
      ),
    ];
  }
}

class _AlertsTmdbRepository extends TmdbRepository {
  _AlertsTmdbRepository() : super(api: Api());

  @override
  Future<List<ContentItem>> trending() async {
    return [_item('movie-1', 'Swapped'), _item('tv-2', 'The Boys', type: 'TV')];
  }

  @override
  Future<List<ContentItem>> upcomingMovies() async {
    return [_item('movie-3', '28 Years Later')];
  }

  @override
  Future<List<ContentItem>> airingTodayTv() async {
    return [_item('tv-4', 'Severance', type: 'TV')];
  }

  @override
  Future<List<ContentItem>> topRatedMovies() async {
    return [_item('movie-5', 'Sinners')];
  }

  @override
  Future<List<ContentItem>> popularMovies() async {
    return [_item('movie-6', 'Popular Duplicate')];
  }
}

class _FailingTmdbRepository extends TmdbRepository {
  _FailingTmdbRepository() : super(api: Api());

  @override
  Future<List<ContentItem>> trending() async =>
      throw StateError('network down');

  @override
  Future<List<ContentItem>> upcomingMovies() async => const [];

  @override
  Future<List<ContentItem>> airingTodayTv() async => const [];

  @override
  Future<List<ContentItem>> topRatedMovies() async => const [];

  @override
  Future<List<ContentItem>> popularMovies() async => const [];
}

ContentItem _item(String id, String title, {String type = 'Movie'}) {
  final remoteId = int.parse(id.split('-').last);
  final isTv = type == 'TV';
  return ContentItem(
    id: id,
    remoteId: remoteId,
    mediaType: isTv ? 'tv' : 'movie',
    title: title,
    subtitle: isTv ? 'Series' : 'Movie',
    year: 2026,
    genre: isTv ? 'Drama' : 'Adventure',
    type: isTv ? 'TV Show' : 'Movie',
    rating: 7.9,
    palette: const [Colors.black, Colors.red],
    glyph: isTv ? Icons.live_tv_rounded : Icons.movie_rounded,
    description: '$title description',
  );
}
