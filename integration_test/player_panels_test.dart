import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/view/native_player_view.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

/// UI-only fixture uses Flutter's public sample video; episode catalog is real.
/// Start tool/playback_live_bridge.mjs to retain simulator screenshots.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('custom panels with real TMDB catalog', (tester) async {
    const item = ContentItem(
      id: 'tv-125988',
      remoteId: 125988,
      title: 'Silo',
      subtitle: '',
      year: 2023,
      genre: 'Drama',
      type: 'TV Show',
      rating: 8,
      palette: [Colors.black],
      glyph: Icons.tv,
      description: 'UI fixture',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: VeilTheme.dark(),
        home: NativePlayerView(
          entryUrl: Uri.parse('https://cinesrc.st/embed/tv/125988?s=1&e=2'),
          title: 'Silo',
          request: const PlaybackRequest(
            item: item,
            server: PlaybackServer.five,
            season: 1,
            episode: 2,
          ),
          resolverFactory: () => _FixtureResolver(),
        ),
      ),
    );
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 30) &&
        (find.byType(VideoPlayer).evaluate().isEmpty ||
            !tester
                .widget<VideoPlayer>(find.byType(VideoPlayer))
                .controller
                .value
                .isInitialized)) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(VideoPlayer), findsOneWidget);
    if (find
        .byKey(const ValueKey('native-player-play-pause'))
        .evaluate()
        .isEmpty) {
      await tester.tap(find.byKey(const ValueKey('native-player-tap-surface')));
      await tester.pump(const Duration(milliseconds: 350));
    }
    await tester.tap(find.byKey(const ValueKey('native-player-play-pause')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('native-player-subtitles')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('French'), findsOneWidget);
    await _capture('tracks');
    await tester.tapAt(const Offset(120, 180));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('native-player-episodes')));
    await tester.pump(const Duration(milliseconds: 500));
    final load = Stopwatch()..start();
    while (find.text('Freedom Day').evaluate().isEmpty &&
        load.elapsed < const Duration(seconds: 20)) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Freedom Day'), findsOneWidget);
    expect(find.textContaining('S01 - E02'), findsOneWidget);
    await _capture('episodes');
    await tester.tap(find.byKey(const ValueKey('native-season-dropdown')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('native-season-2')), findsOneWidget);
    await _capture('seasons');
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _capture(String name) async {
  await http.post(
    Uri.parse('http://127.0.0.1:18765/result'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'run': 'player-ui',
      'case': name,
      'server': 5,
      'fixture': 'public sample video, real Silo metadata',
    }),
  );
}

class _FixtureResolver implements StreamResolver {
  @override
  Future<ResolvedStream> resolve(Uri uri) async => ResolvedStream(
    url: Uri.parse(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    ),
    format: NativeStreamFormat.mp4,
    headers: {},
    resolvedAt: DateTime.now(),
    subtitles: [
      StreamSubtitle(
        url: Uri.parse('https://example.test/en.vtt'),
        label: 'en',
        language: 'en',
      ),
      StreamSubtitle(
        url: Uri.parse('https://example.test/fr.vtt'),
        label: 'fr',
        language: 'fr',
      ),
    ],
  );
  @override
  Future<void> dispose() async {}
}
