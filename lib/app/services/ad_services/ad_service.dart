import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:veil/app/services/ad_services/ad_platform.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class AdState {
  const AdState({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  static const disabled = AdState(
    canRequestAds: false,
    privacyOptionsRequired: false,
  );

  final bool canRequestAds;
  final bool privacyOptionsRequired;

  @override
  bool operator ==(Object other) {
    return other is AdState &&
        other.canRequestAds == canRequestAds &&
        other.privacyOptionsRequired == privacyOptionsRequired;
  }

  @override
  int get hashCode => Object.hash(canRequestAds, privacyOptionsRequired);
}

abstract interface class LoadedAd {
  Size get size;

  Widget buildWidget();

  Future<void> dispose();
}

abstract interface class AdService {
  Future<AdState> initialize();

  Future<AdState> showPrivacyOptions();

  Future<LoadedAd?> loadAdaptiveBanner(double width);

  Future<LoadedAd?> loadNative();
}

class AdUnitIds {
  const AdUnitIds._();

  static String banner(
    TargetPlatform platform, {
    bool useTestIds = !kReleaseMode,
  }) {
    return switch (platform) {
      TargetPlatform.android =>
        useTestIds
            ? 'ca-app-pub-3940256099942544/6300978111'
            : AppEnvironment.admobAndroidBannerAdUnitId,
      TargetPlatform.iOS =>
        useTestIds
            ? 'ca-app-pub-3940256099942544/2934735716'
            : AppEnvironment.admobIosBannerAdUnitId,
      _ => '',
    };
  }

  static String native(
    TargetPlatform platform, {
    bool useTestIds = !kReleaseMode,
  }) {
    return switch (platform) {
      TargetPlatform.android =>
        useTestIds
            ? 'ca-app-pub-3940256099942544/2247696110'
            : AppEnvironment.admobAndroidNativeAdUnitId,
      TargetPlatform.iOS =>
        useTestIds
            ? 'ca-app-pub-3940256099942544/3986624511'
            : AppEnvironment.admobIosNativeAdUnitId,
      _ => '',
    };
  }
}

class GoogleAdService implements AdService {
  Future<AdState>? _initializeFuture;
  var _mobileAdsInitialized = false;

  @override
  Future<AdState> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<AdState> _initialize() async {
    if (!supportsMobileAds) return AdState.disabled;

    try {
      await _requestConsentInfoUpdate();
      await _loadAndShowConsentFormIfRequired();
    } catch (error, stackTrace) {
      debugPrint('[Ads] UMP consent unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);

      try {
        final cachedState = await _readConsentState();
        if (cachedState.canRequestAds || kReleaseMode) return cachedState;
      } catch (cachedError) {
        debugPrint('[Ads] Could not read cached consent: $cachedError');
        if (kReleaseMode) return AdState.disabled;
      }

      // Debug/profile builds use only Google's test inventory. Keep local ad
      // development usable before production UMP messages are configured.
      await _initializeMobileAds();
      debugPrint('[Ads] Using test-ad fallback after UMP failure.');
      return const AdState(canRequestAds: true, privacyOptionsRequired: false);
    }

    return _readConsentState();
  }

  @override
  Future<AdState> showPrivacyOptions() async {
    if (!supportsMobileAds) return AdState.disabled;

    final completer = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(StateError(error.message));
      }
    });
    await completer.future;
    return _readConsentState();
  }

  @override
  Future<LoadedAd?> loadAdaptiveBanner(double width) async {
    if (!supportsMobileAds || width <= 0) return null;

    final adUnitId = AdUnitIds.banner(defaultTargetPlatform);
    if (adUnitId.isEmpty) return null;

    final adSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width.floor(),
    );
    if (adSize == null) return null;

    final completer = Completer<LoadedAd?>();
    late final BannerAd ad;
    ad = BannerAd(
      size: adSize,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!completer.isCompleted) {
            completer.complete(
              _GoogleLoadedAd(
                ad,
                Size(adSize.width.toDouble(), adSize.height.toDouble()),
              ),
            );
          }
        },
        onAdFailedToLoad: (failedAd, error) async {
          debugPrint('[Ads] Banner failed to load: $error');
          await failedAd.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      await ad.load();
      return completer.future;
    } catch (_) {
      await ad.dispose();
      return null;
    }
  }

  @override
  Future<LoadedAd?> loadNative() async {
    if (!supportsMobileAds) return null;

    final adUnitId = AdUnitIds.native(defaultTargetPlatform);
    if (adUnitId.isEmpty) return null;

    final completer = Completer<LoadedAd?>();
    late final NativeAd ad;
    ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!completer.isCompleted) {
            completer.complete(_GoogleLoadedAd(ad, const Size(450, 380)));
          }
        },
        onAdFailedToLoad: (failedAd, error) async {
          debugPrint('[Ads] Native ad failed to load: $error');
          await failedAd.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: VeilColors.panel,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: VeilColors.gold,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: VeilColors.text2,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: VeilColors.text3,
          style: NativeTemplateFontStyle.normal,
          size: 11,
        ),
      ),
    );

    try {
      await ad.load();
      return completer.future;
    } catch (_) {
      await ad.dispose();
      return null;
    }
  }

  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      completer.complete,
      (error) => completer.completeError(StateError(error.message)),
    );
    return completer.future;
  }

  Future<void> _loadAndShowConsentFormIfRequired() async {
    final completer = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(StateError(error.message));
      }
    });
    await completer.future;
  }

  Future<AdState> _readConsentState() async {
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    final privacyStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();

    if (canRequestAds) await _initializeMobileAds();

    return AdState(
      canRequestAds: canRequestAds,
      privacyOptionsRequired:
          privacyStatus == PrivacyOptionsRequirementStatus.required,
    );
  }

  Future<void> _initializeMobileAds() async {
    if (_mobileAdsInitialized) return;
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
  }
}

class _GoogleLoadedAd implements LoadedAd {
  const _GoogleLoadedAd(this._ad, this.size);

  final AdWithView _ad;

  @override
  final Size size;

  @override
  Widget buildWidget() => AdWidget(ad: _ad);

  @override
  Future<void> dispose() => _ad.dispose();
}
