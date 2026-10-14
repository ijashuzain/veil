import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil/app/services/ad_services/playback_interstitial.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'shared cap survives recreation and expires at exactly 30 minutes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime.utc(2026, 10, 14);
      final first = PlaybackAdCooldown(prefs, now: () => now);
      expect(first.eligible, isTrue);
      await first.markShown();
      final restarted = PlaybackAdCooldown(prefs, now: () => now);
      expect(restarted.eligible, isFalse);
      now = now.add(const Duration(minutes: 29, seconds: 59));
      expect(restarted.eligible, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(restarted.eligible, isTrue);
    },
  );

  test('clock rollback does not grant another impression', () async {
    var now = DateTime.utc(2026, 10, 14);
    final cap = PlaybackAdCooldown(
      await SharedPreferences.getInstance(),
      now: () => now,
    );
    await cap.markShown();
    now = now.subtract(const Duration(hours: 1));
    expect(cap.eligible, isFalse);
  });

  test('disabled ads do not delay playback or consume cooldown', () async {
    final ads = PlaybackInterstitial();
    await ads.showIfEligible();
    expect(
      (await SharedPreferences.getInstance()).getInt(PlaybackAdCooldown.key),
      isNull,
    );
    ads.dispose();
  });

  test('production units match supplied IDs and debug uses test ads', () {
    expect(
      PlaybackInterstitial.unitId(TargetPlatform.android, test: false),
      'ca-app-pub-9567183629579117/7093007985',
    );
    expect(
      PlaybackInterstitial.unitId(TargetPlatform.iOS, test: false),
      'ca-app-pub-9567183629579117/4878917348',
    );
    expect(
      PlaybackInterstitial.unitId(TargetPlatform.android),
      'ca-app-pub-3940256099942544/1033173712',
    );
    expect(
      PlaybackInterstitial.unitId(TargetPlatform.iOS),
      'ca-app-pub-3940256099942544/4411468910',
    );
  });
}
