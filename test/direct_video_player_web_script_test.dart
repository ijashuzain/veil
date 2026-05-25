import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player_web_script.dart';

void main() {
  test('web direct player prefers native HLS before hls.js', () {
    final script = buildDirectWebPlayerBootstrapScript(
      url: 'https://example.test/stream.m3u8',
      videoId: 'video',
      statusId: 'status',
    );

    final nativeSupportIndex = script.indexOf('const nativeSupport');
    final hlsSupportIndex = script.indexOf('if (!window.Hls)');

    expect(nativeSupportIndex, isNonNegative);
    expect(hlsSupportIndex, greaterThan(nativeSupportIndex));
    expect(script, contains('if (nativeSupport)'));
    expect(script, contains('loadNative(video, status);'));
  });
}
