import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide LocalStorage;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:veil/main.dart' as app;
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/features/embeded_player/utils/playback_launcher.dart';
import 'package:veil/src/features/embeded_player/utils/playback_target.dart';
import 'package:veil/src/features/embeded_player/view/mobile_playback_webview.dart';
import 'package:veil/src/features/embeded_player/view/player_mobile.dart';
import 'package:veil/src/features/native_player/view/native_player_view.dart';
import 'package:veil/src/features/native_player/view/player_controls.dart';
import 'package:veil/src/features/native_player/repository/vidzee_stream_resolver.dart';
import 'package:veil/src/features/native_player/repository/provider_stream_resolver.dart';
import 'package:video_player/video_player.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

import 'support/playback_probe_script.dart';

/// Opt-in network/device test. Credentials are supplied at runtime by a local
/// loopback bridge, never embedded in the test source or compiled app.
/// Run with `flutter test integration_test/playback_live_test.dart -d <simulator>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const bridge = String.fromEnvironment(
    'PLAYBACK_BRIDGE_URL',
    defaultValue: 'http://127.0.0.1:18765',
  );
  const runLabel = String.fromEnvironment(
    'PLAYBACK_RUN_LABEL',
    defaultValue: 'baseline',
  );
  const caseFilter = String.fromEnvironment('PLAYBACK_CASE_FILTER');
  const nativeProvider = String.fromEnvironment('PLAYBACK_NATIVE_PROVIDER');
  const checkControls = bool.fromEnvironment('PLAYBACK_CHECK_CONTROLS');
  const safariUa = bool.fromEnvironment('PLAYBACK_SAFARI_UA');
  const blockAntiDebug = bool.fromEnvironment('PLAYBACK_BLOCK_ANTI_DEBUG');
  const vidlinkPlayer = String.fromEnvironment('PLAYBACK_VIDLINK_PLAYER');
  const noContentBlockers = bool.fromEnvironment(
    'PLAYBACK_NO_CONTENT_BLOCKERS',
  );
  const serverFilter = String.fromEnvironment('PLAYBACK_SERVER_FILTER');
  const waitSeconds = int.fromEnvironment(
    'PLAYBACK_WAIT_SECONDS',
    defaultValue: 40,
  );

  testWidgets('live authenticated playback matrix', (tester) async {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    NativePlayerView.debugProbeSource = true;
    final credentialsResponse = await http.get(
      Uri.parse('$bridge/credentials'),
    );
    final credentials =
        jsonDecode(credentialsResponse.body) as Map<String, dynamic>;
    expect(
      credentialsResponse.statusCode,
      200,
      reason: 'Start tool/playback_live_bridge.mjs with test credentials',
    );
    await app.main();
    await tester.pump();
    final restoredUser = SupabaseService.client?.auth.currentUser;
    if (restoredUser != null && restoredUser.email != credentials['email']) {
      throw StateError(
        'Simulator is signed into a different account; use the requested test account.',
      );
    }
    if (SupabaseService.client?.auth.currentSession == null) {
      await _wait(
        tester,
        () => find.widgetWithText(TextField, 'Email').evaluate().isNotEmpty,
        const Duration(seconds: 30),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        credentials['email'] as String,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        credentials['password'] as String,
      );
      await tester.tap(find.text('Sign in').last);
      await _wait(
        tester,
        () => SupabaseService.client?.auth.currentSession != null,
        const Duration(seconds: 40),
      );
    }
    credentials.clear();
    final client = SupabaseService.client!;
    expect(client.auth.currentSession, isNotNull);
    final profile = await client
        .from('user_profiles')
        .select('is_premium')
        .eq('user_id', client.auth.currentUser!.id)
        .maybeSingle();
    debugPrint(
      '[PlaybackLive] authenticated premium=${profile?['is_premium']}',
    );
    await tester.pump(const Duration(seconds: 1));

    MobilePlaybackWebView.debugUserScripts = [
      UserScript(
        source: playbackProbeScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: false,
      ),
    ];
    MobilePlaybackWebView.debugConfigureSettings = (settings) {
      if (safariUa) {
        settings.userAgent =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7 Mobile/15E148 Safari/604.1';
      }
      if (noContentBlockers) settings.contentBlockers = [];
      if (blockAntiDebug) {
        settings.contentBlockers = [
          ...?settings.contentBlockers,
          ContentBlocker(
            trigger: ContentBlockerTrigger(
              urlFilter: r'^https?://[^/]+/(.*/)?disable-devtool(\.min)?\.js',
            ),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
        ];
      }
    };
    final casesResponse = await http.get(Uri.parse('$bridge/cases'));
    final cases = (jsonDecode(casesResponse.body) as List)
        .cast<Map<String, dynamic>>();
    for (final fixture in cases) {
      final caseId = fixture['key'] as String;
      if (caseFilter.isNotEmpty && !caseFilter.split(',').contains(caseId)) {
        continue;
      }
      final isTv = fixture['type'] == 'tv';
      final item = ContentItem(
        id: caseId,
        remoteId: fixture['id'] as int,
        title: fixture['title'] as String,
        type: isTv ? 'TV Show' : 'Movie',
        mediaType: isTv ? 'tv' : 'movie',
        subtitle: '',
        year: 2026,
        genre: '',
        rating: 0,
        palette: const [Colors.black],
        glyph: Icons.movie,
        description: '',
      );
      for (final server in PlaybackServer.values) {
        final serverNumber = server.index + 1;
        if (serverFilter.isNotEmpty &&
            !serverFilter.split(',').contains('$serverNumber')) {
          continue;
        }
        final events = <Map<String, dynamic>>[];
        final stopwatch = Stopwatch()..start();
        NativePlayerView.debugOnDiagnostic = (event) =>
            events.add(Map<String, dynamic>.from(event));
        MobilePlaybackWebView.debugOnDiagnostic = (event) {
          events.add({
            'elapsedMs': stopwatch.elapsedMilliseconds,
            ...event,
            if (event['url'] is String)
              'url': _safeUrl(event['url']! as String),
          });
        };
        InAppWebViewController? controller;
        MobilePlaybackWebView.debugOnWebViewCreated = (created) {
          controller = created;
          created.addJavaScriptHandler(
            handlerName: 'veilProbe',
            callback: (args) {
              if (args.isNotEmpty && args.first is Map) {
                events.add({
                  'elapsedMs': stopwatch.elapsedMilliseconds,
                  ...Map<String, dynamic>.from(args.first as Map),
                });
              }
              return null;
            },
          );
          created.addJavaScriptHandler(
            handlerName: 'veilProbeSource',
            callback: (args) async {
              if (args.length != 3) return null;
              try {
                final response = await http.post(
                  Uri.parse('$bridge/probe-stream'),
                  headers: {'content-type': 'application/json'},
                  body: jsonEncode({
                    'url': args[0],
                    'referer': args[1],
                    'ua': args[2],
                  }),
                );
                events.add({
                  'elapsedMs': stopwatch.elapsedMilliseconds,
                  'kind': 'streamProbe',
                  ...jsonDecode(response.body) as Map<String, dynamic>,
                });
              } catch (error) {
                events.add({
                  'kind': 'streamProbeFailure',
                  'error': error.runtimeType.toString(),
                });
              }
              return null;
            },
          );
        };
        debugPrint(
          '[PlaybackLive] start $runLabel/$caseId/server-$serverNumber',
        );
        final context = tester.element(find.byType(Scaffold).first);
        final request = PlaybackRequest(
          item: item,
          server: server,
          season: fixture['season'] as int? ?? 1,
          episode: fixture['episode'] as int? ?? 1,
        );
        if (server == PlaybackServer.five && nativeProvider.isNotEmpty) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              builder: (_) => NativePlayerView(
                entryUrl: playbackTargetFor(request)!.url,
                title: item.title,
                request: request,
                resolverFactory: () => nativeProvider == 'vidzee'
                    ? VidzeeStreamResolver()
                    : ProviderStreamResolver(
                        providers: [
                          NativeProvider.values.byName(nativeProvider),
                        ],
                      ),
              ),
            ),
          );
        } else if (server == PlaybackServer.four && vidlinkPlayer.isNotEmpty) {
          final target = playbackTargetFor(request)!;
          final query = Map<String, String>.from(target.url.queryParameters);
          if (vidlinkPlayer == 'default') {
            query.remove('player');
          } else {
            query['player'] = vidlinkPlayer;
          }
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              builder: (_) => FullscreenLandscapeWebPlayer(
                url: target.url.replace(queryParameters: query).toString(),
                loadAsPage: target.loadAsPage,
              ),
            ),
          );
        } else {
          await launchPlaybackRequest(context, request);
        }
        await tester.pump();
        var commandedPlay = false;
        await _wait(
          tester,
          () {
            final videos = events
                .where((event) => event['kind'] == 'video')
                .toList();
            return videos.any(
                  (event) =>
                      (event['time'] as num? ?? 0) >= 3 &&
                      event['paused'] == false &&
                      (event['duration'] as num? ?? 0) > 300 &&
                      (event['width'] as num? ?? 0) > 0,
                ) ||
                videos.any((event) => (event['errorCode'] as num? ?? 0) > 0) ||
                events.any(
                  (event) =>
                      event['kind'] == 'playerError' ||
                      event['kind'] == 'nativePlaying' ||
                      event['kind'] == 'nativeError' ||
                      event['kind'] == 'failure',
                );
          },
          Duration(seconds: waitSeconds),
          onTick: () async {
            if (!commandedPlay &&
                stopwatch.elapsedMilliseconds > 8000 &&
                controller != null) {
              commandedPlay = true;
              await controller!.evaluateJavascript(
                source: 'window.postMessage({veilProbeCommand:"play"},"*");',
              );
            }
          },
        );
        if (controller != null) {
          try {
            await controller!.evaluateJavascript(
              source: 'window.postMessage({veilProbeCommand:"snapshot"},"*");',
            );
            await tester.pump(const Duration(milliseconds: 300));
          } catch (_) {}
        }
        final playing = events
            .where(
              (event) =>
                  (event['kind'] == 'nativePlaying' ||
                  (event['kind'] == 'video' &&
                      (event['time'] as num? ?? 0) >= 3 &&
                      event['paused'] == false &&
                      (event['duration'] as num? ?? 0) > 300 &&
                      (event['width'] as num? ?? 0) > 0)),
            )
            .toList();
        if (playing.isEmpty &&
            events.any(
              (event) =>
                  event['kind'] == 'playerError' ||
                  (event['kind'] == 'video' &&
                      (event['errorCode'] as num? ?? 0) > 0),
            )) {
          await tester.pump(const Duration(seconds: 2));
        }
        bool? seekSucceeded;
        if (playing.isNotEmpty && controller != null) {
          await controller!.evaluateJavascript(
            source:
                'window.postMessage({veilProbeCommand:"seek",time:45},"*");',
          );
          seekSucceeded = await _wait(
            tester,
            () => events.any(
              (event) =>
                  event['kind'] == 'video' &&
                  (event['time'] as num? ?? 0) >= 46 &&
                  event['paused'] == false &&
                  (event['readyState'] as num? ?? 0) >= 2,
            ),
            const Duration(seconds: 12),
          );
        }
        if (playing.isNotEmpty &&
            find.byType(VideoPlayer).evaluate().isNotEmpty) {
          final native = tester
              .widget<VideoPlayer>(find.byType(VideoPlayer))
              .controller;
          if (find
              .byKey(const ValueKey('native-player-seek'))
              .evaluate()
              .isEmpty) {
            await tester.tap(
              find.byKey(const ValueKey('native-player-tap-surface')),
            );
            await tester.pump();
          }
          tester
              .widget<PlayerSeekBar>(
                find.byKey(const ValueKey('native-player-seek')),
              )
              .onChangeEnd(45000);
          seekSucceeded = await _wait(
            tester,
            () =>
                native.value.position >= const Duration(seconds: 46) &&
                native.value.isPlaying,
            const Duration(seconds: 15),
          );
          if (checkControls) {
            await tester.pump(const Duration(seconds: 4));
            expect(
              find.byKey(const ValueKey('native-player-play-pause')),
              findsNothing,
            );
            await tester.tap(
              find.byKey(const ValueKey('native-player-tap-surface')),
            );
            await tester.pump();
            await tester.tap(
              find.byKey(const ValueKey('native-player-play-pause')),
            );
            await tester.pump(const Duration(milliseconds: 500));
            expect(
              find.byKey(const ValueKey('native-playback-buffering')),
              findsNothing,
            );
            expect(native.value.isPlaying, isFalse);
            await tester.tap(
              find.byKey(const ValueKey('native-player-quality')),
            );
            await tester.pump(const Duration(milliseconds: 300));
            final qualityCount = find.byType(PlayerPanelRow).evaluate().length;
            await tester.tap(
              find.byWidgetPredicate(
                (w) => w is PlayerAction && w.label == 'Close track menu',
              ),
            );
            await tester.pump();
            await tester.tap(
              find.byKey(const ValueKey('native-player-subtitles')),
            );
            await _wait(
              tester,
              () => find.byType(PlayerPanelRow).evaluate().isNotEmpty,
              const Duration(seconds: 10),
            );
            final subtitleCount =
                find.byType(PlayerPanelRow).evaluate().length - 1;
            await tester.tap(
              find.byWidgetPredicate(
                (w) => w is PlayerAction && w.label == 'Close track menu',
              ),
            );
            await tester.pump();
            events.add({
              'kind': 'controlsVerified',
              'autoHide': true,
              'pausedSpinnerHidden': true,
              'qualityOptions': qualityCount,
              'subtitleOptions': subtitleCount,
            });
          }
        }
        final result = {
          'run': runLabel,
          'case': caseId,
          'title': item.title,
          'server': serverNumber,
          'durationMs': stopwatch.elapsedMilliseconds,
          'playing': playing.isNotEmpty,
          'firstPlayingMs': playing.isEmpty ? null : playing.first['elapsedMs'],
          'seekSucceeded': seekSucceeded,
          'retryVisible': find
              .byKey(const ValueKey('embed-player-retry'))
              .evaluate()
              .isNotEmpty,
          'events': events,
        };
        await http.post(
          Uri.parse('$bridge/result'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(result),
        );
        debugPrint(
          '[PlaybackLive] result $caseId/$serverNumber playing=${result['playing']} firstPlayingMs=${result['firstPlayingMs']} seek=$seekSucceeded events=${events.length}',
        );
        if (find.byType(FullscreenLandscapeWebPlayer).evaluate().isNotEmpty) {
          Navigator.of(
            tester.element(find.byType(FullscreenLandscapeWebPlayer)),
          ).pop();
        } else if (find.byType(NativePlayerView).evaluate().isNotEmpty) {
          if (find
              .byKey(const ValueKey('native-player-close'))
              .evaluate()
              .isEmpty) {
            await tester.tap(
              find.byKey(const ValueKey('native-player-tap-surface')),
            );
            await tester.pump();
          }
          await tester.tap(find.byKey(const ValueKey('native-player-close')));
          await _wait(
            tester,
            () => find.byType(NativePlayerView).evaluate().isEmpty,
            const Duration(seconds: 10),
          );
        }
        await tester.pump(const Duration(milliseconds: 500));
        MobilePlaybackWebView.debugOnWebViewCreated = null;
        NativePlayerView.debugOnDiagnostic = null;
      }
    }
    MobilePlaybackWebView.debugUserScripts = const [];
    MobilePlaybackWebView.debugOnDiagnostic = null;
    MobilePlaybackWebView.debugConfigureSettings = null;
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }, timeout: const Timeout(Duration(minutes: 30)));
}

String _safeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '<invalid>';
  if (uri.scheme == 'data') return 'data:${url.substring(5).split(',').first}';
  if (uri.host.isEmpty) return uri.scheme;
  return '${uri.scheme}://${uri.host}${uri.path}';
}

Future<bool> _wait(
  WidgetTester tester,
  bool Function() ready,
  Duration timeout, {
  Future<void> Function()? onTick,
}) async {
  final clock = Stopwatch()..start();
  while (!ready() && clock.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 500));
    if (onTick != null) await onTick();
  }
  return ready();
}
