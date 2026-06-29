import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/features/alerts/view/alerts_view.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/movie_suggestion.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  testWidgets('alerts view renders TMDB alerts and marks them read', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_AlertsTmdbRepository()),
        ],
        child: const MaterialApp(home: AlertsView(showBack: true)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('5 new'), findsOneWidget);
    expect(find.textContaining('Swapped'), findsWidgets);
    expect(find.textContaining('Dune: Part Two trailer'), findsNothing);

    await tester.tap(find.text('Mark read'));
    await tester.pump();

    expect(find.textContaining('0 new'), findsOneWidget);
  });

  testWidgets('alerts view renders follow alerts and suggestions tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_AlertsTmdbRepository()),
          socialRepositoryProvider.overrideWithValue(_AlertsSocialRepository()),
        ],
        child: const MaterialApp(home: AlertsView(showBack: true)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Mira sent you a follow request'), findsOneWidget);

    await tester.tap(find.text('Suggestions'));
    await tester.pump();

    expect(find.text('Ijas suggested Sinners for you'), findsOneWidget);
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
