import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player_script.dart';

void main() {
  test('direct player uses hls.js before native HLS fallback', () {
    final script = buildDirectPlayerBootstrapScript(
      url: 'https://example.test/stream.m3u8',
      videoId: 'video',
      statusId: 'status',
    );

    final hlsSupportIndex = script.indexOf('window.Hls.isSupported()');
    final nativeSupportIndex = script.indexOf('const nativeSupport');

    expect(hlsSupportIndex, isNonNegative);
    expect(nativeSupportIndex, greaterThan(hlsSupportIndex));
    expect(script, contains('lowLatencyMode: true'));
    expect(script, contains('hls.loadSource(sourceUrl);'));
    expect(script, contains('hls.attachMedia(video);'));
    expect(script, contains('loadNative(video, status);'));
  });
}
