# AdMob Ads Design

**Date:** 2026-08-28
**Status:** Approved

## Goal

Monetize Veil on Android and iOS with Google AdMob anchored adaptive banners and native template ads while preserving startup, playback, navigation, pagination, and web behavior.

## Product Decisions

- Use Google AdMob through the official `google_mobile_ads` Flutter plugin.
- Support Android and iOS. Web remains ad-free and must keep compiling.
- Show ads to every user, including premium users.
- Include anchored adaptive banners and native ads only. Interstitial, rewarded, app-open, and custom native ads are out of scope.
- Use Google medium native templates rather than Kotlin and Swift `NativeAdFactory` implementations.
- Use one inline Home banner plus native ads after every 12 organic items in eligible linear feeds and grids.
- Keep onboarding, password recovery, fullscreen playback, own Profile, and settings ad-free.
- Do not request App Tracking Transparency permission in this release.

## AdMob Identifiers

### App IDs

- Android: `ca-app-pub-9567183629579117~3553991339`
- iOS: `ca-app-pub-9567183629579117~3532820354`

### Production Ad-Unit IDs

- Android adaptive banner: `ca-app-pub-9567183629579117/6978075494`
- iOS adaptive banner: `ca-app-pub-9567183629579117/1861480181`
- Android native: `ca-app-pub-9567183629579117/8848348916`
- iOS native: `ca-app-pub-9567183629579117/9806207364`

### Development Ad-Unit IDs

Debug and profile builds must use Google's official test units regardless of production configuration:

- Android banner: `ca-app-pub-3940256099942544/6300978111`
- iOS banner: `ca-app-pub-3940256099942544/2934735716`
- Android native: `ca-app-pub-3940256099942544/2247696110`
- iOS native: `ca-app-pub-3940256099942544/3986624511`

Production app IDs are public native configuration values. Production ad-unit IDs live in typed Dart configuration with optional `ADMOB_ANDROID_BANNER_AD_UNIT_ID`, `ADMOB_IOS_BANNER_AD_UNIT_ID`, `ADMOB_ANDROID_NATIVE_AD_UNIT_ID`, and `ADMOB_IOS_NATIVE_AD_UNIT_ID` `dart-define` overrides, following existing `AppEnvironment` conventions. Code selects test units whenever `kReleaseMode` is false.

## Platform Configuration

- Add Android AdMob app ID metadata under the existing `<application>` in `AndroidManifest.xml`.
- Add `GADApplicationIdentifier` to iOS `Info.plist`.
- Add current Google-documented iOS SKAdNetwork entries required for Mobile Ads attribution.
- Do not add `NSUserTrackingUsageDescription` because this release does not request ATT authorization.
- Let plugin manifests provide SDK-owned Android permissions unless build verification proves an explicit app permission is required.
- Do not change package or bundle ID `com.vexellab.veil`.

## Architecture

### Ad Service

Create one mobile-only ad service under `lib/app/services/` with these responsibilities:

- Request a fresh UMP consent-information update once per app launch.
- Load and show a consent form when required.
- Check `ConsentInformation.canRequestAds()` before enabling ad requests.
- Initialize `MobileAds.instance` once after ads can be requested.
- Expose readiness and privacy-options availability through overridable Riverpod providers.
- Open the UMP privacy-options form from Profile when required.
- Return a disabled state on web, unsupported platforms, plugin failures, or consent failures.

The service starts after the first frame. Existing startup order remains Flutter binding, `LocalStorage.init()`, `SupabaseService.init()`, persisted-session routing, and `runApp()`. Ad initialization must not delay initial routing or replace routed content.

### Shared Ad Widgets

Add two shared, mobile-only widgets:

- `AdaptiveBannerAd`: resolves anchored adaptive size from available width, loads one banner, displays it only after a successful load, and disposes it with widget lifecycle.
- `NativeTemplateAd`: loads one medium native template styled for Veil's dark surface and gold accent, displays it only after successful load, and disposes it with widget lifecycle.

Both widgets consume the shared readiness provider. They render `SizedBox.shrink()` when disabled, loading, denied, failed, unsupported, or disposed. They must not call native plugin APIs in web or widget-test environments.

No premium provider participates in ad visibility.

## Banner Placement

- Show one anchored adaptive banner in Home discovery mode between Global trending and New this week.
- Keep the banner inside Home's scroll flow; it must not pin to navigation or viewport edges.
- Do not show banners in Diary, Reviews, Profile, pushed routes, detail, auth, recovery, settings, or playback.

## Native Placement

### Frequency Rule

- Insert a medium native template after 12 organic items, then after 24, 36, and subsequent complete groups of 12.
- Ads never count as organic items.
- Repository requests, pagination offsets, result totals, poster indexes, and analytics semantics remain content-only.
- Grid ads occupy a full-width sliver between 12-item grid chunks. They never impersonate poster-grid cells.
- Segment/tab changes calculate frequency independently for the selected content collection.
- Empty Diary and Reviews states contain one native slot. Other empty, loading, and error states contain no ad slots.

### Screen Map

- Home discovery mode: one native template after the second discovery rail because this mode is section-based rather than a linear feed.
- Home selected-genre mode: full-width native template after every 12 posters.
- Diary watched, watchlist, and favorites grids: full-width native template after every 12 posters, or one native template after the empty state.
- Reviews community and personal feeds: native template after every 12 review cards, or one native template after the empty state.
- Search results: one native template after the first three top results, or after all results when only one or two exist; none in empty or recent-search states.
- See All catalogs: full-width native template after every 12 posters.
- Provider movie and TV catalogs: full-width native template after every 12 posters while preserving pinned headers and pagination footers.
- Alerts and suggestions: native template after every 12 tiles, independently per segment.
- Other-user profile activity/member feeds: native template after every 12 items. This does not include own Profile/settings.
- Movie and TV detail: one native template after description and before clips/reviews content. Play and rating actions remain above it and unobstructed.

## Consent And Privacy Controls

- Use Google UMP's region-aware consent flow.
- Request consent-information update on every launch.
- Never request ads before `canRequestAds()` succeeds.
- If `PrivacyOptionsRequirementStatus.required` is reported, show a `Privacy choices` row in Profile's legal/support area.
- Opening `Privacy choices` presents Google's privacy-options form and refreshes ad readiness afterward.
- Consent UI is Google-owned. Veil does not create a second custom consent dialog.
- Consent failure is fail-closed for monetization: app remains usable, but no ads load during that session.

## Failure And Lifecycle Behavior

- Ad-load failure disposes the failed ad and collapses its slot to zero height.
- No placeholder, spinner, error message, toast, or reserved blank area appears for ad failures.
- Do not run automatic tight retry loops. A new request may occur when the owning widget is recreated or its content is refreshed.
- Width changes recreate adaptive banners with a newly resolved size.
- Widget disposal always disposes loaded or loading ad objects.
- Native insertion remains deterministic while pagination appends content, preventing duplicate slots at chunk boundaries.
- Backgrounding, route changes, orientation changes, and player transitions must not leave orphaned platform views.
- Fullscreen player remains free of app-owned ad views and ad lifecycle hooks.

## Testing

### Automated

- Override ad service/readiness providers in widget tests so no real platform channel is called.
- Test release/debug ad-unit selection independently from plugin loading.
- Test ads are disabled on web and unsupported platforms.
- Test no shell-level banner exists and Home banner orders between Global trending and New this week.
- Test native insertion after organic items 12 and 24 without changing item order or count.
- Test Home discovery and Detail fixed native seams.
- Test loading, denied-consent, consent-error, and ad-load-error states collapse to zero space.
- Test ad disposal when widgets unmount or change size.
- Preserve existing grid-column, pagination, premium-playback, routing, and WebView ad-blocking tests.
- Add lightweight checks for required Android manifest and iOS plist app IDs.

### Commands

- `flutter analyze`
- Focused ad and affected-screen widget tests
- `flutter test`
- Android debug build
- Unsigned iOS build
- Web release build to prove ads remain excluded from web runtime

### Manual

- Use UMP debug geography and test-device configuration to exercise required/not-required consent states.
- Confirm only Google test ads appear in debug/profile builds on physical Android and iOS devices.
- Confirm release configuration selects supplied production IDs without generating test impressions.
- Exercise rotation, compact/tablet breakpoints, shell tab switching, pagination, refresh, offline/load failure, and Profile privacy options.
- Confirm no ad appears during auth, recovery, account management, or playback.

## Store And Website Release Requirements

- Keep `https://vexellab.com/app-ads.txt` publicly crawlable with publisher record `google.com, pub-9567183629579117, DIRECT, f08c47fec0942fa0`.
- Keep `robots.txt` permissive for `Google-adstxt` and related Google crawlers.
- Android app-ads.txt verification is complete.
- iOS App Store metadata must expose `https://www.vexellab.com/` as Marketing URL/Developer Website before iOS app-ads.txt verification can complete.
- Update Veil privacy policy to disclose Google Mobile Ads, advertising identifiers, consent choices, data processing, and partner links before store release.
- Update Google Play Data Safety declarations; current public declaration says no data is collected or shared.
- Update Apple App Privacy disclosures; current public listing only declares contact information used for app functionality.
- Complete AdMob app readiness review before relying on production fill.

## Out Of Scope

- Interstitial, rewarded, rewarded-interstitial, and app-open ads.
- Premium or ad-free entitlement changes.
- ATT prompts or custom tracking permission UX.
- Custom Kotlin/Swift native-ad factories.
- Ad mediation, bidding partners, frequency caps configured outside AdMob, revenue analytics, or remote placement configuration.
- Web advertising.
