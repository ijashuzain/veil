import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil/src/core/config/app_environment.dart';

/// Device-wide cap, shared by both native playback providers.
class PlaybackAdCooldown {
  PlaybackAdCooldown(this.preferences, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  static const key = 'playback_interstitial_last_shown_ms';
  static const interval = Duration(minutes: 30);
  final SharedPreferences preferences;
  final DateTime Function() now;
  DateTime? _lastShown;

  bool get eligible {
    final stored = preferences.getInt(key);
    final last =
        _lastShown ??
        (stored == null ? null : DateTime.fromMillisecondsSinceEpoch(stored));
    return last == null || now().difference(last) >= interval;
  }

  Future<void> markShown() async {
    _lastShown = now();
    await preferences.setInt(key, _lastShown!.millisecondsSinceEpoch);
  }
}

class PlaybackInterstitial {
  InterstitialAd? _ad;
  DateTime? _loadedAt;
  DateTime? _lastAttempt;
  PlaybackAdCooldown? _cooldown;
  bool _enabled = false;
  bool _loading = false;
  bool _disposed = false;

  static String unitId(TargetPlatform platform, {bool test = !kReleaseMode}) =>
      switch (platform) {
        TargetPlatform.android =>
          test
              ? 'ca-app-pub-3940256099942544/1033173712'
              : AppEnvironment.admobAndroidInterstitialAdUnitId,
        TargetPlatform.iOS =>
          test
              ? 'ca-app-pub-3940256099942544/4411468910'
              : AppEnvironment.admobIosInterstitialAdUnitId,
        _ => '',
      };

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled) {
      unawaited(preload());
    } else {
      unawaited(_ad?.dispose());
      _ad = null;
    }
  }

  Future<void> preload() async {
    if (_disposed || !_enabled || kIsWeb || _loading || _ad != null) return;
    final id = unitId(defaultTargetPlatform);
    if (id.isEmpty) return;
    final now = DateTime.now();
    if (_lastAttempt != null &&
        now.difference(_lastAttempt!) < const Duration(seconds: 60)) {
      return;
    }
    _loading = true;
    _lastAttempt = now;
    try {
      _cooldown ??= PlaybackAdCooldown(await SharedPreferences.getInstance());
      if (_disposed || !_enabled) return;
      await InterstitialAd.load(
        adUnitId: id,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed || !_enabled) {
              unawaited(ad.dispose());
              return;
            }
            _ad = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            debugPrint('[Ads] Interstitial failed to load: code=${error.code}');
          },
        ),
      );
    } catch (error) {
      _loading = false;
      debugPrint('[Ads] Interstitial preload failed: ${error.runtimeType}');
    } finally {
      if (_disposed || !_enabled) _loading = false;
    }
  }

  /// Never wait for an ad to load. Only a ready ad may delay playback.
  Future<void> showIfEligible() async {
    if (_disposed || !_enabled || kIsWeb) return;
    final ad = _ad;
    if (ad == null) {
      unawaited(preload());
      return;
    }
    if (DateTime.now().difference(_loadedAt!) >= const Duration(hours: 1)) {
      _ad = null;
      unawaited(ad.dispose());
      unawaited(preload());
      return;
    }
    if (!(_cooldown?.eligible ?? false)) return;
    _ad = null;
    final dismissed = Completer<void>();
    void finish() {
      unawaited(ad.dispose());
      if (!dismissed.isCompleted) dismissed.complete();
      unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        unawaited(
          _cooldown!.markShown().catchError((Object error) {
            debugPrint(
              '[Ads] Cannot persist interstitial cap: ${error.runtimeType}',
            );
          }),
        );
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    await dismissed.future;
  }

  void dispose() {
    _disposed = true;
    unawaited(_ad?.dispose());
    _ad = null;
  }
}
