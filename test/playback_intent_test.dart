import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/native_player/utils/playback_intent.dart';

void main() {
  test(
    'rapid skips accumulate; latest pause wins over in-flight seek',
    () async {
      final gate = Completer<void>();
      final seeks = <Duration>[];
      final actions = <String>[];
      final intent = PlaybackIntent(
        play: () async {
          actions.add('play');
        },
        pause: () async {
          actions.add('pause');
        },
        seek: (target) async {
          seeks.add(target);
          if (seeks.length == 1) await gate.future;
        },
        position: () => Duration.zero,
        duration: () => const Duration(minutes: 2),
        onChanged: () {},
        onError: (error) => fail('$error'),
      );
      intent.skip(const Duration(seconds: 10));
      intent.skip(const Duration(seconds: 10));
      intent.skip(const Duration(seconds: 10));
      intent.setPlaying(false);
      expect(intent.displayedPosition, const Duration(seconds: 30));
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(seeks, [const Duration(seconds: 10), const Duration(seconds: 30)]);
      expect(actions, isNot(contains('play')));
      expect(intent.wantsPlay, isFalse);
      intent.dispose();
    },
  );

  test('disposed seek completion cannot restart playback', () async {
    final gate = Completer<void>();
    var plays = 0;
    final intent = PlaybackIntent(
      play: () async {
        plays++;
      },
      pause: () async {},
      seek: (_) => gate.future,
      position: () => Duration.zero,
      duration: () => const Duration(minutes: 1),
      onChanged: () {},
      onError: (_) {},
    );
    intent.seekTo(const Duration(seconds: 20));
    intent.dispose();
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(plays, 0);
  });
}
