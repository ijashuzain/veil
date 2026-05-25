import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player_web_script.dart';

void main() {
  test(
    'web direct player only prefers native HLS on Apple mobile browsers',
    () {
      final script = buildDirectWebPlayerBootstrapScript(
        url: 'https://example.test/stream.m3u8',
        videoId: 'video',
        statusId: 'status',
      );

      final appleMobileIndex = script.indexOf('const isAppleMobileBrowser');
      final appleNativeBranchIndex = script.indexOf(
        'if (isAppleMobileBrowser && nativeSupport)',
      );
      final hlsSupportIndex = script.indexOf('if (!window.Hls)');

      expect(appleMobileIndex, isNonNegative);
      expect(appleNativeBranchIndex, greaterThan(appleMobileIndex));
      expect(hlsSupportIndex, greaterThan(appleNativeBranchIndex));
      expect(script, contains('loadNative(video, status);'));
    },
  );
}
