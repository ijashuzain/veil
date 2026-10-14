# MoviePlex streaming-source evaluation for Veil

## 1. What does MoviePlex actually use, and are direct streams available?

### Takeaway

MoviePlex is **an aggregation/player frontend with a restricted resolver/proxy backend plus an alternate iframe player**, not merely a CineSrc iframe skin. Its shipped code supports HLS and MP4, but this check obtained **no playable MoviePlex source response, manifest, segment, subtitle file, or native playback result**. Configured providers and source-name heuristics are static evidence, not proof that those upstreams currently serve this title. [Watch page](https://movieplex.online/watch/movie/1058424), [application bundle](https://movieplex.online/assets/index-CMIFxJKg.js), [watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js), [resolver endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en).

### Cited Findings

**Fresh-check scope and provenance**

- Session date: 2026-10-14 local environment; the captured API response carried `Date: Tue, 13 Oct 2026 20:25:23 GMT`. Checks used anonymous public HTTP reads and bounded inspection of the two referenced first-party bundles. No user credentials, installations, application execution, challenge bypass, or media playback tests. The API result is a new HTTP observation; the device results in section 3 are inherited evidence. [HTTP endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en).
- The watch URL returns an HTML application shell, with `/assets/index-CMIFxJKg.js`; that bundle references `/assets/Watch-DeeiQPp_.js`. The shell includes advertising and analytics scripts, including `al5sm.com/tag.min.js`. These were observed as references, not executed. [HTML](https://movieplex.online/watch/movie/1058424).

**Observed frontend architecture**

```text
MoviePlex watch route (TMDB identity)
  ├─ TMDB title/season metadata + local watch/settings state
  ├─ default custom player
  │    └─ api.movieplex.online /api/stream
  │         └─ source descriptors → direct upstream URL OR MoviePlex proxy
  │              └─ HLS.js / browser-native HLS / HTML video MP4
  └─ alternate embed player
       └─ selected third-party iframe (VidCore, CineSrc, CineJoy, etc.)
```

This is the dependency structure inferred from shipped client calls and rendering branches, not a captured runtime network trace or an inspection of MoviePlex server code. [Application bundle](https://movieplex.online/assets/index-CMIFxJKg.js), [watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).

- The watch component initializes player mode to `custom`. Its alternate embed component creates an iframe using the selected provider; its default iframe provider is VidCore. An effect deletes `mode=embed` and resets custom mode, so that query parameter should not be treated as a reliable external integration contract. TV selection supports path season/episode and query aliases `s`/`season`, `e`/`episode`; navigation writes `/watch/tv/{id}/{season}/{episode}`. [Watch bundle, `vh`, `ph`, `mh`](https://movieplex.online/assets/Watch-DeeiQPp_.js).
- The custom player calls `https://api.movieplex.online/api/stream` with `tmdbId`, `type`, `lang`, and optionally `season`, `episode`, `title`, `year`, `imdbId`, `originalLanguage`, `fast=1`, or `bypassCache=1`. Its client expects fields including `success`, `sources`, `activeSource`, `subtitles`, `providersStatus`, and `resolvedInMs`. These are **internal shapes reconstructed from the public client**, not published API guarantees. [Application bundle, `gr`](https://movieplex.online/assets/index-CMIFxJKg.js), [watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).
- Source consumers use `id`, `providerId`/`provider`/`providerName`, `name`, `url`, `rawUrl`, `type`, `quality`, `headers`, `language`, `audio`, `isDirect`, and `requiresProxy`. Not every field is necessarily supplied by the backend. [Watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).

**Actual configured iframe destinations**

All entries below are verified URL constructors in the shipped bundle. None was played during this research. For this movie, substitute `1058424` for `{id}`. [Watch bundle, `mh`](https://movieplex.online/assets/Watch-DeeiQPp_.js).

| Displayed provider | Movie destination | Episode destination |
| --- | --- | --- |
| VidCore | `https://vidcore.io/movie/{id}` | `/tv/{id}/{season}/{episode}` |
| CineSrc Fast | `https://cinesrc.st/embed/movie/{id}` | `/embed/tv/{id}?season={season}&episode={episode}` |
| VidSpark Ultra | `https://vidspark.org/embed/movie/{id}` | `/embed/tv/{id}/{season}/{episode}` |
| VidUp High-Speed | `https://vidup.to/movie/{id}` | `/tv/{id}/{season}/{episode}` |
| CineJoy Edge | `https://cinejoy.to/watch/movie/{id}` | `/watch/tv/{id}/{season}/{episode}` |
| BingeBang Fast | `https://bingebang.tv/movie/play/{id}` | `/tv/play/{id}/{season}/{episode}` |
| VidLink | `https://vidlink.pro/movie/{id}` | `/tv/{id}/{season}/{episode}` |
| SuperEmbed | `https://multiembed.mov/?video_id={id}&tmdb=1` | Same URL plus `&s={season}&e={episode}` |
| VidSrc | `https://vidsrc.sbs/embed/movie/{id}` | `/embed/tv/{id}/{season}/{episode}` |
| VidFast | `https://vidfast.vc/movie/{id}` | `/tv/{id}/{season}/{episode}` |

- Important domain distinctions: MoviePlex names `cinejoy.to`, while Veil uses `cinejoy.pk`; MoviePlex's iframe list names `vidsrc.sbs`, while Veil uses `vsembed.ru`. This check does not establish ownership, equivalent infrastructure, or identical streams across those domains. [Watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js), [Veil URL builder](../../lib/src/features/detail/utils/playback_entry_url.dart).
- The direct-player naming/ranking code recognizes VidZee/NXOCW/Zenith, VidRock, CineJoy/Vanguard, VidSrc, Videasy/Filmu, KKPhim/PhimAPI, VixSrc/VixStream, RiveStream/Borealis/Bingr, and others. It also includes CineSrc, VidLink, VidFast and additional provider-name patterns. **Recognition is not proof of an active extractor or successful upstream response.** [Watch bundle, `Wu`, `Zu`, error-label substitutions](https://movieplex.online/assets/Watch-DeeiQPp_.js).
- Marketing names obscure source identity: `PlexMax` maps to VidZee/NXOCW; `IMAX Digital` to VidRock; `Dolby Premiere` to CineJoy/Vanguard; `Grand Theater` to VidSrc; `Multiplex Gold` to Videasy/Filmu; `Roxy Cinema` to CineSrc. These are UI aliases, not new independently verified CDNs. [Watch bundle, `Zu`](https://movieplex.online/assets/Watch-DeeiQPp_.js).

**Direct-media availability and metadata**

| Capability | Fresh static evidence | Fresh runtime evidence |
| --- | --- | --- |
| HLS | HLS.js `loadSource`/`attachMedia`, manifest levels, audio/subtitle tracks, and browser `application/vnd.apple.mpegurl` fallback | No manifest or segment obtained |
| MP4 | Explicit MP4 branch assigning HTML video source; source menu differentiates MP4/HLS | No MP4 URL or range response obtained |
| DASH | No application DASH/MPD playback branch identified in inspected watch code | No MPD obtained; cannot claim support |
| External subtitles | `/api/stream/subtitles`; expected `id`, `label`, `language`, `url`; mapped to VTT tracks | No subtitle response/file obtained |
| HLS subtitles/audio | Reads HLS subtitle tracks and audio tracks, including names/languages and track indices | No track list verified for target |
| Quality | Reads HLS levels and dimensions, but also infers quality from labels/provider/URL | No decoded dimensions or real target renditions verified |
| Episodes | TMDB metadata, season episode lists, explicit episode keys, next-episode/season navigation | No episode playback tested |

Sources for table: [application bundle](https://movieplex.online/assets/index-CMIFxJKg.js), [watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).

- Quality is not trustworthy merely because the UI says 1080p/4K: `qu` defaults unknown sources to 1080; manifest-level handling supplies inferred dimensions for a single level without a height; 2160 selection includes an explicit fallback toast mentioning a `1080p FHD Master` while keeping a 2160 preference. The code also uses broad width/height buckets for labels. Verify manifest attributes and decoded dimensions rather than borrowing these labels. [Watch bundle, `qu`, `Yu`, `MANIFEST_PARSED`, quality-selection handler](https://movieplex.online/assets/Watch-DeeiQPp_.js).
- Independent fresh metadata lookup for this exact TMDB ID returned `Hope`, year `2026`, IMDb `tt27369017`, quality `CAM`, and `status_code: 200`. **This is VidSrc's metadata assertion, not MoviePlex resolution or proof of successful playback.** [VidSrc target metadata](https://vsembed.ru/info/movie/1058424.json).

**Auth, sessions, proxying, and expiry**

- The frontend sends `Accept: application/json`, `x-client-app: movieplex`, and a literal `x-app-key` embedded in the public bundle. The key value is intentionally not copied here. The resolver fetch shown does not explicitly set `credentials: include` or send a user bearer token; this does not establish what the backend or upstream media requires. [Application bundle, `dr`, `gr`](https://movieplex.online/assets/index-CMIFxJKg.js).
- Anonymous GET to the observed resolver URL returned **HTTP 403**, `Content-Type: application/json; charset=utf-8`, body: `{"error":"Forbidden","message":"Access denied: MoviePlex API is restricted to authorized applications."}`. Response headers included `Access-Control-Allow-Credentials: true`, `Vary: Origin`, and exposed range/content headers. Those headers alone do not establish an allowed Veil origin or working CORS policy. No public client-key replay or origin spoofing was attempted after this denial. [Resolver endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en).
- The client constructs `/api/stream/proxy{extension}?url={encoded upstream URL}&referer={encoded referer}&audio={language}`; extensions include `.m3u8`, `.mp4`, `.m4s`, and `.ts`. The player routes sources requiring a Referer/proxy through that backend and includes proxy fallback on some HLS failures. A source marked `isDirect` can still depend on this relay. This is evidence of intended header/origin compatibility handling, not a verified working proxy. [Application bundle, `br`](https://movieplex.online/assets/index-CMIFxJKg.js), [watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).
- Client source-cache handling treats several provider patterns and URL markers (`token=`, `expires=`, `exp=`, `sig=`, `wmsauthsign=`, timestamp-like values) as short-lived. Watch cache thresholds include **7 minutes** for recognized sensitive sources and **30 minutes** otherwise; in-memory resolver caches include **30 seconds** fast / **25 minutes** full. These are cache policies, **not measured or contractual media expiry times**. [Watch bundle, `42e4`, `18e5`](https://movieplex.online/assets/Watch-DeeiQPp_.js), [application bundle, `gr`](https://movieplex.online/assets/index-CMIFxJKg.js).
- Preferences, source selections and watch progress are saved in localStorage, including movie/episode-specific keys. Browser state contributes to selection/resume behavior; there is no demonstrated portable MoviePlex session contract for native consumers. [Watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).

### Inferences

- Backend aggregation could offer sources beyond CineSrc and could remove client-side extraction work **if** a supported server-to-server/native API were supplied. Current evidence establishes frontend expectations, not backend coverage, service reliability, or permission to reuse the API. [Application bundle](https://movieplex.online/assets/index-CMIFxJKg.js), [403 endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en).
- Embedding the full watch page adds MoviePlex metadata loading, player logic and backend dependency; selecting CineSrc inside its iframe mode adds an outer frontend around the same CineSrc embed. There is no demonstrated startup/quality benefit from that additional layer. [Watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js).

### Gaps

- Actual provider chosen for `1058424`, upstream media hostname, playable URL, codecs, renditions, audio/subtitle inventory, DRM status, cookies, IP binding, required headers, refresh behavior, and expiry remain unknown: resolver denied anonymous access.
- No public MoviePlex integration documentation was identified in the inspected entry page/assets. No claim of site-wide documentation absence: no guessed-endpoint sweep or exhaustive search was performed.
- No browser/native playback, seek, first-frame, reliability, battery, or bandwidth benchmark was run. Server ranking constants, `latencyMs`, `resolvedInMs`, buffer configuration, and “Fast/Ultra” labels are not performance measurements.

## 2. How do the public integration contracts compare?

### Takeaway

CineSrc, VidSrc/vsembed, and VidLink publish useful **embed contracts**; none of the inspected documentation provides a general direct HLS/DASH/MP4 source API. VidSrc additionally documents content/availability metadata. CineJoy's inspected homepage is an application shell, not comparable developer documentation. [CineSrc docs](https://cinesrc.st/docs), [VidSrc docs](https://vsembed.ru/vidsrc/docs), [VidLink docs](https://vidlink.pro/), [CineJoy](https://cinejoy.pk/).

### Cited Findings

| Provider | Public entry contract | Metadata/control contract | Native-source contract found? |
| --- | --- | --- | --- |
| CineSrc | TMDB `/embed/movie/{id}`; `/embed/tv/{id}?s={season}&e={episode}` with long-form aliases | Quality preference; resume `t`/`time`; autoplay, autonext, autoskip, preferred server; documented events and commands | No direct-source endpoint in inspected docs. [Docs](https://cinesrc.st/docs) |
| CineJoy.pk | Fresh homepage is a Svelte application shell; Veil currently uses `/watch/movie/{id}` and `/watch/tv/{id}/{season}/{episode}` | No developer contract found in inspected homepage. Existing route usage is local integration evidence, not a provider guarantee | Not established. [Homepage](https://cinejoy.pk/), [Veil URL builder](../../lib/src/features/detail/utils/playback_entry_url.dart) |
| VidSrc / vsembed.ru | IMDb or TMDB `/embed/movie/{id}`; TV path forms including `/embed/tv/{id}/{season}/{episode}` and whole-series picker | Documented subtitles, progress events, resume; JSON content info, quality/episode metadata and catalog feeds | Metadata returns embed URLs, not playable media URLs. [Docs](https://vsembed.ru/vidsrc/docs) |
| VidLink | TMDB `/movie/{id}` and `/tv/{id}/{season}/{episode}`; separate MAL anime route | `startAt`, `player=jw`, custom VTT subtitle, next button, failure redirect, `MEDIA_DATA` and `PLAYER_EVENT` | No direct-source endpoint in inspected docs. [Docs](https://vidlink.pro/) |
| MoviePlex | Public watch route and shipped internal resolver calls | Internal source/subtitle objects and local UI state; no supported external contract identified | Restricted internal endpoint; anonymous request denied. [Bundle](https://movieplex.online/assets/index-CMIFxJKg.js), [endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en) |

- CineSrc documents `cinesrc:ready`, time/progress/seek events, `loadedmetadata`, `nextepisode`, `sourceused`, `error`, and a command/response bridge for play/pause/seek/volume/rate and getters. `sourceused` exposes a `sourceId`, not a media URL. `quality` is a preferred quality parameter; `febbox` is explicitly an authentication token for premium source access. This is a distinct optional source dependency, not evidence that normal embeds require a user account. [CineSrc docs](https://cinesrc.st/docs).
- VidSrc documents `ds_lang` priorities and external HTTPS VTT/SRT via `sub_url`, fetched in the viewer's browser with CORS requirements. `PLAYER_EVENT` reports `player_info`, `player_status`, progress and duration. Official domains retain a Play gate; no-click autoplay is documented for custom domains only. Its homepage announces `vidsrc.sh` as the current main embed domain; this research did not change Veil's domain. [VidSrc docs](https://vsembed.ru/vidsrc/docs), [homepage](https://vsembed.ru/).
- VidSrc `/info/movie/{id}.json`, `/info/tv/{id}.json`, and episode info document JSON 200/404 availability, quality labels, and show season/episode ranges with approximately five-minute caching. Only the target movie endpoint was freshly exercised here. A metadata 200 does not verify media authorization or decoding. [Docs](https://vsembed.ru/vidsrc/docs), [fresh target result](https://vsembed.ru/info/movie/1058424.json).
- VidLink supports `sub_file` as a direct VTT URL, `sub_label`, `fallback_url`, `startAt`, and optional JWPlayer. Docs warn that saved progress can take precedence over `startAt`. `MEDIA_DATA` includes watch history/episode progress; `PLAYER_EVENT` includes event/time/duration/title identity, and the published example spells the ID field `mtmdbId`. Validate actual runtime payload before relying on that spelling. [VidLink docs](https://vidlink.pro/).

### Inferences

- Documented embed events offer a more stable route to progress/error/episode synchronization than coupling Veil to another site's private UI internals. They still do not turn a provider into a supported native-stream API. [CineSrc](https://cinesrc.st/docs), [VidSrc](https://vsembed.ru/vidsrc/docs), [VidLink](https://vidlink.pro/).
- VidSrc's metadata API is a concrete candidate for availability/quality hints in Veil; keep hints distinct from successful playback and avoid treating title-level “best quality” as guaranteed episode/rendition quality. [VidSrc docs](https://vsembed.ru/vidsrc/docs).

### Gaps

- CineJoy documentation and its internal source architecture were not deeply investigated; this bounded comparison does not conclude that CineJoy lacks a direct resolver.
- No fresh playback of CineSrc, CineJoy, VidSrc, or VidLink was performed. Documentation claims about speed, coverage, quality and source count were not independently validated.
- Context7 lookup for CineSrc returned no matching library; provider-owned pages were used directly instead.

## 3. Should Veil replace CineSrc, and what architecture follows from this evidence?

### Takeaway

**Do not replace CineSrc with MoviePlex on this evidence.** MoviePlex offers potentially useful aggregation but no verified, supported native-source improvement. Preserve the existing native resolver/fallback boundary; consider MoviePlex only if its operator supplies an authorized, versioned API contract and a bounded playback comparison demonstrates an actual gain. This recommendation weighs the fresh restricted-API observation against Veil's existing, explicitly limited native-playback evidence. [MoviePlex endpoint](https://api.movieplex.online/api/stream?tmdbId=1058424&type=movie&lang=en), [prior Server 5 report](../../docs/playback/server-five-native.md).

### Cited Findings

**Current local architecture — fresh source inspection, not fresh playback**

- Veil maps Server 1 to VidSrc/vsembed, Server 2 to CineJoy, Server 3 to CineSrc embed, Server 4 to VidLink, and Server 5 to native playback resolved through CineSrc. [Playback target](../../lib/src/features/embeded_player/utils/playback_target.dart).
- `CineSrcStreamResolver` accepts only HTTPS `cinesrc.st`, creates a temporary headless WebView, captures a usable HLS playlist, chooses a conservative rendition, copies captured headers plus Referer/User-Agent and destination cookies, then disposes the WebView. Swapping the entry URL to MoviePlex would fail the explicit host check and would not constitute an implemented MoviePlex resolver. [Resolver](../../lib/src/features/native_player/repository/cinesrc_stream_resolver.dart).
- `ResolvedStream` carries URL, format, headers and resolution timestamp; its format enum has HLS and MP4, but the inspected CineSrc resolver produces HLS. It has no subtitle/audio-track inventory, explicit expiry, or DASH format. Those capabilities would need deliberate model/player work if a new provider genuinely supplies them. [Stream model](../../lib/src/features/native_player/models/resolved_stream.dart), [resolver](../../lib/src/features/native_player/repository/cinesrc_stream_resolver.dart).

**Prior verified evidence — not rerun in this research**

- The 2026-10-13 live audit reports Server 1/2/3 passing all seven tested titles after fixes in the iPhone 17 Pro / iOS 26.5 simulator. Server 4 was variable: denied media responses, unavailable titles, and changing DASH/MP4 selection. These results belong to that earlier environment/test matrix, not this MoviePlex check. [Prior audit, matrix and root causes](../../docs/playback/live-audit-2026-10-13.md).
- The Server 5 report records advancing native video **after resolver disposal** for all seven titles, with seek/resume passing six and Game of Thrones S2E3 stalling in that run. It explicitly calls the implementation a beta browser-assisted resolver, not a stable source API; subtitles/advanced quality/audio selection and physical-device/other-network validation remain gaps. [Prior native report](../../docs/playback/server-five-native.md).
- Earlier first-frame observations are not a MoviePlex comparison. The audit itself cautions about one-network measurements, interaction delay and provider/cache variability. No new speed ranking is justified here. [Prior timing caveats](../../docs/playback/live-audit-2026-10-13.md).

### Inferences

**Recommended integration decision**

1. **Keep CineSrc Server 5 and its explicit embedded fallback.** Existing native handoff has prior observational evidence; MoviePlex has no equivalent result here. This is an evidence-based default, not a guarantee of future CineSrc reliability. [Prior native report](../../docs/playback/server-five-native.md).
2. **Do not insert the MoviePlex watch page as a transparent CineSrc replacement.** Its custom mode introduces another resolver/proxy dependency; its CineSrc iframe option wraps an already-integrated endpoint. Added provider breadth is plausible, but no improvement in available content, quality, startup, seeking or native compatibility was established. [Watch bundle](https://movieplex.online/assets/Watch-DeeiQPp_.js), [CineSrc docs](https://cinesrc.st/docs).
3. **If supported MoviePlex access becomes available, use a separate resolver adapter.** Proposed boundary: `PlaybackRequest → provider resolver → validated stream descriptor → native player`, with provider-specific embedded fallback. Request a contract for playable URLs, per-resource headers/cookies, expiry/refresh, proxy/segment semantics, subtitle/audio metadata, codecs/renditions, error codes, rate limits and supported clients. This is a proposed design, not an implemented or promised MoviePlex capability. [Existing resolver interface](../../lib/src/features/native_player/models/resolved_stream.dart), [observed internal source expectations](https://movieplex.online/assets/Watch-DeeiQPp_.js).
4. **Retain original upstream identity in any adapter.** Avoid presenting MoviePlex's cinema-themed aliases as independent sources, or repeatedly falling back to CineSrc through different wrappers. Track actual provider and source family when known. [Alias map](https://movieplex.online/assets/Watch-DeeiQPp_.js).
5. **Require a small, comparable native test before adopting.** Demonstrate manifest/segment or MP4 range success, actual decoded video, seek/resume after resolver disposal, required-header propagation across child requests, and behavior after source expiry. Compare matching titles/episodes on the same device/network, with separate resolution and first-frame timing; verify subtitles and quality from actual tracks/dimensions. These are missing acceptance evidence, not claims of present capability. [Prior native limitations](../../docs/playback/server-five-native.md), [MoviePlex implementation](https://movieplex.online/assets/Watch-DeeiQPp_.js).

### Gaps

- **Native MoviePlex handoff: NOT VERIFIED.** No AVPlayer/ExoPlayer initialization, browser-to-native handoff, advancing frames, seeking, subtitle rendering or expiry test occurred.
- **Direct MoviePlex HLS/MP4 availability for Hope: NOT VERIFIED.** Static support exists, but the anonymous resolver response was forbidden. DASH support was not established.
- **Improvement over CineSrc: NOT DEMONSTRATED.** MoviePlex is more than an iframe wrapper in implementation, but that alone establishes neither better sources nor a usable replacement contract.
- Existing application changes were present before research. This task adds only this note; no app code, provider settings, credentials, or runtime behavior was changed.
