import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/src/core/providers/ad_providers.dart';

class AdaptiveBannerAd extends ConsumerStatefulWidget {
  const AdaptiveBannerAd({super.key});

  @override
  ConsumerState<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends ConsumerState<AdaptiveBannerAd> {
  /// A no-fill on the first request is routine, so a failed slot re-arms
  /// instead of staying blank until the layout width happens to change.
  static const _retryDelays = [
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(seconds: 90),
  ];

  LoadedAd? _ad;
  int? _attemptedWidth;
  var _loading = false;
  var _clearing = false;
  var _retriesUsed = 0;
  Timer? _retryTimer;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      adControllerProvider.select((state) => state.canRequestAds),
    );
    if (!enabled) {
      _scheduleClear();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.floor()
            : MediaQuery.sizeOf(context).width.floor();
        _scheduleLoad(width);

        final ad = _ad;
        if (ad == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: ad.size.width,
            height: ad.size.height,
            child: ad.buildWidget(),
          ),
        );
      },
    );
  }

  void _scheduleLoad(int width) {
    if (width <= 0 || _loading || _attemptedWidth == width) return;
    _loading = true;
    _attemptedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_load(width));
    });
  }

  Future<void> _load(int width) async {
    final loaded = await ref
        .read(adServiceProvider)
        .loadAdaptiveBanner(width.toDouble());
    if (!mounted || _attemptedWidth != width) {
      await loaded?.dispose();
      return;
    }

    final previous = _ad;
    setState(() {
      _ad = loaded;
      _loading = false;
    });
    await previous?.dispose();

    if (loaded == null) {
      _scheduleRetry(width);
    } else {
      _retriesUsed = 0;
    }
  }

  void _scheduleRetry(int width) {
    if (_retriesUsed >= _retryDelays.length) return;

    final delay = _retryDelays[_retriesUsed];
    _retriesUsed += 1;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      _loading = true;
      unawaited(_load(width));
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleClear() {
    if (_clearing || (_ad == null && !_loading && _attemptedWidth == null)) {
      return;
    }
    _clearing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_clear());
    });
  }

  Future<void> _clear() async {
    _cancelRetry();
    _retriesUsed = 0;
    final previous = _ad;
    setState(() {
      _ad = null;
      _attemptedWidth = null;
      _loading = false;
      _clearing = false;
    });
    await previous?.dispose();
  }

  @override
  void dispose() {
    _cancelRetry();
    unawaited(_ad?.dispose());
    super.dispose();
  }
}
