# Server 5 native playback

Server 5 is a separate Android/iOS playback path. It uses CineSrc to resolve a
real HLS request, captures the source's required headers/cookies in memory,
disposes its temporary headless WebView, and then opens video_player's native
AVPlayer/ExoPlayer implementation. Servers 1–4 retain their existing target and
launcher decisions.

## Behavior

- Movie and selected season/episode routing through a fifth server-sheet option.
- Native playback, pause/resume, seek slider, forward/rewind, close, and retry.
- Explicit embedded fallback when native resolution/playback fails or the
  platform does not support this native path.
- Conservative AVC/H.264 rendition selection up to 720p where advertised.
- Signed URLs and headers remain in memory; history stores only content/server
  identity and episode selection.
- Resolver cancellation and native-player release when the route closes.

## Verified results

Latest iPhone 17 Pro / iOS 26.5 simulator matrix:

| Content | Native video | Seek to 45s and resume |
| --- | --- | --- |
| Fall 2: Deadpoint | Passed | Passed |
| Interstellar | Passed | Passed |
| Dune: Part Two | Passed | Passed |
| Avatar | Passed | Passed |
| Breaking Bad S1E1 | Passed | Passed |
| Game of Thrones S2E3 | Passed | Stalled in this run |
| Arcane S2E3 | Passed | Passed |

Native telemetry and screenshots prove advancing video after resolver disposal.
Early trials exposed a native-surface initialization dependency and rendition
compatibility problems; these were corrected before the latest matrix.

This remains a beta browser-assisted resolver, not a documented stable stream
API. Initial resolution still loads the provider, and provider URLs/session
requirements can change. Subtitles and advanced quality/audio selection are not
part of this first implementation. Physical-device and other-network validation
are still required. The embedded fallback remains available for source or seek
limitations.

## Validation

- 60 focused playback/history/UI checks passed, including existing server paths.
- Android debug APK and web debug build succeeded.
- Analysis has no errors; existing async-return warnings remain outside this feature.
- Live tests: `integration_test/playback_live_test.dart` with
  `PLAYBACK_SERVER_FILTER=5`; see `integration_test/README.md` for runtime credentials.
