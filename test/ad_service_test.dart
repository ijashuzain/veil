import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/src/core/providers/ad_providers.dart';

void main() {
  test('ad controller exposes initialized consent state', () async {
    final service = _FakeAdService(
      initializeResult: const AdState(
        canRequestAds: true,
        privacyOptionsRequired: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(adControllerProvider.notifier).initialize();

    expect(
      container.read(adControllerProvider),
      const AdState(canRequestAds: true, privacyOptionsRequired: true),
    );
    expect(service.initializeCalls, 1);

    await container.read(adControllerProvider.notifier).initialize();
    expect(service.initializeCalls, 1);
  });

  test('ad controller fails closed when initialization throws', () async {
    final container = ProviderContainer(
      overrides: [
        adServiceProvider.overrideWithValue(
          _FakeAdService(initializeError: StateError('consent failed')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(adControllerProvider.notifier).initialize();

    expect(container.read(adControllerProvider), AdState.disabled);
  });

  test('privacy choices refresh controller state', () async {
    final service = _FakeAdService(
      initializeResult: const AdState(
        canRequestAds: true,
        privacyOptionsRequired: true,
      ),
      privacyResult: const AdState(
        canRequestAds: false,
        privacyOptionsRequired: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await container.read(adControllerProvider.notifier).showPrivacyOptions();

    expect(
      container.read(adControllerProvider),
      const AdState(canRequestAds: false, privacyOptionsRequired: true),
    );
    expect(service.privacyCalls, 1);
  });

  test('ad unit IDs use Google test inventory outside release', () {
    expect(
      AdUnitIds.banner(TargetPlatform.android, useTestIds: true),
      'ca-app-pub-3940256099942544/6300978111',
    );
    expect(
      AdUnitIds.banner(TargetPlatform.iOS, useTestIds: true),
      'ca-app-pub-3940256099942544/2934735716',
    );
    expect(
      AdUnitIds.native(TargetPlatform.android, useTestIds: true),
      'ca-app-pub-3940256099942544/2247696110',
    );
    expect(
      AdUnitIds.native(TargetPlatform.iOS, useTestIds: true),
      'ca-app-pub-3940256099942544/3986624511',
    );
    expect(AdUnitIds.banner(TargetPlatform.macOS), isEmpty);
    expect(AdUnitIds.native(TargetPlatform.linux), isEmpty);
  });
}

class _FakeAdService implements AdService {
  _FakeAdService({
    this.initializeResult = AdState.disabled,
    this.privacyResult = AdState.disabled,
    this.initializeError,
  });

  final AdState initializeResult;
  final AdState privacyResult;
  final Object? initializeError;
  var initializeCalls = 0;
  var privacyCalls = 0;

  @override
  Future<AdState> initialize() async {
    initializeCalls += 1;
    if (initializeError case final error?) throw error;
    return initializeResult;
  }

  @override
  Future<LoadedAd?> loadAdaptiveBanner(double width) async => null;

  @override
  Future<LoadedAd?> loadNative() async => null;

  @override
  Future<AdState> showPrivacyOptions() async {
    privacyCalls += 1;
    return privacyResult;
  }
}
