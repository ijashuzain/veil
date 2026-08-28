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
  LoadedAd? _ad;
  var _attempted = false;
  var _loading = false;
  var _clearing = false;

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
    unawaited(_ad?.dispose());
    super.dispose();
  }
}
