# Playback Reliability Implementation Plan

**Goal:** Improve playback startup, video visibility, and protection against provider ads.

**Architecture:** Shared mobile playback WebView and pure URL policy. Native Apple
content rules and Android request interception block targeted ad domains without
filter downloads or stream preflight requests. Media events and non-blocking UI
separate playback from page-resource completion.

**Tech stack:** Flutter, Dart, flutter_inappwebview 6.1.x, WKWebView, Android WebView,
native HLS and pinned HLS.js.

## Constraints

- Preserve `embeded_player` paths, existing constructors, providers, and launch policy.
- Do not hand-edit generated files or introduce Rust.
- Preserve TLS validation and reject external schemes, downloads, and popups.
- Do not run Android content blockers that probe every resource with HEAD.

## Tasks

- [x] Add `utils/playback_webview_policy.dart` with host-boundary navigation rules,
  a bundled domain blocklist, shared sandbox flags, and regression cases in
  `test/playback_webview_policy_test.dart`.
- [x] Add `view/mobile_playback_webview.dart` with hybrid composition, autoplay,
  all-frame document-start guards, Apple content blockers, Android interception,
  and callbacks for page readiness, media readiness, and relevant failures.
- [x] Migrate `view/player_mobile.dart` and `view/direct_video_player_mobile.dart`
  to shared WebView; ensure loading does not cover or consume player input.
- [x] Update `view/player_web.dart` sandbox permissions. Update
  `view/direct_video_player_script.dart` for native-first, lazy pinned HLS.js and
  bounded recovery; adapt web direct-player bootstrap/cleanup.
- [x] Pass season/episode in `utils/playback_target.dart`; update playback tests.
- [x] Replace playback WebView fakes in `test/widget_test.dart`, covering request
  filtering, popup rejection, startup failure/retry, and media readiness.
- [x] Run `flutter pub get`, focused playback tests, `flutter analyze`, full
  `flutter test`, and web compilation. Inspect final diff for incidental changes.

## Verification results

- Focused playback checks: 35 passed, including renderer termination recovery.
- Full suite: 272 passed, 7 failed in existing signup/review UI due to Flutter
  3.47.2 `ListTile`/`DecoratedBox` debug assertions.
- Analysis: no errors; three existing `unawaited_return_in_try_block` warnings
  in ad services and social repository.
- Android debug APK, unsigned iOS debug app, and web debug build succeeded.
- WebKit content-blocker regex compiled successfully using the native API.
- Keep CocoaPods enabled for the playback plugin; disable project-level SwiftPM
  migration. Restore incidental SDK build migrations to native project settings.
- Physical-device/network testing still required for device-specific codecs,
  rendering, provider uptime, and regional/CDN reachability.
