import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player_script.dart';

void main() {
  test('native HLS starts without waiting for a CDN script', () {
    final result = _runPlayer(nativeSupport: true);
    expect(result['scripts'], isEmpty);
    expect(result['loads'], 1);
    expect(result['plays'], 1);
    expect(result['hlsCreated'], 0);
  });

  test('unsupported native HLS lazily loads pinned adaptive VOD player', () {
    final result = _runPlayer(nativeSupport: false);
    expect(result['scripts'], [directPlayerHlsScriptUrl]);
    expect(result['hlsCreated'], 1);
    expect(result['source'], 'https://example.test/stream.m3u8');
    expect(result['config']['lowLatencyMode'], isFalse);
    expect(result['config']['capLevelToPlayerSize'], isTrue);
    expect(result['config']['startLevel'], -1);
  });

  test('native decode error switches once to HLS.js', () {
    final result = _runPlayer(
      nativeSupport: true,
      actions: 'video.listeners.error(); await flush();',
    );
    expect(result['scripts'], [directPlayerHlsScriptUrl]);
    expect(result['hlsCreated'], 1);
  });

  test('fatal network recovery is bounded and surfaces useful failure', () {
    final result = _runPlayer(
      nativeSupport: false,
      actions: '''
        for (let i = 0; i < 3; i++) {
          hls.listeners.error(null, {fatal: true, type: 'network'});
        }
      ''',
    );
    expect(result['networkRecoveries'], 2);
    expect(result['destroyed'], 1);
    expect(result['status'], contains('Try another server'));
  });

  test(
    'fatal media recovery is bounded rather than endless native fallback',
    () {
      final result = _runPlayer(
        nativeSupport: false,
        actions: '''
        for (let i = 0; i < 2; i++) {
          hls.listeners.error(null, {fatal: true, type: 'media'});
        }
      ''',
      );
      expect(result['mediaRecoveries'], 1);
      expect(result['destroyed'], 1);
      expect(result['loads'], 0);
    },
  );

  test('disposed video does not attach after asynchronous library load', () {
    final result = _runPlayer(
      nativeSupport: false,
      disposeBeforeLibraryLoad: true,
    );
    expect(result['hlsCreated'], 0);
    expect(result['plays'], 0);
  });
}

/// Execute generated JavaScript: assertions cover engine selection and recovery,
/// not source-string order. Requires Node.js, also used by the screenshot tool.
Map<String, dynamic> _runPlayer({
  required bool nativeSupport,
  bool disposeBeforeLibraryLoad = false,
  String actions = '',
}) {
  final script = buildDirectPlayerBootstrapScript(
    url: 'https://example.test/stream.m3u8',
    videoId: 'video',
    statusId: 'status',
  );
  final result = Process.runSync('node', [
    '-e',
    '''
      (async function () {
        const result = {scripts: [], loads: 0, plays: 0, hlsCreated: 0,
          networkRecoveries: 0, mediaRecoveries: 0, destroyed: 0};
        const status = {textContent: '', style: {}};
        const video = {listeners: {},
          canPlayType: () => ${nativeSupport ? "'maybe'" : "''"},
          addEventListener: (name, callback) => video.listeners[name] = callback,
          load: () => result.loads++,
          play: () => { result.plays++; return Promise.resolve(); }};
        let hls;
        class Hls {
          static isSupported() { return true; }
          static Events = {MANIFEST_PARSED: 'parsed', ERROR: 'error'};
          static ErrorTypes = {NETWORK_ERROR: 'network', MEDIA_ERROR: 'media'};
          constructor(config) {
            result.hlsCreated++; result.config = config;
            this.listeners = {}; hls = this;
          }
          on(name, callback) { this.listeners[name] = callback; }
          loadSource(url) { result.source = url; }
          attachMedia() {}
          startLoad() { result.networkRecoveries++; }
          recoverMediaError() { result.mediaRecoveries++; }
          destroy() { result.destroyed++; }
        }
        global.window = {};
        global.document = {
          getElementById: id => id === 'video' ? video : status,
          createElement: () => ({remove() {}}),
          head: {appendChild(script) {
            result.scripts.push(script.src);
            ${disposeBeforeLibraryLoad ? 'video.__veilDisposed = true;' : ''}
            window.Hls = Hls;
            script.onload();
          }}
        };
        global.setTimeout = () => 1;
        global.clearTimeout = () => {};
        const flush = () => new Promise(resolve => setImmediate(resolve));
        (new Function(${jsonEncode(script)}))();
        await flush();
        $actions
        result.status = status.textContent;
        process.stdout.write(JSON.stringify(result));
      })().catch(error => { console.error(error); process.exitCode = 1; });
    ''',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return jsonDecode(result.stdout as String) as Map<String, dynamic>;
}
