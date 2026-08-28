import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';

final adServiceProvider = Provider<AdService>((ref) => GoogleAdService());

final adControllerProvider = NotifierProvider<AdController, AdState>(
  AdController.new,
);

class AdController extends Notifier<AdState> {
  var _started = false;

  @override
  AdState build() => AdState.disabled;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;

    try {
      state = await ref.read(adServiceProvider).initialize();
    } catch (_) {
      state = AdState.disabled;
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      state = await ref.read(adServiceProvider).showPrivacyOptions();
    } catch (_) {
      state = AdState.disabled;
    }
  }
}
