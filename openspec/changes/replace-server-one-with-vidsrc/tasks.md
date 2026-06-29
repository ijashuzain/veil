## 1. URL Contract

- [x] 1.1 Add a Vidsrc playback URL helper in `playback_entry_url.dart` for movie and TV embed URLs.
- [x] 1.2 Prefer TMDB IDs and fall back to IMDb IDs when generating Vidsrc URLs.
- [x] 1.3 Include selected season and episode in TV Vidsrc URLs, clamping invalid values to 1.
- [x] 1.4 Add URL-builder tests for movie TMDB, movie IMDb fallback, TV TMDB, TV IMDb fallback, and invalid season/episode values.

## 2. Server 1 Flow

- [x] 2.1 Replace Server 1's `cine.su` direct HLS path with the Vidsrc embed URL path.
- [x] 2.2 Keep Server 1 movie playback as a one-tap action from the server sheet.
- [x] 2.3 Keep Server 1 TV and series playback behind the existing season/episode selection sheet.
- [x] 2.4 Open Server 1 Vidsrc URLs with `FullscreenLandscapeWebPlayer` instead of `FullscreenLandscapeDirectVideoPlayer`.
- [x] 2.5 Ensure Server 1 no longer calls the direct stream availability checker.
- [x] 2.6 Preserve Server 2 PlayIMDB/StreamIMDB behavior and Server 3 Cinesrc behavior.

## 3. Tests And Verification

- [x] 3.1 Update widget tests that currently expect Server 1 `cine.su` direct-player URLs to expect Vidsrc embedded-player URLs.
- [x] 3.2 Add widget coverage for Server 1 missing TMDB/IMDb playback IDs.
- [x] 3.3 Run `flutter test test/widget_test.dart --plain-name "detail server one"`.
- [x] 3.4 Run `flutter test`.
- [x] 3.5 Run `flutter analyze`.
- [x] 3.6 Smoke-test playback on Android or iOS if a device or simulator is available; web desktop and web mobile are not required for this change.
