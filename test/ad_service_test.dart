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

  testWidgets('ad controller retries until consent resolves', (tester) async {
    final service = _FakeAdService(
      initializeResults: const [
        AdState.disabled,
        AdState(canRequestAds: true, privacyOptionsRequired: false),
      ],
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(adControllerProvider.notifier).initialize();

    expect(container.read(adControllerProvider), AdState.disabled);
    expect(service.initializeCalls, 1);

    await tester.pump(AdController.retryDelays.first);

    expect(service.initializeCalls, 2);
    expect(
      container.read(adControllerProvider),
      const AdState(canRequestAds: true, privacyOptionsRequired: false),
    );

    // Consent resolved, so no further retries are scheduled.
    await tester.pump(AdController.retryDelays.last);
    expect(service.initializeCalls, 2);
  });

  testWidgets('ad controller stops retrying after the backoff is exhausted', (
    tester,
  ) async {
    final service = _FakeAdService();
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(adControllerProvider.notifier).initialize();

    for (final delay in AdController.retryDelays) {
      await tester.pump(delay);
    }

    expect(service.initializeCalls, AdController.retryDelays.length + 1);

    await tester.pump(const Duration(minutes: 5));
    expect(service.initializeCalls, AdController.retryDelays.length + 1);
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
    this.initializeResults = const [],
  });

  final AdState initializeResult;
  final AdState privacyResult;
  final Object? initializeError;
  final List<AdState> initializeResults;
  var initializeCalls = 0;
  var privacyCalls = 0;

  @override
  Future<AdState> initialize() async {
    initializeCalls += 1;
    if (initializeError case final error?) throw error;
    if (initializeResults.isEmpty) return initializeResult;

    final index = initializeCalls - 1;
    return index < initializeResults.length
        ? initializeResults[index]
        : initializeResults.last;
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
