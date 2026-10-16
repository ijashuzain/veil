import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/view/native_player_view.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';
import 'package:veil/src/features/native_player/repository/episode_repository.dart';
import 'package:veil/src/features/native_player/utils/language_labels.dart';
import 'package:veil/src/features/native_player/view/player_controls.dart';
import 'package:veil/src/features/native_player/view/episode_panel.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;
import 'package:flutter/services.dart';

void main() {
  for (final rotateBeforeReady in [true, false]) {
    testWidgets('first-open rotation keeps video and controls aligned '
        '(rotate before ready: $rotateBeforeReady)', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 2340);
      addTearDown(tester.view.reset);
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      final resolver = _Resolver(pending: true);
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => resolver,
          ),
        ),
      );
      if (!rotateBeforeReady) {
        resolver.complete();
        await tester.pumpAndSettle();
      }
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.padding = const FakeViewPadding(left: 90, right: 30);
      await tester.pump();
      if (rotateBeforeReady) resolver.complete();
      await tester.pumpAndSettle();

      expect(platform.viewType, VideoViewType.textureView);
      final video = tester.getRect(find.byType(VideoPlayer));
      expect(video.width, closeTo(640, .01));
      expect(video.height, closeTo(360, .01));
      expect(video.center, const Offset(400, 180));
      final toolbar = tester.getRect(
        find.byKey(const ValueKey('native-player-toolbar')),
      );
      expect(toolbar.left, 46);
      expect(toolbar.right, 754);
      final fitButton = tester.getRect(
        find.byKey(const ValueKey('native-player-fit')),
      );
      expect(toolbar.contains(fitButton.center), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  testWidgets('mute restores previous volume and fits a narrow mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      MaterialApp(
        home: NativePlayerView(
          entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
          title: 'Movie',
          resolverFactory: () => _Resolver(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<VideoPlayer>(find.byType(VideoPlayer))
        .controller;
    await controller.setVolume(.35);
    await tester.pump();
    final mute = find.byKey(const ValueKey('native-player-mute'));
    await tester.tap(mute);
    await tester.pump();
    expect(platform.volume, 0);
    expect(tester.widget<PlayerAction>(mute).label, 'Unmute');
    await tester.tap(mute);
    await tester.pump();
    expect(platform.volume, .35);
    expect(tester.widget<PlayerAction>(mute).label, 'Mute');
    expect(find.byKey(const ValueKey('web-player-fullscreen')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('veil/player'),
          (call) async => call.method == 'getBrightness' ? 0.5 : null,
        );
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'language codes expand to full names and descriptive labels survive',
    () {
      expect(subtitleLanguageLabel('en', 'en'), 'English');
      expect(subtitleLanguageLabel('fr', 'fr'), 'French');
      expect(subtitleLanguageLabel('English (SDH)', 'en'), 'English (SDH)');
    },
  );
  const playlist = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000000\n720.m3u8';
  test('candidate must be real public HTTPS HLS, not blob or HTML', () {
    expect(
      isUsableHlsCandidate(
        Uri.parse('https://cinesrc.st/api/playlist/signed'),
        playlist,
      ),
      isTrue,
    );
    for (final url in [
      'blob:https://cinesrc.st/id',
      'file:///tmp/a.m3u8',
      'https://127.0.0.1/a.m3u8',
      'https://localhost/a.m3u8',
    ]) {
      expect(isUsableHlsCandidate(Uri.parse(url), playlist), isFalse);
    }
    expect(
      isUsableHlsCandidate(
        Uri.parse('https://cdn.test/movie.m3u8'),
        '<html>403</html>',
      ),
      isFalse,
    );
  });

  test('native handoff prefers an AVC 720 rendition over 4K HEVC', () {
    const master =
        '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=8000000,RESOLUTION=3840x2160,CODECS="hvc1.1.6"\n4k.m3u8\n#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1280x720,CODECS="avc1.64001f,mp4a.40.2"\n720.m3u8';
    expect(
      preferredNativeHlsUrl(
        Uri.parse('https://cdn.test/movie/master.m3u8'),
        master,
      ).toString(),
      'https://cdn.test/movie/720.m3u8',
    );
  });

  test(
    'metadata retains qualities and subtitle groups without detaching audio',
    () {
      final base = Uri.parse('https://cdn.test/master.m3u8');
      const master =
          '#EXTM3U\n#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",LANGUAGE="en",URI="en.vtt"\n#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1280x720,AUDIO="audio",SUBTITLES="subs"\n720.m3u8';
      expect(preferredNativeHlsUrl(base, master), base);
      expect(parseHlsSubtitles(base, master).single.language, 'en');
      expect(parseHlsQualities(base, master), isEmpty);
      expect(
        parseHlsQualities(
          base,
          master.replaceAll(',AUDIO="audio",SUBTITLES="subs"', ''),
        ).single.height,
        720,
      );
    },
  );

  testWidgets(
    'resolver is closed before native creation and session headers survive',
    (tester) async {
      final resolver = _Resolver();
      final platform = _VideoPlatform(
        onCreate: () => expect(resolver.disposed, isTrue),
      );
      VideoPlayerPlatform.instance = platform;
      final diagnostics = <Map<String, Object?>>[];
      NativePlayerView.debugOnDiagnostic = diagnostics.add;
      addTearDown(() => NativePlayerView.debugOnDiagnostic = null);
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => resolver,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        platform.source!.uri,
        'https://cdn.test/master.m3u8?token=short-lived',
      );
      expect(platform.source!.httpHeaders['Referer'], 'https://cinesrc.st/');
      expect(platform.source!.formatHint, VideoFormat.hls);
      expect(
        find.byKey(const ValueKey('native-player-play-pause')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('native-player-forward')));
      await tester.pump();
      expect(platform.position, const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      expect(platform.disposed, isTrue, reason: diagnostics.toString());
    },
  );

  testWidgets(
    'episode switch preserves selected native server and re-resolves new identity',
    (tester) async {
      VideoPlayerPlatform.instance = _VideoPlatform();
      const item = ContentItem(
        id: 'tv-94605',
        remoteId: 94605,
        title: 'Arcane',
        subtitle: '',
        year: 2024,
        genre: 'Animation',
        type: 'TV Show',
        rating: 8,
        palette: [Colors.black],
        glyph: Icons.tv,
        description: '',
      );
      final next = _Resolver(pending: true);
      var calls = 0;
      PlaybackRequest? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/tv/94605?s=2&e=3'),
            title: 'Arcane',
            request: const PlaybackRequest(
              item: item,
              server: PlaybackServer.six,
              season: 2,
              episode: 3,
            ),
            resolverFactory: () => calls++ == 0 ? _Resolver() : next,
            episodeRepository: _EpisodeCatalog(),
            onEpisodeChanged: (request) => changed = request,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('native-player-episodes')));
      await tester.pumpAndSettle();
      expect(find.textContaining('S02 - E03'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('native-season-dropdown')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('native-season-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('native-episode-2')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      expect(changed?.server, PlaybackServer.six);
      expect(changed?.season, 1);
      expect(changed?.episode, 2);
      expect(next.requested?.queryParameters, {'s': '1', 'e': '2'});
      await tester.pumpWidget(const SizedBox.shrink());
      next.complete();
      await tester.pump();
    },
  );

  testWidgets(
    'closing during resolution cancels resolver and never creates player',
    (tester) async {
      final resolver = _Resolver(pending: true);
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => resolver,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      resolver.complete();
      await tester.pump();
      expect(resolver.disposed, isTrue);
      expect(platform.source, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resolution failure offers retry and explicit embedded fallback',
    (tester) async {
      final resolver = _Resolver(failure: true);
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => resolver,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('native-player-retry')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('native-player-embedded-fallback')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'controls retain viewport width around pillarboxed video and aligned header',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      VideoPlayerPlatform.instance = _VideoPlatform();
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => _Resolver(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final video = tester.getRect(find.byType(VideoPlayer));
      final controls = tester.getRect(
        find.byKey(const ValueKey('native-player-toolbar')),
      );
      expect(controls.left, 16);
      expect(controls.right, 1184);
      expect(controls.width, greaterThan(video.width));
      final close = tester.getRect(
        find.byKey(const ValueKey('native-player-close')),
      );
      final title = tester.getRect(
        find.byKey(const ValueKey('native-player-title')),
      );
      expect(title.left - close.right, 10);
      expect(title.center.dy, close.center.dy);
      final action = tester.widget<PlayerAction>(
        find.byKey(const ValueKey('native-player-close')),
      );
      expect(action.color, Colors.white);
      final fitButton = find.byKey(const ValueKey('native-player-fit'));
      final fitSurface = find.byKey(const ValueKey('native-player-video-fit'));
      expect(tester.widget<FittedBox>(fitSurface).fit, BoxFit.contain);
      for (final fit in [BoxFit.cover, BoxFit.fill, BoxFit.contain]) {
        await tester.tap(fitButton);
        await tester.pump();
        expect(tester.widget<FittedBox>(fitSurface).fit, fit);
        expect(
          tester.getRect(find.byKey(const ValueKey('native-player-toolbar'))),
          controls,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'native resume seeks saved position and checkpoints on pause/close',
    (tester) async {
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      const item = ContentItem(
        id: 'movie-123',
        remoteId: 123,
        title: 'Movie',
        subtitle: '',
        year: 2026,
        genre: 'Drama',
        type: 'Movie',
        rating: 8,
        palette: [Colors.black],
        glyph: Icons.movie,
        description: '',
      );
      final saved = <PlaybackRequest>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            request: const PlaybackRequest(
              item: item,
              server: PlaybackServer.five,
              startPosition: Duration(seconds: 30),
            ),
            resolverFactory: () => _Resolver(),
            onProgress: saved.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.position, const Duration(seconds: 30));
      await tester.tap(find.byKey(const ValueKey('native-player-play-pause')));
      await tester.pump();
      expect(saved.last.startPosition, const Duration(seconds: 30));
      expect(saved.last.server, PlaybackServer.five);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('video and overlays respect left/right notch safe insets', (
    tester,
  ) async {
    VideoPlayerPlatform.instance = _VideoPlatform();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            padding: EdgeInsets.fromLTRB(44, 0, 28, 20),
          ),
          child: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => _Resolver(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(VideoPlayer));
    expect(rect.left, greaterThanOrEqualTo(44));
    expect(rect.right, lessThanOrEqualTo(772));
    expect(rect.bottom, lessThanOrEqualTo(580));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('episode without title has one numbered label and no thumbnail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 350,
            child: PlayerEpisodePanel(
              repository: _UnnamedCatalog(),
              seriesId: 1,
              season: 1,
              episode: 1,
              onSelect: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'track menu is inline with segmented tabs, not a Material dialog',
    (tester) async {
      VideoPlayerPlatform.instance = _VideoPlatform();
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => _Resolver(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('native-player-subtitles')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('English (1)'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const ValueKey('subtitle-language-English')));
      await tester.pumpAndSettle();
      expect(find.text('English · provider'), findsOneWidget);
      final back = find.byKey(const ValueKey('subtitle-language-back'));
      expect(tester.getSize(back), const Size(30, 30));
      final arrow = find.descendant(
        of: back,
        matching: find.byIcon(Icons.arrow_back),
      );
      expect(
        tester.getRect(arrow).left,
        tester.getRect(find.text('English · provider')).left,
      );
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('English (1)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('native-track-tab-1')));
      await tester.pump();
      expect(find.text('Auto'), findsOneWidget);
      expect(find.byType(PlayerSeekBar), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('subtitle scroll survives playback updates and tab changes', (
    tester,
  ) async {
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      MaterialApp(
        home: NativePlayerView(
          entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
          title: 'Movie',
          resolverFactory: () => _Resolver(subtitleCount: 40),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('native-player-subtitles')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subtitle-language-English')));
    await tester.pumpAndSettle();
    final list = find.byKey(const PageStorageKey('native-track-list-0'));
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    final controller = tester.widget<ListView>(list).controller!;
    final offset = controller.offset;
    expect(offset, greaterThan(0));
    platform.events.add(VideoEvent(eventType: VideoEventType.bufferingStart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.offset, offset);
    platform.events.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
    await tester.pumpAndSettle();
    expect(controller.offset, offset);
    await tester.tap(find.byKey(const ValueKey('native-track-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('native-track-tab-0')));
    await tester.pumpAndSettle();
    expect(tester.widget<ListView>(list).controller!.offset, offset);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'double tap seeks and vertical swipes adjust player volume and brightness',
    (tester) async {
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('veil/player'), (
            call,
          ) async {
            calls.add(call);
            return call.method == 'getBrightness' ? 0.5 : null;
          });
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => _Resolver(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(650, 230));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(const Offset(650, 230));
      await tester.pump();
      expect(platform.position, const Duration(seconds: 10));
      await tester.dragFrom(const Offset(650, 230), const Offset(0, 100));
      await tester.pump();
      expect(platform.volume, lessThan(1));
      await tester.dragFrom(const Offset(130, 230), const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls.any((call) => call.method == 'setBrightness'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(calls.any((call) => call.method == 'restoreBrightness'), isTrue);
    },
  );

  testWidgets(
    'controls hide, toggle on tap, and paused buffering stays hidden',
    (tester) async {
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      await tester.pumpWidget(
        MaterialApp(
          home: NativePlayerView(
            entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
            title: 'Movie',
            resolverFactory: () => _Resolver(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.byKey(const ValueKey('native-player-play-pause')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('native-player-tap-surface')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byKey(const ValueKey('native-player-play-pause')),
        findsOneWidget,
      );
      platform.events.add(VideoEvent(eventType: VideoEventType.bufferingStart));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('native-player-play-pause')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('native-playback-buffering')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.byKey(const ValueKey('native-player-play-pause')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    },
  );

  testWidgets('player offers sizing without native fullscreen option', (
    tester,
  ) async {
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(
      MaterialApp(
        home: NativePlayerView(
          entryUrl: Uri.parse('https://cinesrc.st/embed/movie/123'),
          title: 'Movie',
          resolverFactory: () => _Resolver(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('native-player-fullscreen')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('native-player-fit')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

class _Resolver implements StreamResolver {
  _Resolver({
    this.pending = false,
    this.failure = false,
    this.subtitleCount = 1,
  });
  final int subtitleCount;
  final bool pending;
  final bool failure;
  final completer = Completer<ResolvedStream>();
  bool disposed = false;
  Uri? requested;
  ResolvedStream get stream => ResolvedStream(
    url: Uri.parse('https://cdn.test/master.m3u8?token=short-lived'),
    format: NativeStreamFormat.hls,
    headers: {'Referer': 'https://cinesrc.st/'},
    resolvedAt: DateTime.now(),
    masterUrl: Uri.parse('https://cdn.test/master.m3u8'),
    subtitles: [
      for (var i = 0; i < subtitleCount; i++)
        StreamSubtitle(
          url: Uri.parse('https://subs.test/en-$i.vtt'),
          label: 'en',
          language: 'en',
        ),
    ],
  );
  void complete() => completer.complete(stream);
  @override
  Future<ResolvedStream> resolve(Uri url) async {
    requested = url;
    if (failure) throw const StreamResolutionException('Unavailable stream.');
    return pending ? completer.future : stream;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _EpisodeCatalog extends EpisodeRepository {
  @override
  Future<List<PlayerSeason>> seasons(int id) async => [
    const PlayerSeason(1, 3),
    const PlayerSeason(2, 4),
  ];
  @override
  Future<List<PlayerEpisode>> episodes(int id, int season) async =>
      List.generate(
        season == 1 ? 3 : 4,
        (i) => PlayerEpisode(
          season: season,
          number: i + 1,
          name: 'Episode name ${i + 1}',
        ),
      );
}

class _UnnamedCatalog extends EpisodeRepository {
  @override
  Future<List<PlayerSeason>> seasons(int id) async => [
    const PlayerSeason(1, 1),
  ];
  @override
  Future<List<PlayerEpisode>> episodes(int id, int season) async => [
    const PlayerEpisode(
      season: 1,
      number: 1,
      thumbnail: 'https://image.test/thumbnail.jpg',
    ),
  ];
}

class _VideoPlatform extends VideoPlayerPlatform {
  _VideoPlatform({this.onCreate});
  final VoidCallback? onCreate;
  final events = StreamController<VideoEvent>.broadcast();
  DataSource? source;
  VideoViewType? viewType;
  Duration position = Duration.zero;
  bool disposed = false;
  double volume = 1;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    onCreate?.call();
    source = options.dataSource;
    viewType = options.viewType;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int id) {
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(minutes: 90),
          size: const Size(1280, 720),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> dispose(int id) async {
    disposed = true;
    await events.close();
  }

  @override
  Future<void> setLooping(int id, bool value) async {}
  @override
  Future<void> setVolume(int id, double value) async {
    volume = value;
  }

  @override
  Future<void> setPlaybackSpeed(int id, double value) async {}
  @override
  Future<void> play(int id) async {}
  @override
  Future<void> pause(int id) async {}
  @override
  Future<void> seekTo(int id, Duration value) async {
    position = value;
  }

  @override
  Future<Duration> getPosition(int id) async => position;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}
