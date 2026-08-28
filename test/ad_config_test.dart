import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/core/config/app_environment.dart';

void main() {
  test('AdMob production IDs are configured', () {
    expect(
      AppEnvironment.admobAndroidBannerAdUnitId,
      'ca-app-pub-9567183629579117/6978075494',
    );
    expect(
      AppEnvironment.admobIosBannerAdUnitId,
      'ca-app-pub-9567183629579117/1861480181',
    );
    expect(
      AppEnvironment.admobAndroidNativeAdUnitId,
      'ca-app-pub-9567183629579117/8848348916',
    );
    expect(
      AppEnvironment.admobIosNativeAdUnitId,
      'ca-app-pub-9567183629579117/9806207364',
    );
  });

  test('native AdMob app IDs are present', () {
    final android = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();

    expect(android, contains('ca-app-pub-9567183629579117~3553991339'));
    expect(ios, contains('ca-app-pub-9567183629579117~3532820354'));
  });

  test('Home native ad follows second discovery rail', () {
    final source = File(
      'lib/src/features/home/view/home_view.dart',
    ).readAsStringSync();
    final secondRail = source.indexOf("title: 'New this week'");
    final nativeAd = source.indexOf('home-native-after-second-rail');
    final curated = source.indexOf('CuratedCollectionSection()');

    expect(secondRail, greaterThan(-1));
    expect(nativeAd, greaterThan(secondRail));
    expect(curated, greaterThan(nativeAd));
  });
}
