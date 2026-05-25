import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web direct player avoids HtmlElementView compositing on mobile web',
    () {
      final source = File(
        'lib/src/features/embeded_player/view/direct_video_player_web.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('HtmlElementView')));
      expect(source, isNot(contains('ButtonElement')));
      expect(source, isNot(contains('maybePop')));
      expect(source, contains('document.body?.append'));
      expect(source, contains("position = 'fixed'"));
    },
  );
}
