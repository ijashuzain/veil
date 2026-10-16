import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil/src/core/app_access/app_access_config.dart';
import 'package:veil/src/core/app_access/app_access_gate.dart';
import 'package:veil/src/core/app_access/app_access_repository.dart';

const update = AppAccessConfig(
  androidMinBuild: 13,
  iosMinBuild: 20,
  androidStoreUrl:
      'https://play.google.com/store/apps/details?id=com.vexellab.veil',
  iosStoreUrl: 'https://apps.apple.com/app/veil/id123456789',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('minimum build is platform-specific and inclusive', () {
    expect(
      update.status(platform: TargetPlatform.android, build: '12'),
      AppAccessStatus.updateRequired,
    );
    expect(
      update.status(platform: TargetPlatform.android, build: '13'),
      AppAccessStatus.allowed,
    );
    expect(
      update.status(platform: TargetPlatform.android, build: '100'),
      AppAccessStatus.allowed,
    );
    expect(
      update.status(platform: TargetPlatform.iOS, build: '13'),
      AppAccessStatus.updateRequired,
    );
    expect(
      update.status(platform: TargetPlatform.iOS, build: '20'),
      AppAccessStatus.allowed,
    );
    expect(
      update.status(platform: TargetPlatform.android, build: '1', web: true),
      AppAccessStatus.allowed,
    );
    expect(
      update.status(platform: TargetPlatform.macOS, build: '1'),
      AppAccessStatus.allowed,
    );
  });
  test('maintenance takes priority on all platforms', () {
    final config = AppAccessConfig.fromJson({
      ...update.toJson(),
      'maintenance_enabled': true,
    });
    expect(
      config.status(platform: TargetPlatform.android, build: '1'),
      AppAccessStatus.maintenance,
    );
    expect(
      config.status(platform: TargetPlatform.iOS, build: '100', web: true),
      AppAccessStatus.maintenance,
    );
  });
  test('invalid config, build or destination cannot strand users', () {
    expect(
      () => AppAccessConfig.fromJson({'maintenance_enabled': false}),
      throwsFormatException,
    );
    expect(
      update.status(platform: TargetPlatform.android, build: 'unknown'),
      AppAccessStatus.allowed,
    );
    const invalid = AppAccessConfig(
      androidMinBuild: 99,
      androidStoreUrl:
          'https://play.google.com.evil.test/store/apps/details?id=x',
    );
    expect(invalid.storeUrl(TargetPlatform.android), isNull);
    expect(
      invalid.status(platform: TargetPlatform.android, build: '12'),
      AppAccessStatus.allowed,
    );
  });
  test(
    'network failure uses recent persisted config after repository recreation',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.utc(2026, 10, 15);
      await AppAccessRepository(
        fetch: () async => update.toJson(),
        preferences: () async => prefs,
        now: () => now,
      ).load();
      final restored = await AppAccessRepository(
        fetch: () async => throw StateError('offline'),
        preferences: () async => prefs,
        now: () => now.add(const Duration(hours: 1)),
      ).load();
      expect(restored.androidMinBuild, 13);
    },
  );
  for (final age in [const Duration(hours: 6), const Duration(hours: -1)]) {
    test('stale or future cached policy is ignored: $age', () async {
      final now = DateTime.utc(2026, 10, 15);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppAccessRepository.cacheKey,
        jsonEncode({
          'savedAt': now.subtract(age).toIso8601String(),
          'config': update.toJson(),
        }),
      );
      final result = await AppAccessRepository(
        fetch: () async => throw StateError('offline'),
        preferences: () async => prefs,
        now: () => now,
      ).load();
      expect(result.androidMinBuild, 0);
    });
  }
  test('corrupt cache and offline first launch allow access', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppAccessRepository.cacheKey, 'invalid json');
    final result = await AppAccessRepository(
      fetch: () async => throw StateError('offline'),
      preferences: () async => prefs,
    ).load();
    expect(result.maintenance, isFalse);
    expect(result.androidMinBuild, 0);
  });
  test('fresh config replaces cached maintenance immediately', () async {
    final prefs = await SharedPreferences.getInstance();
    await AppAccessRepository(
      fetch: () async => const AppAccessConfig(maintenance: true).toJson(),
      preferences: () async => prefs,
    ).load();
    final result = await AppAccessRepository(
      fetch: () async => const AppAccessConfig().toJson(),
      preferences: () async => prefs,
    ).load();
    expect(result.maintenance, isFalse);
    final cached = await AppAccessRepository(
      fetch: () async => throw StateError('offline'),
      preferences: () async => prefs,
    ).load();
    expect(cached.maintenance, isFalse);
  });

  testWidgets('startup waits, maintenance blocks back, retry restores app', (
    tester,
  ) async {
    final pending = Completer<AppAccessConfig>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppAccessGate(
          readBuild: () async => '12',
          platform: TargetPlatform.android,
          load: () => ++calls == 1
              ? pending.future
              : Future.value(const AppAccessConfig()),
          child: const Scaffold(body: Text('App content')),
        ),
      ),
    );
    expect(find.text('App content'), findsNothing);
    expect(find.text('Checking app availability…'), findsOneWidget);
    pending.complete(
      const AppAccessConfig(maintenance: true, message: 'Back soon'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back soon'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('App content'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('App content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('update opens correct store and remains blocking on failure', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: AppAccessGate(
          readBuild: () async => '12',
          platform: TargetPlatform.iOS,
          load: () async => update,
          openStore: (url) async {
            opened = url;
            return false;
          },
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(opened?.host, 'apps.apple.com');
    expect(
      find.text('Could not open the store. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('App content'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'resume rechecks and removes current app when maintenance starts',
    (tester) async {
      var config = const AppAccessConfig();
      await tester.pumpWidget(
        MaterialApp(
          home: AppAccessGate(
            readBuild: () async => '12',
            load: () async => config,
            child: const Text('App content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('App content'), findsOneWidget);
      config = const AppAccessConfig(maintenance: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Under maintenance'), findsOneWidget);
      expect(find.text('App content'), findsNothing);
      config = const AppAccessConfig();
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('App content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
