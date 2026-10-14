import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/app/services/ad_services/playback_interstitial.dart';

final playbackInterstitialProvider = Provider<PlaybackInterstitial>((ref) {
  final service = PlaybackInterstitial();
  ref.onDispose(service.dispose);
  return service;
});

final adServiceProvider = Provider<AdService>((ref) => GoogleAdService());

final adControllerProvider = NotifierProvider<AdController, AdState>(
  AdController.new,
);

class AdController extends Notifier<AdState> {
  /// Consent resolution is attempted from the first frame, which on a cold
  /// start often lands before the network is usable. Back off and retry rather
  /// than leaving ads disabled for the whole session.
  static const retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(seconds: 60),
  ];

  var _initializing = false;
  var _retriesUsed = 0;
  Timer? _retryTimer;

  @override
  AdState build() {
    ref.onDispose(_cancelRetry);
    return AdState.disabled;
  }

  Future<void> initialize() async {
    if (_initializing || state.canRequestAds) return;
    _initializing = true;
    _cancelRetry();

    try {
      state = await ref.read(adServiceProvider).initialize();
    } catch (error, stackTrace) {
      debugPrint('[Ads] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AdState.disabled;
    } finally {
      _initializing = false;
    }

    if (!state.canRequestAds) _scheduleRetry();
    ref.read(playbackInterstitialProvider).setEnabled(state.canRequestAds);
  }

  Future<void> showPrivacyOptions() async {
    try {
      state = await ref.read(adServiceProvider).showPrivacyOptions();
    } catch (error, stackTrace) {
      debugPrint('[Ads] Privacy options failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AdState.disabled;
    }
    ref.read(playbackInterstitialProvider).setEnabled(state.canRequestAds);
  }

  void _scheduleRetry() {
    if (_retriesUsed >= retryDelays.length) {
      debugPrint(
        '[Ads] Consent unresolved after ${retryDelays.length} retries',
      );
      return;
    }

    final delay = retryDelays[_retriesUsed];
    _retriesUsed += 1;
    debugPrint('[Ads] Retrying initialization in ${delay.inSeconds}s');

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(initialize()));
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
