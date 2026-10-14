import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/auth/view_model/premium_view_model/premium_view_model.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/detail/view/detail_view.dart';
import 'package:veil/src/features/detail/view_model/detail_view_model/detail_view_model.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';
import 'package:veil/src/features/playback_history/history_playback_launcher.dart';

void main() {
  testWidgets(
    'closing Continue Watching playback reveals detail, then back reveals home',
    (tester) async {
      const request = PlaybackRequest(
        item: _movie,
        server: PlaybackServer.five,
        startPosition: Duration(minutes: 5),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailViewModelProvider(_movie).overrideWithValue(
              DetailViewState(detail: ContentDetail.fallback(_movie)),
            ),
            currentUserIsPremiumProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => launchHistoryPlayback(
                    context,
                    request,
                    playerLauncher: (context, received) async {
                      expect(
                        received.startPosition,
                        const Duration(minutes: 5),
                      );
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (playerContext) => Scaffold(
                            body: TextButton(
                              onPressed: () => Navigator.pop(playerContext),
                              child: const Text('Close test playback'),
                            ),
                          ),
                        ),
                      );
                      return true;
                    },
                  ),
                  child: const Text('Resume history'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Resume history'));
      await tester.pumpAndSettle();
      expect(find.text('Close test playback'), findsOneWidget);
      await tester.tap(find.text('Close test playback'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailView), findsOneWidget);
      expect(find.text('Resume history'), findsNothing);
      Navigator.of(tester.element(find.byType(DetailView))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Resume history'), findsOneWidget);
    },
  );
  testWidgets('fifth button launches an independent native movie request', (
    tester,
  ) async {
    PlaybackRequest? launched;
    await _show(tester, _movie, (request) => launched = request);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 6; i++) {
      expect(
        find.byKey(ValueKey('playback-server-$i')),
        i <= 4 ? findsNothing : findsOneWidget,
      );
    }
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('playback-server-5')));
    await tester.tap(find.byKey(const ValueKey('playback-server-5')));
    await tester.pumpAndSettle();
    expect(launched?.server, PlaybackServer.five);
    expect(launched?.item.remoteId, 157336);
  });

  testWidgets('sixth button launches its own native provider request', (
    tester,
  ) async {
    PlaybackRequest? launched;
    await _show(tester, _movie, (request) => launched = request);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('playback-server-6')));
    await tester.tap(find.byKey(const ValueKey('playback-server-6')));
    await tester.pumpAndSettle();
    expect(launched?.server, PlaybackServer.six);
  });

  testWidgets('server five selects requested series season and episode', (
    tester,
  ) async {
    PlaybackRequest? launched;
    final tv = _movie.copyWith(
      id: 'tv-94605',
      remoteId: 94605,
      type: 'TV Show',
      mediaType: 'tv',
    );
    await _show(tester, tv, (request) => launched = request);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('playback-server-5')));
    await tester.tap(find.byKey(const ValueKey('playback-server-5')));
    await tester.pumpAndSettle();
    expect(launched, isNull);
    await tester.tap(find.byKey(const ValueKey('playback-season-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('playback-season-episode-play')),
    );
    await tester.pumpAndSettle();
    expect(launched?.server, PlaybackServer.five);
    expect(launched?.season, 2);
    expect(launched?.episode, 3);
  });
}

Future<void> _show(
  WidgetTester tester,
  ContentItem item,
  void Function(PlaybackRequest) launch,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        detailViewModelProvider(item).overrideWithValue(
          DetailViewState(detail: ContentDetail.fallback(item)),
        ),
        currentUserIsPremiumProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp(
        home: DetailView(
          item: item,
          playbackLauncher: (_, request) async {
            launch(request);
            return false;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _movie = ContentItem(
  id: 'movie-157336',
  title: 'Interstellar',
  subtitle: '',
  year: 2014,
  genre: 'Drama',
  type: 'Movie',
  mediaType: 'movie',
  rating: 8,
  palette: [Colors.black],
  glyph: Icons.movie,
  description: 'Movie fixture',
  remoteId: 157336,
);
