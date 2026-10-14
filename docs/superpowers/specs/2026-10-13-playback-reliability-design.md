# Playback reliability

## Approved approach

Use `flutter_inappwebview` for mobile playback with request-level ad blocking,
explicit popup rejection, scheme validation, and Android hybrid composition.
Keep provider pages and stream requests direct. Rust is not required.

## Components and behavior

- A shared playback policy validates URLs, pins top-level navigation to explicit
  provider hosts/subdomains, and blocks a bundled, targeted ad-domain list.
  Avoid generic `player`, `embed`, or `video` rules that break stream providers.
- A shared mobile WebView configures inline autoplay, hardware rendering, early
  all-frame popup guards and media events. Reject new windows and downloads.
  Use WKWebView content rules on Apple platforms. On Android, intercept requests
  without the plugin's content-blocker MIME-probing HEAD requests.
- Embedded playback shows a small, non-blocking loading indicator. Page completion
  and visible media dismiss it. A startup watchdog offers retry/server guidance;
  relevant HTTP/network failures can advance explicit fallback URLs. Ignore ad
  errors, stale callbacks, and callbacks after disposal.
- Web embeds use a sandbox without popup or top-navigation permissions. Browser
  cross-origin isolation prevents resource filtering inside third-party frames;
  external provider pages remain outside app-level ad blocking.
- Direct HLS playback prefers supported native playback immediately, loads a pinned
  HLS.js version only when needed, and bounds fatal-error recovery.
- Server 3 passes the selected series season and episode.

## Verification

Test navigation and domain boundaries, nested-frame app links, request blocking,
popup rejection, non-blocking loading, media readiness, startup retry/fallback,
disposal, HLS engine choice/recovery, and episode selection. Run Flutter tests,
static analysis, and web compilation. Physical-device validation remains necessary
for codec compatibility and network-dependent stream behavior.
