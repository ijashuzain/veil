# Resolver reuse evaluation: Streamgrabber and CinePro Core

**Reviewed 2026-10-14. Recommendation: retain Veil’s browser-assisted CineSrc → native playback path; investigate Streamgrabber’s small MIT VaPlayer HTTP adapter as a separate fallback. Do not adopt CinePro Core as Server5’s production dependency.** Neither repository proves a browser-free CineSrc resolver or fixes native startup/seek behavior.

## Scope and evidence

- Read-only app inspection. GitHub access through `gh api`: metadata, commit heads, recursive trees, README, LICENSE, selected implementation files, recent commits, and relevant issues. No clones, installs, execution of repository code, upstream stream requests, or live playback tests.
- Bounded reads: **12 files Streamgrabber; 15 files CinePro**, including README/license/configuration. Both recursive trees reported `truncated: false`. Provider coverage below distinguishes inspected implementations from directory inventory.
- **Verified** means visible in pinned code, not operationally verified. README samples, issue reports, and maintenance announcements are attributed claims. No research delegation tool was available; inspection performed directly.

| Repository | Pinned main commit | Maintenance snapshot |
|---|---|---|
| Enki013/streamgrabber | [`673f3048c86f3a434fed59897ee324a564cbd342`](https://github.com/Enki013/streamgrabber/commit/673f3048c86f3a434fed59897ee324a564cbd342) | 2026-10-13, version 0.1.1. Recent dependency-error handling fix; preceding commits mostly initial implementation/docs. 6 stars, 2 forks, 0 open issues in metadata. Small, young project; recent packaging activity does not prove current extraction health. |
| cinepro-org/core | [`98ba005f75d2675877774f5a676b3bc1c4150c27`](https://github.com/cinepro-org/core/commit/98ba005f75d2675877774f5a676b3bc1c4150c27) | 2026-05-27. 181 stars, 167 forks; metadata’s 4 open items include one PR. Not archived, but main is months old. Maintainers explicitly disclaim working functionality during rewrite. |

## 1. Streamgrabber

### License and runtime

Actual [LICENSE, lines 1–21](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/LICENSE#L1-L21): **MIT**, copyright **2026 Enki013**. Grants use, copying, modification, distribution, sublicensing and sale; requires copyright and permission notice in copies/substantial portions; standard “AS IS” disclaimer. Suitable license for adapting code into Veil while retaining notice.

Python ≥3.11 CLI, not Flutter library or HTTP service. Dependencies include Playwright, m3u8, ffsubsync, Rich and Typer; CLI entrypoint is `streamgrabber.cli:app` ([package definition](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/pyproject.toml#L1-L44)). Download/mux execution uses external streamlink/yt-dlp/ffmpeg. These dependencies need not accompany a Dart port of the small HTTP extraction logic.

### Actual coverage and extraction

**Provider-specific coverage: StreamIMDb/VaPlayer, movies and TV episodes.** IMDb URLs/IDs normalize to `streamimdb.ru/embed/{movie|tv}/{id}` using IMDb suggestion metadata; metadata failure falls back to movie. This is not a general multi-provider catalog ([resolver](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/resolver.py#L18-L68)).

Two distinct paths:

1. **HTTP-only VaPlayer path:** `GET https://streamdata.vaplayer.ru/api.php?{imdb|tmdb}=ID&type={movie|tv}`, with `season` and `episode` for selected TV episodes. IDs starting `tt` use IMDb; others use TMDB. Sends desktop User-Agent, `Referer: https://nextgencloudfabric.com/`, and matching Origin. Uses Python `urlopen`, no browser ([implementation](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/vaplayer.py#L12-L80)). CLI chooses this path for episode options **or any URL containing `/embed/movie/`**, without validating provider host at that dispatch point ([CLI](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L118-L124)). Do not interpret this as support for every movie embed site.
2. **Generic browser sniffing:** Playwright Chromium watches request URLs and response MIME types for HLS, DASH, VTT and SRT, clicks play candidates across frames, and records request/response headers. It closes browser after capture ([detector](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/detector.py#L97-L163)). CLI retries with visible browser if headless capture fails. Although detector recognizes DASH, normal CLI selects **only HLS**, then errors without it ([CLI](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L380-L427)). Generic sniffing is not verified provider coverage; no CineSrc-specific implementation found.

### Stream contract, headers, subtitles, quality, expiry

**No server endpoint.** These are upstream fields consumed by Python and CLI output, not an existing stable Veil-ready HTTP API.

VaPlayer response shape inferred directly from parser:

```text
{
  data: {
    season, episode, title, file_name,
    stream_urls: string[],
    eps: { seasonString: episodeString[] }
  },
  default_subs: [{ url, code?, lang?, ... }]
}
```

`default_subs` is top-level, not inside `data`. Stream URLs lack per-source type, headers, numeric quality, or expiry metadata in this parser. Default subtitle selection uses `code`/`lang`, downloads `url`, and converts SRT text to WebVTT ([subtitle handling](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/subtitles.py#L312-L341)).

- **CLI JSON:** movie `--list` emits `{title,media_id,media_type,stream_urls,output}`; episode listing emits `{title,season,episode,stream_urls,output}`. Neither exposes default subtitles or headers ([movie](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L148-L165), [episode](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L219-L233)). Browser-mode summary emits `{page_url,hls,referer,user_agent,variants,selected,subtitles,page_title,output}`; subtitles are bare URLs. Rich progress messages mean stdout is not a clean API transport.
- **Headers:** internal `Capture` retains header maps ([model](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/models.py#L13-L37)), but downstream download commands preserve **User-Agent and Referer only**, not arbitrary Cookie/Origin/Authorization ([commands](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/downloader.py#L12-L54)). “Preserved browser headers” is therefore narrower than full session replay.
- **Quality:** HLS variants expose `{index,bandwidth,resolution,height,url}`; relative URLs resolved against master. Default selects highest height/bandwidth, with no codec compatibility or alternate-audio protection ([manifest](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/manifest.py#L14-L55)). Veil’s existing master-preserving/AVC-conservative logic is better suited to native startup.
- **Expiry:** no `expiresAt`/TTL parsing. TV retry callbacks re-fetch episode URLs before subsequent download attempts; movie path does not provide that callback ([TV refresh](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L183-L205), [retry consumption](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/cli.py#L264-L275)). Browser capture has no equivalent freshness contract.
- **Subtitles:** release-name scoring and SRT→VTT conversion are portable ideas. OpenSubtitles search and ffsubsync are separate external/download workflows, not proof of instant native subtitle support ([scoring](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/src/streamgrabber/subtitles.py#L183-L237)).

### Fit and limitations

**Mobile:** port only VaPlayer request/response mapping and useful pure helpers. It can accept Veil’s TMDB IDs directly, but endpoint availability, device-network restrictions, URL transferability, codecs and segment/key/header behavior remain untested. Add it as a distinct provider; it does not resolve CineSrc’s existing embed URL.

**Backend:** small HTTP adapter is feasible; full CLI requires browser/process orchestration and an API wrapper. Chromium fallback is heavier and duplicates Veil’s already browser-assisted approach.

Other limitations: first stream selected via `[0]` with no robust empty-list guard/failover; hardcoded provider domains and referer; no DRM license contract. README’s working sample and “39 passed” are upstream claims, not tests run here. Inspected [VaPlayer tests](https://github.com/Enki013/streamgrabber/blob/673f3048c86f3a434fed59897ee324a564cbd342/tests/test_vaplayer.py#L1-L32) cover URL construction/naming, not live extraction.

## 2. CinePro Core

### Actual license: commercial reuse blocker

GitHub metadata says **NOASSERTION**, but actual [LICENSE](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/LICENSE#L1-L44) is **PolyForm Noncommercial License 1.0.0**. It grants distribution and derivative-work permissions only for permitted purposes. Notices must include terms or their URL and supplied Required Notices; text contains `Required Notice: Copyright CinePro Foundation (https://github.com/cinepro-org)`.

The [permitted-purpose clauses](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/LICENSE#L52-L71) permit noncommercial purposes and specified personal/noncommercial-organization uses; personal uses explicitly exclude anticipated commercial application. **Do not treat this as MIT or permission to copy/port/host it for monetized Veil. A backend deployment does not remove this restriction.** Separate permission would be needed for commercial reuse outside the grant. Architecture observations remain useful without incorporating this implementation.

### Coverage: inventory versus inspected behavior

[Pinned provider directory](https://github.com/cinepro-org/core/tree/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers) has **17 directories**: `02moviedownloader`, `anyembed`, `cinesu`, `fmovies4u`, `fshare`, `icefy`, `peachify`, `popr`, `streammafia`, `tulnex`, `vidapi`, `videasy`, `vidnest`, `vidrock`, `vidsrc`, `vidzee`, `vixsrc`. Directory presence is not proof all are enabled or functional. `cinesu` is not Veil’s `cinesrc.st`; no CineSrc directory exists. README’s **“50+ unique sources”** is a marketing claim, not 50 verified providers.

| Inspected provider | Verified implementation | Important limit |
|---|---|---|
| VixSrc | Enabled; movie/TV TMDB API → embed HTML → tokenized HLS master; HTTP fetch only. | Rejects tokens within 60 seconds of expiry. Returns proxied master with best-height label. Subtitle extraction explicitly commented out. [Code](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vixsrc/vixsrc.ts#L146-L269), [subtitle TODO](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vixsrc/vixsrc.ts#L300-L327). |
| VidSrc | Enabled; TMDB movie/TV → three HTML hops → regex `file` extraction/domain substitution → proxied HLS. | Static host substitutions, Auto quality, no subtitles. VPN blocking is provider’s diagnostic claim, not tested here. [Code](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vidsrc/vidsrc.ts#L42-L124), [extraction](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vidsrc/vidsrc.ts#L195-L243). |
| Videasy | Enabled; six configured servers: cuevana, mb-flix, 1movies, cdn, superflix, lamovie. Parallel HTTP fetches; movie/TV metadata parameters. | Depends on external `enc-dec.app/api/dec-videasy` for decryption. Other server entries commented out. No browser in inspected path. [Servers](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/videasy/videasy.ts#L18-L59), [mapping](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/videasy/videasy.ts#L133-L207), [external dependency](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/videasy/decryptor.ts#L6-L59). |
| VidRock | Enabled; encrypted movie/TV identifier, JSON endpoints, optional secondary CDN lookup, HLS/MP4 and separate subtitles endpoint. | Some quality hardcoded to `1080`; alternate path uses `referrer` spelling in headers. Encryption helper not inspected. [Sources](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vidrock/vidrock.ts#L55-L134), [subtitles/request](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/vidrock/vidrock.ts#L145-L215). |
| FshareTV | Enabled; **movies only**, IMDb page → watch page → source ID → JSON; combines primary/backups/alternatives and deduplicates URLs. | No TV/subtitles. `video/*` stripping is not strong media-type validation. [Capability](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/fshare/fshare.ts#L32-L78), [extraction/mapping](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/fshare/fshare.ts#L92-L184). |
| AnyEmbed | **Disabled**; session-token HTTP API and source/subtitle mapper remain. | Comments report 403/500 instability; declares TV but shown request only uses TMDB ID, no season/episode. [Code](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/anyembed/anyembed.ts#L15-L35), [request](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/anyembed/anyembed.ts#L106-L114). |
| 02MovieDownloader | **Disabled**; HTTP token/API and crypto code remain. | Explicit reason: Cloudflare Turnstile. No working browser challenge solver established. [Code](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/providers/02moviedownloader/02moviedownloader.ts#L18-L39). |

Remaining ten provider implementations were not read; do not infer their browser/session/crypto requirements from these samples.

### HTTP/JSON contract and native implications

Server delegates route handling, types, discovery and proxy construction to **`@omss/framework`**, declared `^1.1.19` ([package](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/package.json#L1-L24), [bootstrap](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/server.ts#L11-L82)). Framework implementation was not downloaded/read. Consequently **exact HTTP route table, outer JSON envelope, HTTP error statuses, proxy URL syntax and recursive segment/key rewriting remain unverified**. Issue #62 mentions `/v1/movies/329865`; that is a reporter’s reproduction path, not route-code verification.

Verified provider-level return shape, suitable as a design reference rather than a guaranteed wire contract:

```text
{
  sources: [{
    url: createProxyUrl(upstreamUrl, upstreamHeaders),
    type: "hls" | "mp4" | other provider-dependent strings,
    quality: string,
    audioTracks: [{ language, label }],
    provider: { id, name }
  }],
  subtitles: [{ url, label, format }],
  diagnostics: [{ code, message, field, severity }]
}
```

- **Headers:** inspected providers pass User-Agent/Referer/Origin or upstream headers into `createProxyUrl`; returned source objects generally do **not** carry a separate raw header map. Native clients cannot discard proxy URLs and assume naked CDN URLs work. Proxy unwrapping configuration exists, but executable behavior lives in framework ([patterns](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/thirdPartyProxies.ts#L40-L72)).
- **Subtitles:** separate arrays; language often represented only by label. Videasy forces VTT format; VixSrc, VidSrc and Fshare return no separate subtitle entries. Mapping needs format validation and language normalization.
- **Quality:** strings include Auto/unknown/1080/1080p and inferred values. Not equivalent to Veil’s `{height,bitrate,codecs,url}` rendition list. Read actual manifest rather than trusting labels.
- **Expiry:** inspected return objects omit explicit expiry. VixSrc checks upstream token expiration before returning, but server sets source cache TTL to **one hour** and subtitle TTL to **24 hours** ([configuration](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/src/server.ts#L21-L39)). Framework might add handling, but this was not verified. Videasy decryptor cache has no TTL and keys on TMDB ID plus first 32 blob characters. Neither proves safe URL lifetime across long playback/seeks.

**Backend fit exceeds mobile fit:** Node/TypeScript provider registry, TMDB enrichment, cache and header proxy are natural server concerns. Examined extraction paths use HTTP rather than bundled browser automation; this is not evidence all providers evade browser requirements. Direct Dart port would duplicate provider churn and inherit license restrictions. A functioning HTTP backend could return native-playable HLS/MP4, but no AVPlayer/ExoPlayer compatibility, cross-IP replay, Range handling, subtitle support or latency was measured.

### Maintenance changes the verdict

- Maintainer [status issue #68](https://github.com/cinepro-org/core/issues/68): “undergoing a rewrite. None of the functionalities are promised to work.” Follow-up [comment](https://github.com/cinepro-org/core/issues/68#issuecomment-5001960592) says larger reconstruction, no ETA, “should be back before November 2026.” This is a forecast, not a completed rewrite.
- [Issue #62](https://github.com/cinepro-org/core/issues/62) reports invalid streams/multiple provider failures, with only 5/14 returning results in its diagnostic. Anecdotal report, not our measured success rate.
- CI runs audit, formatting and TypeScript build, not live playback tests ([workflow](https://github.com/cinepro-org/core/blob/98ba005f75d2675877774f5a676b3bc1c4150c27/.github/workflows/ci.yml#L30-L48)). No test script in inspected package definition. README “production-ready” should not override these maintenance signals.

## Concrete benefit to current Veil Server5

Local code inspected: `lib/src/features/native_player/repository/cinesrc_stream_resolver.dart` and `models/resolved_stream.dart`.

Veil already has browser capture, copied headers/cookies, HLS validation, master preservation, codec-conscious startup selection, qualities/subtitles, a 60-second resolver cache, invalidation, and browser disposal before native playback. Model accepts HLS/MP4 and exposes `StreamResolver.resolve(Uri)`; it has `resolvedAt`, but no explicit expiry or per-subtitle header/format fields. These are working-tree observations, not pinned public GitHub claims; native files are currently untracked work in progress.

1. **Best next experiment: separate VaPlayer adapter.** Port MIT HTTP request/mapping, identify media from Veil’s structured TMDB/movie/episode context, and return existing `ResolvedStream`. This could avoid browser startup for that provider; latency and reliability remain hypotheses. Preserve CineSrc fallback and existing native playback/UI work.
2. **Retain stronger existing header/master handling.** Streamgrabber’s UA/Referer-only replay and highest-quality default would be regressions. CinePro’s proxied quality strings are not a replacement for Veil’s manifest parser.
3. **Borrow freshness concept, not download pipeline.** Add explicit expiry when provided, conservative caching when unknown, and bounded re-resolution after expired-source failure while preserving playback position. Streamgrabber demonstrates TV URL refresh; neither project implements Veil’s native seek recovery.
4. **Useful future schema:** provider identity, stream type, URL, upstream headers or explicit proxy mode, master URL, manifest-derived qualities, subtitle URL/label/language/format/headers, resolved time and optional expiry. This is a proposed Veil adapter contract, not either repository’s existing HTTP response.
5. **CinePro benefit is architectural reference:** provider capability flags, normalized results, per-provider diagnostics, source deduplication and separating resolution from native playback. Commercial code reuse needs separate permission, and current rewrite/health uncertainty makes immediate integration unattractive even aside from licensing.

**Bottom line:** Streamgrabber’s **VaPlayer HTTP module** is the strongest small, permissively licensed reuse candidate. CinePro is broader but currently unsuitable as a dependable production resolver dependency. Keep Server5’s AVPlayer/ExoPlayer layer and startup/seek enhancements independent of either source project. No live playback or performance conclusions are claimed.
