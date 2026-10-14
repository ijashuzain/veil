# Veil native playback strategy

## 1. Which reported problems are app defects, and which remain provider-dependent?

### Takeaway

Keep AVPlayer/Media3 ExoPlayer and fix Server 5's playback state and controls first. Prefer documented provider adapters returning complete native playback sessions; retain CineSrc's browser-assisted resolver as a bounded beta fallback, preserving Servers 1–4. Neither a new player wrapper nor a blanket backend proxy has evidence supporting it as the primary fix.

Research date: 2026-10-14. Method: read current native-player code, playback documentation, routing, existing proxy, locked plugin source in local package cache, and official documentation through Context7/direct fetch. No playback experiments or new timing measurements were performed. Historical audit results below are attributed, not reproduced. Recommendations and numerical evaluation budgets are proposals.

### Cited Findings

| Report | Current evidence | Attribution |
|---|---|---|
| Long resolution | Resolver creates a headless WebView, loads CineSrc, injects fetch/XHR capture, waits for an HLS response, captures headers/cookies, then disposes WebView. Resolver timeout is 35 seconds; native initialization separately allows 25 seconds. These are limits, not observed latency; asynchronous teardown can add time. | Architecture includes browser/provider bootstrap before native startup. No current stage timings isolate provider versus app overhead. [Resolver L12–16, 39–84, 191–228](../../lib/src/features/native_player/repository/cinesrc_stream_resolver.dart); [view L96–149](../../lib/src/features/native_player/view/native_player_view.dart); [capture script](../../lib/src/features/native_player/utils/stream_capture_script.dart). |
| Slow seek / ±10-second skip | `_seek` snapshots `isPlaying`, awaits pause, awaits seek with 15-second timeout, then may play again. Button calls are unawaited and share no in-flight guard or latest-target queue. Repeated taps calculate from current reported position. | Confirmed command-coordination weakness. Older seek can resume after newer pause; repeated skips can collide or fail to accumulate intended distance. Actual decoder/network contribution unknown. [view L257–274, 420–470, 498–504](../../lib/src/features/native_player/view/native_player_view.dart). |
| Slow pause | Play/pause button directly invokes controller; it does not wait for resolver or source fetch. It toggles from reported `isPlaying`, with no explicit desired-playback state. | No demonstrated network dependency for pause itself. UI acknowledgment, platform events, or overlapping seek/resume race are hypotheses requiring traces. [view L420–431](../../lib/src/features/native_player/view/native_player_view.dart). |
| Buffering persists after pause | Spinner renders whenever `value.isBuffering`, independent of user play intent. Installed iOS plugin emits buffering based on `playbackLikelyToKeepUp`; rate changes are separate events. | Confirmed presentation defect: buffering readiness is not synonymous with waiting to play. Whether reported persistent buffering also includes real failed resume remains unknown. [view L476–485](../../lib/src/features/native_player/view/native_player_view.dart); [locked iOS source L300–329](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player_avfoundation-2.12.1/darwin/video_player_avfoundation/Sources/video_player_avfoundation_objc/FVPVideoPlayer.m). |
| Missing auto-hide / tall overlay | No controls-visible state or hide timer; header and two-row opaque bottom panel are always present after initialization. | Confirmed missing UI behavior/layout choice; does not depend on provider. [view L377–512](../../lib/src/features/native_player/view/native_player_view.dart). |
| Missing subtitles / quality | Stream model carries only URL, format, headers and resolution time. Resolver picks an AVC/unspecified-codec rendition at up to 720p where available; no track controls or caption rendering exist. | Confirmed metadata/UI gaps. Selecting a child playlist removes access to other variants through the master and can lose master-declared alternate audio/subtitle associations. Actual tracks available from each source remain unknown. [model L3–15, 47–85](../../lib/src/features/native_player/models/resolved_stream.dart); [view](../../lib/src/features/native_player/view/native_player_view.dart). |
| Missing episode switch | Native view receives entry URL and title, not structured playback request or episode catalog. | Confirmed navigation/data-context gap. Initial season/episode URL selection exists, but in-player switching does not. [launcher L20–27](../../lib/src/features/embeded_player/utils/playback_launcher.dart); [target L66–79](../../lib/src/features/embeded_player/utils/playback_target.dart). |

- Existing Server 5 report records advancing video for seven simulator cases, one stalled seek for Game of Thrones S2E3, and browser-free playback after resolver disposal. It explicitly calls the resolver beta and leaves physical-device/other-network validation open. It supplies no controlled native-startup/seek-latency distribution. [Server 5 report L20–43](../../docs/playback/server-five-native.md).
- Previous Servers 1–4 audit distinguishes an app/WebView compatibility issue on Server 1 from source denial/unavailability on Server 4: 403/427 responses and HTML instead of media; source selection also changed between runs. These observations do not prove CineSrc has the same failures. Its historical startup numbers include a deliberate Server 1 play-gate wait and must not serve as a native performance baseline. [Audit L40–85, 126–137](../../docs/playback/live-audit-2026-10-13.md).
- Server 3 and native Server 5 currently share CineSrc entry URL construction. Opening CineSrc embedded may recover browser-session compatibility, but is not independent-provider failover. Servers 1, 2 and 4 have separate routing branches. [Playback targets L25–79](../../lib/src/features/embeded_player/utils/playback_target.dart).

### Inferences

- Resolve UI/state defects independently of source procurement. Replacing provider cannot add auto-hide, subtitles UI, episode context, or coordinated seeks.
- Do not interpret every native stall as codec failure. Classify manifest parsing, segment/key denial, token expiry, unavailable content, codec initialization and command-state races separately.
- A paused spinner alone does not justify restarting/re-resolving. That would add bootstrap time and discard useful buffered media.

### Gaps

- No new evidence identifies the user's device, network, title, duration paused, failing resource, actual pause acknowledgment time, or whether resume fails after the spinner appears.
- Source expiry, IP binding, cookie refresh, segment duration/keyframe spacing, subtitle availability and cross-host requirements are not specified by the current `ResolvedStream` contract. No durable CineSrc native-source contract was established in this research.

## 2. What do native-player APIs imply for HLS sessions, seeking and player choice?

### Takeaway

An HLS URL is the start of a request graph, not a complete transferable browser session. Keep the current engine stack and exploit APIs already present; add narrow native extensions only for proven gaps such as seek tolerance, detailed waiting state or native subtitle-track selection.

### Cited Findings

**HLS request/session constraints**

- Apple explicitly describes HLS requests for media, crypt keys and variant indexes across paths/hosts. `AVURLAssetHTTPCookiesKey` supplements applicable cookies; Apple cautions that requests will not contain cookies that do not apply to the asset URL. WebView cookies therefore cannot be assumed to transfer automatically or cover every subordinate resource. [Apple cookie documentation](https://developer.apple.com/documentation/avfoundation/avurlassethttpcookieskey).
- Veil reads cookies once for the chosen native URL and flattens them into one `Cookie` header. JavaScript capture sees fetch/XHR headers and responses, not a complete browser-managed cookie/session engine. No expiry/refresh or per-resource policy is modeled. [Resolver L116–148](../../lib/src/features/native_player/repository/cinesrc_stream_resolver.dart); [capture L21–47](../../lib/src/features/native_player/utils/stream_capture_script.dart).
- Android Media3 supports a shared `DataSource.Factory` for HLS and `ResolvingDataSource` for URI-dependent just-in-time headers. That is the appropriate extension point when a supported integration requires resource-specific authentication, rather than universally replaying one captured header dictionary. [Official customization](https://developer.android.com/media/media3/exoplayer/customization); [official HLS guide](https://developer.android.com/media/media3/exoplayer/hls), retrieved through Context7.
- Locked Android plugin configures `DefaultHttpDataSource` with static default request headers and enables cross-protocol redirects. It does not build a WebView-cookie synchronization layer in `HttpVideoAsset`. A redirect being followed is not proof that destination session requirements are met. [Locked Android source L60–92](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player_android-2.12.2/android/src/main/java/io/flutter/plugins/videoplayer/HttpVideoAsset.java).
- Locked iOS plugin supplies headers using the literal `AVURLAssetHTTPHeaderFieldsKey`. This is implementation evidence, not an Apple-documented guarantee of arbitrary header propagation across all HLS resources/redirects. Public cookie documentation should not be generalized into such a guarantee. [Locked plugin L274–275](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player_avfoundation-2.12.1/darwin/video_player_avfoundation/Sources/video_player_avfoundation/VideoPlayerPlugin.swift); [Apple cookie contract](https://developer.apple.com/documentation/avfoundation/avurlassethttpcookieskey).

**Seek tolerance and buffering**

- Apple warns that zero-tolerance/sample-accurate seeks can incur additional decoding delay. Installed iOS plugin uses zero tolerance except its end-position special case. This is a concrete tuning opportunity, not evidence of a measured improvement. [Apple seek contract](https://developer.apple.com/documentation/avfoundation/avplayer/seek(to:tolerancebefore:toleranceafter:)); [locked iOS source L446–462](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player_avfoundation-2.12.1/darwin/video_player_avfoundation/Sources/video_player_avfoundation_objc/FVPVideoPlayer.m).
- Apple's smooth-scrubbing guidance explicitly recommends waiting for an in-progress seek before chasing the latest requested position; rapid seeks cancel earlier ones. Its example pauses for scrubbing, so it does not establish that pausing is universally wrong. Veil needs coordinated intent, not merely removal of `pause()`. [Apple QA1820](https://developer.apple.com/library/archive/qa/qa1820/_index.html).
- Media3 `SeekParameters` offers `EXACT`, `CLOSEST_SYNC`, `PREVIOUS_SYNC`, `NEXT_SYNC` and finite tolerances. Sync-point seeks are typically faster but less accurate; default is exact. Media packaging still bounds usefulness. [Official AndroidX source and API comments](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/SeekParameters.java).
- AVPlayer's `automaticallyWaitsToMinimizeStalling` defaults to true on modern systems and may delay play/resume while minimizing stall risk. Disabling it can start with available buffer but changes exhausted-buffer behavior; it is not a universal responsiveness fix. `timeControlStatus` and waiting reason distinguish paused from waiting. [Apple waiting behavior](https://developer.apple.com/documentation/avfoundation/avplayer/automaticallywaitstominimizestalling).
- `preferredForwardBufferDuration = 0` means player-selected buffering, not no buffer. Apple states low values increase rebuffer risk; high values increase resource demand. [Apple buffer documentation](https://developer.apple.com/documentation/avfoundation/avplayeritem/preferredforwardbufferduration).
- Media3 `DefaultLoadControl` separates ongoing buffer targets, start/seek thresholds, post-rebuffer thresholds and back-buffer retention. Buffer capacity is not a startup wait requirement. Its loading decision is distinct from play intent. Source defaults on the moving release branch are not asserted as Veil's exact bundled defaults. [Official AndroidX source](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/DefaultLoadControl.java).

**Current Flutter capabilities: avoid outdated assumptions**

- Actual lockfile resolves `video_player 2.14.1`, Android `2.12.2`, AVFoundation `2.12.1`, platform interface `6.9.0`; pubspec's `^2.11.1` is not the installed version. [Lockfile L1460–1491](../../pubspec.lock).
- Current controller already exposes `getVideoTracks`, `selectVideoTrack`, audio-track methods, capability checks and closed-caption-file APIs. `selectVideoTrack(null)` restores Auto. iOS uses a preferred peak bitrate; Android uses a track override. iOS 13–14 returns no HLS variant list; enumeration requires iOS 15+. [Official controller docs via Context7](https://pub.dev/documentation/video_player/latest/video_player/VideoPlayerController-class.html); [locked controller L1070–1129](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player-2.14.1/lib/video_player.dart).
- iOS plugin implements selection by `preferredPeakBitRate`, and estimates selected variant using bitrate comparison. It does not guarantee exact fixed-resolution selection or exact current-rendition reporting. [Locked iOS implementation L494–565, 604–614](file:///Users/ijashuzain/.pub-cache/hosted/pub.dev/video_player_avfoundation-2.12.1/darwin/video_player_avfoundation/Sources/video_player_avfoundation_objc/FVPVideoPlayer.m).
- AVFoundation supports media-selection criteria for audible, legible and visual characteristics, with explicit selection overriding automatic selection. Flutter caption-file support is not equivalent to a complete native HLS subtitle-track discovery/selection bridge. [Apple media selection](https://developer.apple.com/documentation/avfoundation/avplayer/setmediaselectioncriteria(_:formediacharacteristic:)); [Flutter controller](https://pub.dev/documentation/video_player/latest/video_player/VideoPlayerController-class.html).

### Inferences

- Default to a compatible HLS master and adaptive playback; preserve master-level audio/subtitle groups. Retain conservative codec behavior through supported capability/variant constraints or a correctly constructed compatible master, not by blindly restoring every 4K/HEVC variant. Keep direct-child fallback where demonstrably necessary.
- Provide Auto and honest manual quality labels. On iOS describe selection as a quality/bitrate preference or limit; do not promise a hard 720p lock from `preferredPeakBitRate` alone.
- Coalesce seeks to one in-flight operation plus latest target. Track desired play/pause separately, let latest user pause win, accumulate ±10-second taps against pending target, clamp to seekable bounds, and ignore stale completion events after retry/episode change. Keep scrubbing preview responsive while waiting for decoder readiness.
- Test a modest finite seek tolerance for ordinary skips before using unrestricted nearest-sync. Preserve exact mode only where precision is required. Expose tolerance via a small federated-plugin extension if needed; the app-facing `seekTo(Duration)` does not expose it.
- Evaluate a bounded Android back buffer to help rewind after state fixes, within memory limits. Forward-buffer tuning cannot manufacture cached backward media or cure denied segments. Do not blindly set minimum buffers to zero.
- For subtitles, support provider-declared sidecar captions using existing caption APIs plus rendered caption widget first. Native segmented HLS subtitles need explicit discovery/selection/rendering verification and possibly a native bridge. Keep Off, language, forced/default semantics and offset controls; report unavailable tracks honestly.

### Gaps

- No evidence demonstrates which cookie/header/redirect combination fails on the user's source. Validate master, child playlists, segments, init maps, keys and subtitles, not only a successful first manifest.
- No supported cross-platform arbitrary request-interception contract was established for AVPlayer here. Android's `ResolvingDataSource` must not be assumed to have a drop-in AVPlayer equivalent.
- Three direct Android documentation fetches timed out; conclusions instead use Context7-retrieved official HLS/customization material and official AndroidX source. Native tolerance/buffer APIs are established, but required Flutter bridge details remain implementation work.

## 3. Which integration strategy and implementation priorities best satisfy all requests?

### Takeaway

Use provider adapters feeding the existing native engines, preferably through documented direct-HLS session APIs. Separate resolution/control-plane work from media transport; introduce backend proxying only when a shortlisted provider's concrete session contract requires it and measured validation supports it.

### Cited Findings

- Current `StreamResolver` provides a useful abstraction boundary but accepts only an entry URI and returns minimal metadata; CineSrc implementation explicitly permits only `https://cinesrc.st`. It is not yet a multi-provider session interface. [Resolver L21–28](../../lib/src/features/native_player/repository/cinesrc_stream_resolver.dart); [model L3–28](../../lib/src/features/native_player/models/resolved_stream.dart).
- Current Supabase proxy is not ready to substitute for that session layer: upstream headers include only Range, Accept and User-Agent; redirects are manual but returned without proxy-aware redirect rewriting; playlist detection depends on `.m3u8` pathname; host enforcement is commented out. It rewrites non-comment URI lines and quoted URI attributes, but has no provider cookie/token-refresh contract. Extensionless playlists such as those recognized by the native capture script are not classified by that proxy. [Proxy L40–84, 104–139](../../supabase/functions/proxy/index.ts); [capture L43](../../lib/src/features/native_player/utils/stream_capture_script.dart).
- Server 5 is already isolated by a `nativePlayback` branch while Servers 1–4 retain existing target/launcher behavior; embedded fallback releases native resources before replacement. [Targets](../../lib/src/features/embeded_player/utils/playback_target.dart); [launcher](../../lib/src/features/embeded_player/utils/playback_launcher.dart); [view L221–249](../../lib/src/features/native_player/view/native_player_view.dart).

### Inferences

#### Recommended architecture

1. **Provider adapter → playback session → native controller.** Session should include content/episode identity, master URL, expiry/refresh operation, per-origin request policy or supported signed URLs, subtitle/audio/quality metadata, capability flags, cancellation and typed failure reasons. Keep transient credentials in memory; persist content/episode identity and preferences.
2. **Prefer documented direct native playback.** If provider credentials require server custody, a backend can issue/resolve sessions while media flows directly from CDN to device. This avoids treating every media byte as a backend responsibility. Direct transport still needs proof that the returned session is valid from the device's network.
3. **Use a media proxy only for a demonstrated requirement.** If provider binds sessions to backend egress or requires backend-owned request signing, resolving on backend then handing URL to device may fail. Proxying must then preserve that session for all dependent requests. Conversely, moving an on-device browser session to backend egress may invalidate it. IP binding is an evaluation question, not an established CineSrc fact.
4. **If proxy selected, implement complete protocol behavior.** Require redirect-aware origin validation and URL rewriting, MIME/body-aware playlist detection, relative URI resolution after redirects, key/map/subtitle routing, Range/206 semantics, correct transformed response headers, expiry/refresh and bounded retry. Include concurrency, geography, egress cost and cancellation in acceptance. A blanket proxy adds another network path and operating cost; no current evidence says it reduces resolution or seeking time.
5. **Keep on-device resolution as bounded fallback.** It retains device-side provider interaction but still runs page/bootstrap code and produces a session snapshot. Do not persist signed URLs indefinitely or endlessly add capture/decryption logic. Do not convert Servers 1–4 into extracted native sources as collateral work.

#### Implementation priority order

| Priority | Work covering requested behavior | Acceptance intent |
|---|---|---|
| P0 | Explicit desired-playback state; resolve/initialize/ready/paused/seeking/waiting/error stages; coalesced seeks and skip accumulation; immediate pause UI; stale-operation cancellation. | Pause wins against older seek completion; rapid skips land at accumulated target; paused seek stays paused; close/retry cannot revive old playback. |
| P0 | Spinner driven by startup or requested playback waiting for media, not `isBuffering` alone. Distinguish seek progress from playback stall. | Pausing dismisses playback-wait UI immediately; resume surfaces genuine waiting; no re-resolution merely to clear spinner. |
| P0 | Compact overlay: thin timeline and one compact transport row; settings/episode actions in sheets. Tap toggles; proposed 3-second hide after interaction while playing; keep visible while paused, scrubbing, menu open or accessibility focus active. | Header and transport hide together; reveal works; large touch targets remain; no tall persistent opaque card. |
| P0 | Stage diagnostics and structured failure categories. Record resolve start/end, resolver disposal, initialization, first rendered frame where supported, command acknowledgment, seek frame-ready, resume and request-class failure. | No timing claim based only on route entry, initialization or advancing playhead. Existing `nativePlaying` event is position ≥3 seconds, not first-frame telemetry. |
| P1 | Preserve compatible HLS master, use existing video-track APIs, add Auto/quality and audio menu where available. | Dynamic tracks; no fabricated resolutions; preserve position/play intent; label iOS preference accurately; verify conservative codec cases. |
| P1 | Extend session metadata for subtitles; sidecar loading/rendering, language/Off/default/forced and offset; add native HLS bridge only if required. | Captions synchronize across seek/pause/quality changes, remain readable with hidden controls, use correct session headers and report unavailability. |
| P1 | Pass structured `PlaybackRequest` into native screen; reuse episode catalog, season picker and history identity; cancel old resolution on selection. | Correct series/season/episode, clear loading/current episode, no old audio/events, per-episode resume policy; next episode only where catalog confirms it. |
| P1 | Bounded provider-adapter evaluation and source-aware fallback. | Refresh an expired session once where supported; classify denials/unavailability promptly; expose Servers 1–4 without rewriting their routing. |
| P2 | Small native extensions for finite seek tolerance, waiting reason, native subtitle selection or buffer/back-buffer controls after profiling. | Demonstrated improvement without higher rebuffer rate, unacceptable seek error or memory regression on physical iOS/Android. |

These are proposals derived from the concrete state/UI gaps and player contracts in Sections 1–2, not implemented changes or measured outcomes.

#### Bounded provider evaluation proposal

- **Scope cap:** evaluate at most three adapters: current CineSrc baseline plus at most two candidates with documented native-source/session interfaces. Timebox initial contract/implementation feasibility to one engineer-day per candidate; reject unresolved essential session requirements instead of growing an open-ended scraper.
- **Concrete integration gate:** obtain documentation identifying native playback support, allowed client/backend integration mode and redistribution/proxy rights where needed, SDK/license obligations if an SDK is used, rate limits, token TTL/refresh behavior, supported platforms, subtitle/quality metadata and support/versioning contact. This is a procurement/maintenance acceptance criterion, not a generic licensing warning.
- **Transport gate:** demonstrate master/variants/segments/init maps/keys/subtitles under real session rules, redirects, signed-URL expiry, paused resume, network change and device-versus-backend egress. Source must remain usable after resolver disposal. Include one controlled standards-compliant HLS fixture to isolate app defects from provider behavior.
- **Fixed test matrix:** reuse four movies and three episodes from existing audit, including Game of Thrones S2E3; use physical iOS and Android and two network conditions. Two startup attempts per title/platform/network gives 56 attempts per candidate, reported by cell rather than hiding failures in averages. Document cold/warm state; add one long session crossing documented TTL per platform for finalists.
- **Interaction script:** pause/resume, pause during an in-flight seek, five rapid +10 and −10 taps, seek inside/outside buffered range, near-end seek, seek while paused, quality change, subtitles, episode switch, background/resume and close during resolution. Observe target-frame readiness, not just method completion.
- **Proposed initial budgets, not measurements:** aim for pause/control acknowledgment ≤100 ms, warm/in-buffer seek-to-frame ≤1 second, cold/out-of-buffer seek ≤3 seconds, and native first frame ≤8 seconds on agreed reference conditions. Separate resolver budget, e.g. ≤5 seconds for a documented API; give browser fallback a clearly bounded user-visible escape, e.g. 10 seconds, with cancellation rather than endless waiting. Calibrate against controlled fixture before making release promises.
- **Reliability gate:** require no recurring session/seek/state failure and at least 95% successful first-frame starts in this screening matrix. Include failures/timeouts in results; do not claim the small sample certifies production reliability or a stable per-device p95. Report medians, ranges and counts, with startup stages and rebuffer seconds per playback minute.
- **Selection:** among candidates passing functional/session gates, rank measured successful startup and seek recovery first, then subtitle/quality/episode coverage, maintenance contract and total delivery cost. If none pass, keep Server 5 labeled beta and preserve explicit embedded/server selection; do not promote a provider solely because one title starts quickly.

### Gaps

- This research does not nominate a newly verified streaming provider: no candidate contract, endpoint or physical-device benchmark was supplied or validated. A bounded evaluation is necessary before choosing one.
- Proxy versus direct cost/latency depends on session binding, traffic volume and CDN geography; current repo cannot determine those values.
- Quality/subtitle availability cannot be repaired in UI when source lacks corresponding renditions/tracks. Exact iOS quality locking and segmented subtitle rendering require separate acceptance evidence.
- Only this research note was created. App edits, dependency changes, tool installations and live playback measurements were outside this research task.
