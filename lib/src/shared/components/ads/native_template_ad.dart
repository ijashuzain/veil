import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/src/core/providers/ad_providers.dart';

class NativeTemplateAd extends ConsumerStatefulWidget {
  const NativeTemplateAd({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<NativeTemplateAd> createState() => _NativeTemplateAdState();
}

class _NativeTemplateAdState extends ConsumerState<NativeTemplateAd> {
  /// A no-fill on the first request is routine, so a failed slot re-arms
  /// instead of staying blank for the rest of the session.
  static const _retryDelays = [
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(seconds: 90),
  ];

  LoadedAd? _ad;
  var _attempted = false;
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

    _scheduleLoad();
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(0, ad.size.width).toDouble()
              : ad.size.width;
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              height: ad.size.height,
              child: ad.buildWidget(),
            ),
          );
        },
      ),
    );
  }

  void _scheduleLoad() {
    if (_attempted || _loading) return;
    _attempted = true;
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final loaded = await ref.read(adServiceProvider).loadNative();
    if (!mounted) {
      await loaded?.dispose();
      return;
    }
    setState(() {
      _ad = loaded;
      _loading = false;
    });

    if (loaded == null) {
      _scheduleRetry();
    } else {
      _retriesUsed = 0;
    }
  }

  void _scheduleRetry() {
    if (_retriesUsed >= _retryDelays.length) return;

    final delay = _retryDelays[_retriesUsed];
    _retriesUsed += 1;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      _loading = true;
      unawaited(_load());
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleClear() {
    if (_clearing || (_ad == null && !_loading && !_attempted)) return;
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
      _attempted = false;
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
