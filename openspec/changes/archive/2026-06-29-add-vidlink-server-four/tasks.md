## 1. URL Contract

- [x] 1.1 Add a VidLink playback URL helper in `playback_entry_url.dart` for movie and TV episode URLs.
- [x] 1.2 Require a valid TMDB ID for VidLink URLs and return no URL when the TMDB ID is missing or invalid.
- [x] 1.3 Include selected season and episode in TV VidLink URLs, clamping invalid values to 1.
- [x] 1.4 Add URL-builder tests for movie TMDB, TV TMDB, invalid season/episode values, and missing TMDB ID.

## 2. Server 4 Flow

- [x] 2.1 Add a fourth Server 4 option to `DetailPlaybackServerSheet`.
- [x] 2.2 Route Server 4 movie playback from the server sheet to the VidLink movie URL path.
- [x] 2.3 Route Server 4 TV and series playback through the existing season/episode selection sheet.
- [x] 2.4 Open Server 4 VidLink URLs with `FullscreenLandscapeWebPlayer` using top-level page loading.
- [x] 2.5 Update the mobile WebView main-frame guard to allow VidLink movie and TV page paths when loaded as a top-level page.
- [x] 2.6 Ensure Server 4 does not call the direct stream availability checker or direct HLS player.
- [x] 2.7 Preserve Server 1 Vidsrc, Server 2 PlayIMDB/StreamIMDB, and Server 3 Cinesrc behavior.

## 3. Tests And Verification

- [x] 3.1 Add widget coverage for the playback server sheet showing Server 4.
- [x] 3.2 Add widget coverage for Server 4 movie playback opening the VidLink web player.
- [x] 3.3 Add widget coverage for Server 4 TV playback asking for season and episode before opening VidLink.
- [x] 3.4 Add widget coverage for Server 4 missing TMDB ID behavior.
- [x] 3.5 Add mobile WebView coverage for allowing top-level `vidlink.pro/movie/...` and `vidlink.pro/tv/...` paths while preserving ad/main-frame blocking.
- [x] 3.6 Run `flutter test test/widget_test.dart --plain-name "server four"`.
- [x] 3.7 Run `flutter test`.
- [x] 3.8 Run `flutter analyze`.
- [x] 3.9 Smoke-test Server 4 playback on Android or iOS; web desktop and web mobile are not required for this change.
