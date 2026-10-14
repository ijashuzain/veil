# Repository player evaluation for Veil

Research date: 2026-10-14. Static source inspection only; no clones, installs, builds, playback, or upstream provider requests. App files were read only. Existing working-tree native-player work was treated as current context, not changed.

## Recommendation

**VortX is the best reference for native transport correctness, source headers, and episode ownership. Streambert is the best inspected example of actual provider-specific extraction, narrowly for anime. Watchlo is useful for source normalization and control layout, not general movie/TV extraction.** None is a drop-in Flutter resolver/player.

| Repository | Actual source path observed | Useful to Veil | Main limitation |
|---|---|---|---|
| Streambert | Electron webviews plus intercepted URL notifications; separate AllAnime/AllManga resolver returns direct URLs | Anime resolver boundary, subtitle search metadata, cancellable next-episode countdown | Desktop Node/Electron assumptions; web/DOM transport controls; no verified portable cookie handoff |
| VortX | Stremio/add-on/debrid ecosystem; direct/HLS community-provider results mapped into native sources | Seek/pause intent, load ownership, header sanitation, subtitle timing scope, next/previous inventory policy | Swift/libmpv policies need independent Dart adaptation; private engine dependency; not a bundled universal extractor |
| Watchlo | Movie/TV iframe URL construction; anime route normalizes external API results and HLS proxy URLs | Quality/subtitle normalization, ±10-second controls, bounded previous/next UI | Extraction backend is external; React/Next UI; no license grant found |

“Low latency” here means responsive playback commands and avoiding avoidable reloads. No measured startup, seek, pause, rebuffering, or live-edge latency results were obtained. README adjectives, stars, source labels, and code comments are not benchmarks.

## Pinned revisions, scope, and licenses

| Repository | Inspected content revision | License evidence |
|---|---|---|
| [Streambert][s-root] | `4afe564e5ea2565c96d6f2e61679c00fad2d498c` | Actual root [LICENSE][s-license] contains GNU GPL version 3; package metadata also declares `GPL-3.0` |
| [VortX][v-root] | `7b3d0d7204f423fe0dd7119d14e80e561c838c6b` | Actual root [LICENSE][v-license] contains GNU GPL version 3; README identifies GPL-3.0 app and separately obtained server components |
| [Watchlo][w-root] | `9a92b5b9ca44b079292f300afa9537b259bbc570` | GitHub license metadata is null; recursive tree exposes no LICENSE/COPYING file; inspected package.json has no license field; README has no license grant |

GPL repositories are references, not permissive copy/paste sources. Copying/adapting their implementation requires respecting GPL obligations. Watchlo's absent license is not permission to reuse its code. This evaluation proposes behavior and data-contract ideas, without importing implementation.

Bounded remote reads: **12 per repository**, counting metadata, commit lookup, tree, and each content fetch. Streambert/Watchlo: metadata + commit + tree + nine files. VortX: metadata + two commit lookups (SHA was lost in truncated initial output) + tree + eight files. Trees were reconnaissance reads of `main`; every selected file was fetched with the full pinned SHA. Re-reading locally captured tool output added no remote reads. VortX's large MPV controller was examined through line-numbered seek/pause/header-related excerpts; other selected files were returned in full. This is a targeted evaluation, not a whole-repository audit.

### Selected file inventory

- **Streambert:** README.md, LICENSE, package.json, `src/ipc/player.js`, `src/ipc/allmanga.js`, `src/ipc/subtitles.js`, `src/utils/playerGamepadScript.js`, `src/pages/TVPage.jsx`, `src/utils/useAutoplay.js`.
- **VortX:** README.md, LICENSE, `app/Sources/Player/PlayerEngine.swift`, `StreamRequestHeaderPolicy.swift`, `SubtitleTimingScope.swift`, `MPVMetalViewController.swift`; `app/SourcesShared/JSProviders/JSProviderStreamMapping.swift`; `app/SourcesShared/ManualEpisodeNavigationPolicy.swift`.
- **Watchlo:** README.md, package.json, `app/api/animestream/route.ts`, `app/api/subtitles/route.ts`, `app/api/subtitle-id/route.ts`, `app/components/media/Embeded.tsx`, `app/components/watch/anime/AnimeScreeningDeck.tsx`, `app/components/watch/episodes/EpisodesComponent.tsx`, `app/data/watchlo-source.json`.

## 1. Streambert

### Extraction versus player hosting

- [AllManga resolver][s-allmanga] is actual extraction logic: GraphQL POST to `api.allanime.day`, parsing/decryption of episode source records, decoding provider URLs, resolving clock JSON and redirects, then returning a selected direct URL. See lines 100–167, 300–330, 540–641.
- Returned object includes `url`, `resolution`, `sourceName`, `isDirectMp4`, and `referer`. It prefers non-HLS links when available, then sorts resolution strings numerically. This is selection of one source, not a full adaptive-quality source model.
- Anime season resolution uses AniList relations plus hardcoded show/split-season mappings. Useful warning for Veil: TMDB season/episode numbers are not universally interchangeable with anime provider numbering.
- [TVPage][s-tv] consumes `onM3u8Found`, stores intercepted subtitle information, and renders an Electron `<webview>` (around lines 803 and 2057). This demonstrates an interception consumer, **not verification of the underlying general movie/TV request interceptor**: `index.js` was outside the file budget.
- AllManga direct playback still uses a local Node HTTP server serving HTML `<video>`/hls.js, not an embedded native libmpv controller. [player.js][s-player] also launches external mpv/VLC for validated local files and timestamps; that is not an in-process mobile playback API.

### Seek, pause, headers, dependencies

- [Gamepad script][s-gamepad], lines 35–45, clamps `video.currentTime` and calls `video.play()`/`pause()` directly. TVPage also injects seek scripts and polls progress across webview frames. Useful interaction semantics; wrong transport layer to adopt for Flutter-native controls.
- Local `/proxy` sends Referer, User-Agent and **the current downstream Range**, preserving upstream status plus Content-Range/Accept-Ranges (AllManga lines 702–740). Retain that Range behavior if Veil ever needs a media relay. Do not freeze a captured first-request Range into every native seek.
- Inspected AllManga resolver/proxy does not expose browser-session cookies or a general request-header map in its returned source object. Film/TV cookie capture remains unverified. A URL plus Referer does not prove standalone native playback.
- Electron + React/Vite + Node HTTP/crypto/filesystem are platform assumptions. AllManga and AniList are external services; a YouTube fallback spawns installed `yt-dlp`, while local file tools optionally use mpv/VLC/ffprobe. Its yt-dlp branch selects the first output URL even when separate audio/video URLs are returned (lines 270–296), so it is not a complete multi-track resolver template.

### Subtitles, quality, episodes

- [Subtitle IPC][s-subs], lines 113–275, searches SubDL when configured, then Wyzie; includes title/season/episode/language filters and normalized release, hearing-impaired, AI-translation, and provider fields. ZIP extraction accepts SRT/VTT/ASS/SSA and caps decompressed output at 10 MiB.
- Good idea: expose provenance and release match, not just language. Caveat: several normalized fields are defaults (`ratings: 0`, `fps: null`, `from_trusted: false`); these do not prove subtitle quality. “First subtitle in ZIP” also does not establish correct episode/release matching.
- [Autoplay hook][s-autoplay] implements enable/disable, cancellation, configurable countdown, immediate “play now,” unreleased-episode guard, and a zero-duration manual-only overlay. Useful UI reference. It does not supply VortX-style session/source ownership guarantees.

**Fit:** selectively study anime extraction and subtitle discovery. Do not adopt Electron player/proxy architecture merely to gain native seek/pause controls.

## 2. VortX

### Source architecture and dependency boundary

- Primary product model is bring-your-own Stremio/add-ons and resolved direct/debrid links, with torrent/server paths. This is not equivalent to extracting Veil's existing embed providers.
- Actual [JSProviderStreamMapping][v-mapping] accepts provider-produced HTTP(S) URLs, maps headers into `behaviorHints.proxyHeaders.request`, stamps `jsplugin:<id>` provenance, and groups provider results. It caps results at 80/provider. It is a **normalizer after resolution**, not evidence that arbitrary provider extraction is bundled or working.
- Quality, release title, and size are folded into display text for downstream ranking. Veil should retain typed fields rather than making display-string parsing its primary source contract.
- Important code/comment mismatch: mapping comments mention provider `subtitles`, but constructed JSON at lines 63–76 contains URL/name/description/provenance/header hints only. **Subtitle propagation is not implemented in this mapper.** Do not infer it from the advertised input shape.
- [PlayerEngine][v-engine] provides an engine abstraction; inspected MPV controller uses native libmpv. Tree also contains AVPlayer/remux components, Android Kotlin/mpv code, and desktop Tauri code, but those implementations were not audited here.
- [README build section][v-readme] explicitly says the engine lives in a private repository and a complete source build requires maintainer access. It also describes separately fetched proprietary `server.js`, nodejs-mobile for applicable torrent/header-proxy builds, MPVKit, Swift/SwiftUI, and Rust/C bridging. Earlier README language claiming full source availability conflicts with that build section. Treat this as a public app/policy reference with an unavailable full engine dependency, not a self-contained open backend.
- README reports Android beta and desktop work in progress; tree confirms platform source presence, not release parity or measured performance. Current repository description saying Android is “next” is not sufficient status evidence.

### Strongest native seek/pause ideas

From [MPVMetalViewController][v-mpv], especially lines 3072–3277 and 4381–4400:

1. **User intent survives recovery.** Play/pause updates recovery transport intent; internal forced pauses must not overwrite what the viewer requested. Restoring a source/seek restores the latest intent, not an old “was playing” snapshot.
2. **Explicit seek supersedes maintenance.** Manual seeks cancel cache-reanchor and older EOF recovery before issuing the new command, preventing old recovery targets from pulling playback backward.
3. **Separate manual scrub from saved resume.** Both may seek to an absolute position, but saved resume does not automatically inherit manual-scrub cache-hold behavior.
4. **Distinguish cached and uncached jumps.** tvOS code checks target against a conservative buffered window before arming a cache hold. This is evidence of conditional recovery logic, not proof of faster seeking. Its buffer margins/timeouts are engine-specific, not universal tuning values.
5. **Separate command acceptance from settlement.** Owner/load tokens and seek generations gate recovery; position/restart evidence determines whether recovery settled. Paused exact recovery uses `absolute+exact`; ordinary scrubs use `absolute`. A paused seek must publish position without briefly playing.
6. **Do not let stale EOF advance episodes.** Source/load provenance matters when old events arrive after replacement. A failed correction is emitted as a source error, not successful completion.

For Veil, these concepts matter more than transplanting a particular mpv option or timeout.

### Headers and cookies

- [StreamRequestHeaderPolicy][v-headers], lines 4–24, explicitly strips `Range`, Host, Content-Length, connection/proxy transport headers and invalid field names/values. Native engine owns byte ranges. Origin identity headers such as Cookie, Authorization, Referer, Origin and User-Agent can survive this filter when valid.
- Provider mapping bounds header count/value sizes and excludes transport fields, but its own deny list omits Range; the later stream-header policy is therefore important.
- This is header forwarding/sanitation, **not browser cookie acquisition or a domain/path/expiry-aware cookie jar**. No inspected code proves export of WebView HttpOnly cookies or per-redirect cookie scoping. Those remain Veil resolver responsibilities.

### Subtitle and episode correctness

- [SubtitleTimingScope][v-subscope] scopes offsets to content identity **and release fingerprint**, rejecting empty/unknown identity. Avoid applying one release's offset to a different cut or episode.
- MPV excerpts expose subtitle track language/forced state, external subtitle fetching with bounded HTTPS transport, and `sub-delay` adjustment (lines 3564–3585, 3783–3817, 3833–3851). This supports native subtitle control ideas; no subtitle legibility/sync benchmark was performed. Renderer and full add-on matching logic were outside scope.
- [ManualEpisodeNavigationPolicy][v-episodes] resolves exact episode ID first, falls back to season/episode, waits for pending inventory, and only consumes a navigation intent belonging to the same session, episode generation, source generation and load owner. Adjacent **inventory** entries replace naive `episode + 1`; inventory ordering still must be correct upstream.

**Fit:** highest-value native-control and source-contract reference. Independently implement selected policies in Veil's current engine; do not depend on VortX's private engine or assume its Stremio/debrid pipeline solves embed extraction.

## 3. Watchlo

### Movie/TV embeds versus anime sources

- [Embeded.tsx][w-embed], lines 23–69 and 170–179, builds provider-specific movie/TV URLs and renders an iframe. Selection persists in localStorage. [Provider JSON][w-sources] is an embed directory, not a set of direct playable manifests. Labels like “Fast HD” or “1080p” are not probed quality/performance evidence.
- [Anime stream route][w-stream] calls external AnimeService V1/V2 services, tries provider/watch-ID fallbacks, then normalizes `sources`/`streams`. Actual upstream extraction implementation is outside this inspected repository path.
- HLS links are rewritten through configured external `${WATCHLO_API_V2}/proxy/hls`; MP4 is left direct. Referer comes from upstream `data.headers.Referer` or a default. This demonstrates reliance on backend relay behavior, not an on-device Flutter extractor.
- Dependencies: Next.js server routes, React UI, configured upstream anime/TMDB APIs and credentials. [package.json][w-package] specifies Node `24.x`, despite README's older minimum; Vidstack/hls.js are web-player dependencies, not native Flutter engines.

### Controls, quality, subtitles, episodes

- [AnimeScreeningDeck][w-controls] exposes ±10-second seek callbacks, speed, quality, captions/off, previous/next, auto-next, PiP and intro-skip controls. Previous/next are disabled using episode bounds. These are concrete component callbacks, **not proof of how the owning player settles seek/pause**; the anime watch page was outside the read budget.
- Stream route standardizes subtitle `url`/`file`, labels and defaults, and strips an HLS `&subs=` parameter when explicit subtitle tracks exist to avoid double rendering. Useful normalization intent; query-string surgery is provider-specific.
- Missing source quality defaults to `auto` for HLS or `720p` for non-HLS. That MP4 label is assumed, not measured; Veil should show unknown quality unless source/manifest evidence supplies it.
- [Subtitle relay][w-subs] fetches using Referer and User-Agent, then returns all text as `text/vtt`. It does not convert SRT/ASS or prove content format. It also does not forward a session cookie map.
- [Indonesian translation route][w-translation] parses cue blocks, preserves timing headers, strips most styling, translates batches through `clients5.google.com`, and falls back to original text on translation failure. Useful lesson: label machine-generated tracks; language label alone does not guarantee translated content or alignment. Not evidence of higher subtitle quality.
- [Episode grid][w-episodes] accepts episode inventory and selection callback and displays current season/episode. More readable discovery/navigation UI than an opaque iframe alone, but no inspected session/source ownership or cross-season completion logic.

**Fit:** secondary UI/normalization reference. Low fit for general native extraction; unknown reuse rights and external backend dependence make it unsuitable as a direct implementation base.

## Concrete implications for Veil's current working tree

Local context read: `lib/src/features/native_player/models/resolved_stream.dart`, `utils/playback_intent.dart`, native-player/resolver/subtitle call sites, plus embedded playback target/direct-player files. Native-player files are existing uncommitted work in this checkout.

- Veil already has `ResolvedStream(url, format, headers, resolvedAt, masterUrl, provider, qualities, subtitles)`, native `VideoPlayerController` header handoff, and separate resolver/player boundaries. Build on that rather than replacing it with an Electron or Next.js app.
- Current `PlaybackIntent` already coalesces seek targets, accumulates skips against the displayed pending target, sends pause immediately while a seek is waiting, and reapplies latest play intent. **VortX's incremental contribution is explicit load/seek ownership and settled-position evidence**, not rediscovering intent serialization.
- Existing Cinesrc resolver captures request headers, Referer/User-Agent and CookieManager cookies. Existing subtitle repository only passes stream headers to same-origin subtitle URLs. Preserve that separation.

### Suggested source contract additions (design only)

| Area | Suggested fields/behavior |
|---|---|
| Identity | Stable content/episode ID, provider source ID, release fingerprint, source/load generation |
| Source kind | Explicit direct-HLS/direct-file/embed/add-on/torrent kind; never hand iframe URLs to native decoder |
| Validity | Resolution time, optional expiry, resolver refresh identity; URL alone is not permanent identity |
| Requests | Validated identity headers plus scoped cookie context; per-origin policy for manifest, segment, key, subtitle and redirect requests; engine-generated Range |
| Quality | Master URL, typed resolution/bitrate/codecs and rendition identity; unknown stays unknown; preserve HLS audio/subtitle groups |
| Subtitles | Stable track ID, language, format, forced/HI flags, provider/release match, machine-generated flag, scoped headers, content+release-specific offset |
| Capability | Seekability, live/VOD, available quality/audio/subtitle controls and fallback reason |

### Priority native-control ideas

1. Keep ±10-second and scrub-preview feedback local; coalesce repeated seeks and preserve latest pause intent through quality switch, resolver refresh, and recovery.
2. Fence asynchronous seek/source/subtitle/episode results by source generation and load owner. Ignore stale completion/EOF from replaced sources.
3. Preserve headers/cookie scope throughout playback and quality changes, but let native HTTP transport choose fresh byte ranges. Validate manifest, segment, key and subtitle requests separately; a successfully fetched master alone is insufficient.
4. Keep “Auto” tied to master playback. Quality selection should preserve position and latest pause intent and retain a usable previous source on failure; avoid claiming a label proves resolution.
5. Use release-aware subtitle selection and adjustable offset. Keep external, embedded and segmented subtitle capabilities explicit; current local subtitle repository reports segmented subtitles as embedded-player-only.
6. Resolve previous/next through accepted episode inventory; cancel pending auto-next on manual navigation/source replacement and distinguish true completion from seek/recovery errors. Streambert's cancellable countdown complements VortX's ownership policy.

Validation to perform later, not performed here: input-to-command and input-to-observed-state timing; pause during pending seek; repeated skip accumulation; seek while paused; quality switch while paused; stale EOF after episode replacement; Range/206 behavior; cookie-gated manifests/segments; expired URL refresh; subtitle sync across releases. Record device, engine, source, buffered state and repeated-run percentiles before calling any option “lower latency.”

## Pinned source links

[s-root]: https://github.com/truelockmc/streambert/tree/4afe564e5ea2565c96d6f2e61679c00fad2d498c
[s-license]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/LICENSE
[s-allmanga]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/ipc/allmanga.js
[s-tv]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/pages/TVPage.jsx
[s-player]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/ipc/player.js
[s-gamepad]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/utils/playerGamepadScript.js
[s-subs]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/ipc/subtitles.js
[s-autoplay]: https://github.com/truelockmc/streambert/blob/4afe564e5ea2565c96d6f2e61679c00fad2d498c/src/utils/useAutoplay.js
[v-root]: https://github.com/VortXTV/VortX/tree/7b3d0d7204f423fe0dd7119d14e80e561c838c6b
[v-license]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/LICENSE
[v-readme]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/README.md#building-it-yourself
[v-mapping]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/SourcesShared/JSProviders/JSProviderStreamMapping.swift
[v-engine]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/Sources/Player/PlayerEngine.swift
[v-mpv]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/Sources/Player/MPVMetalViewController.swift#L3072-L3277
[v-headers]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/Sources/Player/StreamRequestHeaderPolicy.swift
[v-subscope]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/Sources/Player/SubtitleTimingScope.swift
[v-episodes]: https://github.com/VortXTV/VortX/blob/7b3d0d7204f423fe0dd7119d14e80e561c838c6b/app/SourcesShared/ManualEpisodeNavigationPolicy.swift
[w-root]: https://github.com/alfaruqii/watchlo/tree/9a92b5b9ca44b079292f300afa9537b259bbc570
[w-embed]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/components/media/Embeded.tsx
[w-sources]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/data/watchlo-source.json
[w-stream]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/api/animestream/route.ts
[w-package]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/package.json
[w-controls]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/components/watch/anime/AnimeScreeningDeck.tsx
[w-subs]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/api/subtitles/route.ts
[w-translation]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/api/subtitle-id/route.ts
[w-episodes]: https://github.com/alfaruqii/watchlo/blob/9a92b5b9ca44b079292f300afa9537b259bbc570/app/components/watch/episodes/EpisodesComponent.tsx
