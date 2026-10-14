import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/home/widgets/continue_watching_section.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

void main() {
  testWidgets(
    'three compact cards fit phone width and duplicate/legacy rows stay hidden',
    (tester) async {
      tester.view.physicalSize = const Size(390, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entries = [
        _entry(1, PlaybackServer.five, 1),
        _entry(1, PlaybackServer.six, 2),
        _entry(2, PlaybackServer.six, 3),
        _entry(3, PlaybackServer.five, 4),
        _entry(4, PlaybackServer.one, 5),
      ];
      PlaybackHistoryEntry? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContinueWatchingSection(
              entries: entries,
              editing: false,
              onPlay: (entry) => opened = entry,
              onRemove: (_) {},
              onToggleEditing: () {},
            ),
          ),
        ),
      );
      expect(find.text('Movie 1'), findsOneWidget);
      expect(find.text('Movie 4'), findsNothing);
      for (final id in [1, 2, 3]) {
        final finder = find.byKey(ValueKey('continue-watching-card-movie:$id'));
        expect(finder, findsOneWidget);
        expect(tester.getRect(finder).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(finder).right, lessThanOrEqualTo(390));
        expect(tester.getSize(finder).width, lessThan(125));
      }
      await tester.tap(
        find.byKey(const ValueKey('continue-watching-card-movie:1')),
      );
      expect(opened?.server, PlaybackServer.six);
      expect(tester.takeException(), isNull);
    },
  );
}

PlaybackHistoryEntry _entry(int id, PlaybackServer server, int hour) =>
    PlaybackHistoryEntry.fromRequest(
      PlaybackRequest(
        item: ContentItem(
          id: 'movie-$id',
          remoteId: id,
          title: 'Movie $id',
          subtitle: '',
          year: 2026,
          genre: 'Drama',
          type: 'Movie',
          rating: 8,
          palette: const [Colors.black],
          glyph: Icons.movie,
          description: '',
        ),
        server: server,
      ),
      DateTime.utc(2026, 10, 14, hour),
    );
