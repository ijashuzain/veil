import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/view/player_mobile.dart';

import 'support/fake_playback_platform.dart';

void main() {
  late FakePlaybackPlatform platform;
  const url = 'https://vidlink.pro/movie/123';

  setUp(() {
    platform = FakePlaybackPlatform();
    InAppWebViewPlatform.instance = platform;
  });

  Future<void> showPlayer(
    WidgetTester tester, {
    List<Uri> fallbacks = const [],
  }) => tester.pumpWidget(
    MaterialApp(
      home: FullscreenLandscapeWebPlayer(
        url: url,
        loadAsPage: true,
        showCloseButton: false,
        fallbackUrls: fallbacks,
      ),
    ),
  );

  testWidgets('Android blocks ad requests without probing stream MIME types', (
    tester,
  ) async {
    await showPlayer(tester);
    final settings = platform.params.initialSettings!;
    expect(settings.useHybridComposition, isTrue);
    expect(settings.hardwareAcceleration, isTrue);
    expect(settings.mediaPlaybackRequiresUserGesture, isFalse);
    expect(settings.useShouldInterceptRequest, isTrue);
    expect(settings.contentBlockers, isEmpty);
    final blocked = await platform.intercept(
      'https://ads.doubleclick.net/ad.js',
    );
    expect(blocked?.statusCode, 403);
    expect(
      await platform.intercept('https://cdn.test/player/stream.m3u8'),
      isNull,
    );
    expect(await platform.intercept('https://cdn.test/segment.ts'), isNull);
    expect(platform.controller.requestLoads, [Uri.parse(url)]);
    final subframeRule = RegExp(
      settings.regexToCancelSubFramesLoading!.replaceFirst('(?i)', ''),
      caseSensitive: false,
    );
    expect(subframeRule.hasMatch('intent://ad#Intent;end'), isTrue);
    expect(subframeRule.hasMatch('https://doubleclick.net/ad'), isTrue);
    expect(subframeRule.hasMatch('https://cdn.test/player'), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Apple content rules and all-frame guards exist before loading', (
    tester,
  ) async {
    await showPlayer(tester);
    expect(platform.params.initialSettings!.contentBlockers, isNotEmpty);
    expect(platform.params.initialSettings!.allowsInlineMediaPlayback, isTrue);
    final script = platform.params.initialUserScripts!.single;
    expect(script.injectionTime, UserScriptInjectionTime.AT_DOCUMENT_START);
    expect(script.forMainFrameOnly, isFalse);
    expect(await platform.popup('https://ad.test/'), isFalse);
    expect(await platform.popup('https://vidlink.pro/'), isFalse);
    expect(
      await platform.navigate('market://details?id=ad', isMainFrame: false),
      NavigationActionPolicy.CANCEL,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('loading cannot obscure video or intercept player touches', (
    tester,
  ) async {
    await showPlayer(tester);
    final indicator = find.byType(CircularProgressIndicator);
    expect(tester.getSize(indicator), const Size(24, 24));
    expect(
      find.ancestor(
        of: indicator,
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
    platform.mediaReady();
    await tester.pump();
    expect(indicator, findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
    expect(platform.controller.requestLoads, hasLength(1));
  });

  testWidgets(
    'loaded page without ready media offers retry instead of hanging',
    (tester) async {
      await showPlayer(tester);
      platform.pageFinished(url);
      await tester.pump(const Duration(seconds: 25));
      expect(find.byKey(const ValueKey('embed-player-retry')), findsOneWidget);
      platform.mediaReady();
      await tester.pump();
      expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
    },
  );

  testWidgets('relevant HTTP failures advance fallback; ad failures do not', (
    tester,
  ) async {
    final fallback = Uri.parse('https://vsembed.ru/embed/movie/123');
    await showPlayer(tester, fallbacks: [fallback]);
    platform.httpError(Uri.parse('https://ads.doubleclick.net/ad.js'));
    await tester.pump();
    expect(platform.controller.requestLoads, hasLength(1));
    final oldParams = platform.params;
    platform.httpError(Uri.parse(url), statusCode: 503);
    await tester.pump();
    expect(platform.controller.requestLoads, [Uri.parse(url), fallback]);
    // Old WebView completion must not clear the fallback's loading state.
    oldParams.onLoadStop?.call(
      InAppWebViewController.fromPlatform(platform: platform.controller),
      WebUri(url),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('closing player cancels watchdog and ignores late media events', (
    tester,
  ) async {
    await showPlayer(tester);
    final callback = platform.controller.handlers['veilMediaReady']!;
    await tester.pumpWidget(const SizedBox.shrink());
    callback([]);
    platform.pageFinished(url);
    await tester.pump(const Duration(seconds: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderer termination after playback offers a fresh WebView', (
    tester,
  ) async {
    await showPlayer(tester);
    platform.mediaReady();
    await tester.pump();
    platform.params.onWebContentProcessDidTerminate?.call(
      InAppWebViewController.fromPlatform(platform: platform.controller),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('embed-player-retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('embed-player-retry')));
    await tester.pump();
    expect(platform.controller.requestLoads, [Uri.parse(url), Uri.parse(url)]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('provider Play gate does not trigger a false buffering timeout', (
    tester,
  ) async {
    await showPlayer(tester);
    platform.awaitingPlay();
    await tester.pump(const Duration(seconds: 60));
    expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
    platform.playRequested();
    await tester.pump(const Duration(seconds: 25));
    expect(find.byKey(const ValueKey('embed-player-retry')), findsOneWidget);
    platform.mediaReady();
    await tester.pump();
    expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
  });

  testWidgets(
    'media failure is shown immediately and later recovery clears it',
    (tester) async {
      await showPlayer(tester);
      platform.mediaError(4);
      await tester.pump();
      expect(
        find.textContaining('This server could not play this video'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('embed-player-retry')), findsOneWidget);
      platform.mediaReady();
      await tester.pump();
      expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
    },
  );

  testWidgets('aborted/invalid media events do not interrupt playback', (
    tester,
  ) async {
    await showPlayer(tester);
    platform.mediaReady();
    platform.mediaError(1);
    platform.mediaError(99);
    await tester.pump();
    expect(find.byKey(const ValueKey('embed-player-retry')), findsNothing);
  });

  testWidgets(
    'top-level blank abort is rejected even after media became ready',
    (tester) async {
      await showPlayer(tester);
      platform.mediaReady();
      await tester.pump();
      expect(
        await platform.navigate('about:blank'),
        NavigationActionPolicy.CANCEL,
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('embed-player-retry')), findsOneWidget);
    },
  );
}
