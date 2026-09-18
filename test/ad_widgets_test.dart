import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/src/core/providers/ad_providers.dart';
import 'package:veil/src/shared/components/ads/adaptive_banner_ad.dart';
import 'package:veil/src/shared/components/ads/native_ad_list.dart';
import 'package:veil/src/shared/components/ads/native_ad_sliver_grid.dart';
import 'package:veil/src/shared/components/ads/native_template_ad.dart';

void main() {
  testWidgets('adaptive banner renders and disposes loaded ad', (tester) async {
    final service = _FakeAdService(
      bannerAd: _FakeLoadedAd(const Size(320, 50), 'banner-content'),
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SizedBox(width: 320, child: AdaptiveBannerAd()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('banner-content')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(service.bannerAd!.disposeCalls, 1);
  });

  testWidgets('native ad collapses when loading fails', (tester) async {
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(_FakeAdService())],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Column(
            children: [NativeTemplateAd(key: ValueKey('failed-native'))],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey('failed-native'))),
      Size.zero,
    );
  });

  testWidgets('native ad renders and disposes loaded ad', (tester) async {
    final service = _FakeAdService(
      nativeAd: _FakeLoadedAd(const Size(450, 380), 'native-content'),
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Column(children: [NativeTemplateAd()])),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('native-content')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(service.nativeAd!.disposeCalls, 1);
  });

  testWidgets('native ad retries after a no-fill and renders the later ad', (
    tester,
  ) async {
    final service = _FakeAdService(
      nativeAd: _FakeLoadedAd(const Size(450, 380), 'native-retry-content'),
      failuresBeforeFill: 1,
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Column(children: [NativeTemplateAd()])),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.nativeLoadCalls, 1);
    expect(find.byKey(const ValueKey('native-retry-content')), findsNothing);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(service.nativeLoadCalls, 2);
    expect(find.byKey(const ValueKey('native-retry-content')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('adaptive banner retries after a no-fill at the same width', (
    tester,
  ) async {
    final service = _FakeAdService(
      bannerAd: _FakeLoadedAd(const Size(320, 50), 'banner-retry-content'),
      failuresBeforeFill: 1,
    );
    final container = ProviderContainer(
      overrides: [adServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(adControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SizedBox(width: 320, child: AdaptiveBannerAd()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.bannerLoadCalls, 1);
    expect(find.byKey(const ValueKey('banner-retry-content')), findsNothing);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(service.bannerLoadCalls, 2);
    expect(find.byKey(const ValueKey('banner-retry-content')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('linear list inserts native ads after 12 and 24 items', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SingleChildScrollView(
            child: NativeAdList<int>(
              items: _items,
              keyPrefix: 'reviews',
              itemBuilder: _numberItem,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('reviews-native-after-12')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reviews-native-after-24')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reviews-native-after-36')), findsNothing);
    expect(find.byType(Text), findsNWidgets(25));
  });

  testWidgets('sliver grid preserves items and inserts full-width ad slivers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CustomScrollView(
            slivers: [
              NativeAdSliverGrid<int>(
                items: _items,
                keyPrefix: 'grid',
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemBuilder: _numberItem,
              ),
            ],
          ),
        ),
      ),
    );

    final finder = find.byType(NativeAdSliverGrid<int>);
    final grid = tester.widget<NativeAdSliverGrid<int>>(finder);
    final group = grid.build(tester.element(finder)) as SliverMainAxisGroup;
    expect(group.children, hasLength(5));
    expect(
      group.children.where(
        (sliver) =>
            sliver.key == const ValueKey('grid-native-after-12') ||
            sliver.key == const ValueKey('grid-native-after-24'),
      ),
      hasLength(2),
    );
    expect(grid.items, hasLength(25));
  });
}

const _items = <int>[
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
];

Widget _numberItem(BuildContext context, int item, int index) {
  return Text('$item');
}

class _FakeAdService implements AdService {
  _FakeAdService({this.bannerAd, this.nativeAd, this.failuresBeforeFill = 0});

  final _FakeLoadedAd? bannerAd;
  final _FakeLoadedAd? nativeAd;

  /// Number of leading requests that answer with a no-fill.
  final int failuresBeforeFill;
  var bannerLoadCalls = 0;
  var nativeLoadCalls = 0;

  @override
  Future<AdState> initialize() async {
    return const AdState(canRequestAds: true, privacyOptionsRequired: false);
  }

  @override
  Future<LoadedAd?> loadAdaptiveBanner(double width) async {
    bannerLoadCalls += 1;
    return bannerLoadCalls > failuresBeforeFill ? bannerAd : null;
  }

  @override
  Future<LoadedAd?> loadNative() async {
    nativeLoadCalls += 1;
    return nativeLoadCalls > failuresBeforeFill ? nativeAd : null;
  }

  @override
  Future<AdState> showPrivacyOptions() async => initialize();
}

class _FakeLoadedAd implements LoadedAd {
  _FakeLoadedAd(this.size, this.contentKey);

  @override
  final Size size;
  final String contentKey;
  var disposeCalls = 0;

  @override
  Widget buildWidget() => SizedBox(key: ValueKey(contentKey));

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}
