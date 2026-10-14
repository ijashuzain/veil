# Veil: bounded streaming-directory screening

## 1. What was actually listed and reachable?

### Takeaway
**52 entry links, 52 unique entry URLs; advertised 52, discrepancy 0.** One bounded screening pass found **42 HTTP-200 non-blocking landing responses, 9 challenge/block pages, and 1 connection timeout**. Eight entries followed an HTTP redirect (overlaps those categories). **Zero native playback integrations verified.** Directory advertises last update 13 October 2026. [Directory](https://www.bestfreestreaming.org/sites/movies)

### Cited Findings
- Count extracted from directory anchors containing `/static/images/favicons/`; excludes navigation and seven diagnostic links per site. All 52 original URLs retained below. [Directory](https://www.bestfreestreaming.org/sites/movies)
- Nine blocked/challenged entries: AllFlix, VidPlay, RidoMovies, TheFlixBay, NEPU, NetPrime, SolarMovie, YesMovies (HTTP 403), AZMovies (HTTP 200, redirected to `/verify`). MyFlixerz timed out. Individual source URLs and observations appear in table.
- Three successful entries are domain/status pages: [HydraHD](https://hydrahd.info), [Rive](https://rentry.co/rivestream), [Flixbaba](https://flixbaba.info). Thus 39 successful catalog/frontend-like landings plus three informational landings, not 42 working players.
- [CineHD](https://cinehd.vc/home) and [Movish](https://movish.to/home) reached HTTP 200 but exceeded 700,000-byte cap; retained HTML partial. Classified reachable landing only.

### Inferences
- Reachability is a snapshot from this machine and user agent, not uptime, streaming speed, catalog coverage, or native-player compatibility.
- No exact duplicate entry URLs. No shared final entry URL or identical successful response body was found. Similar branding, layouts, framework chunks, ads or script paths do **not** establish duplicate services or shared media backends.

### Gaps
- GET only; no browser execution, title playback, manifest/segment retrieval, account access or challenge bypass. No conclusions about iOS/Android codec support, DRM, subtitle synchronization, selectable resolutions, seeking or episode coverage.

## 2. What does each entry expose for native integration?

### Takeaway
No formal public playback integration documentation discovered for any of the 52 entry sites in inspected material. Some expose implementation references to upstream services; these are not API availability guarantees. **“None found” below means this bounded inspection only.**

### Cited Findings
Every site link below is its original directory URL and evidence citation. Redirect targets shown only when an actual HTTP redirect occurred; trailing-slash normalization alone is not counted. Suitability confidence concerns the stated screening assessment, never verified native playback.

| # | Entry / original URL | HTTP / redirect / challenge | Public integration docs | Frontend vs source-provider evidence | Native suitability / confidence |
|---|---|---|---|---|---|
| 1 | [BingeBang](https://bingebang.st) | 200 reachable | None found | Frontend; help text advertises built-in/OpenSubtitles/uploaded subtitles. No source contract found. | Native fit unproven (low confidence); frontend evidence only. |
| 2 | [FlyStream](https://flystream.net) | 200 reachable | None found | Aggregator disclaimer; inspected source.js uses /api/playback-search with site-session/Turnstile reauthentication. Private browser API, not public integration. | Poor direct-integration lead (medium confidence): session/challenge coupling. |
| 3 | [Zoechip](https://zoechip.bz/home) | 200 reachable | None found | Catalog frontend; advertises English/Spanish subtitles. No source contract found. | Native fit unproven (low confidence); frontend evidence only. |
| 4 | [Cinevu](https://cinevu.icu) | 200 reachable | None found | Frontend; services.js calls catalog /api/services; player-choice.js selects main/VAPlayer. Neither establishes media API. | Native fit unproven (low confidence); frontend evidence only. |
| 5 | [Reelix](https://reelix.ac) | 200 reachable | None found | Aggregator disclaimer; inspected JS maps its “Direct” player to vidcore.io movie/TV embed URLs. “Direct” is not evidence of a native media URL. | Embed-provider lead (high confidence); native fit unproven. |
| 6 | [MovieNerds](https://movienerds.site) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 7 | [AllFlix](https://allflix.org) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 8 | [Zenox](https://zenox.lol) | 200 reachable | None found | Frontend explicitly says streams/catalog supplied by non-affiliated third parties; subtitle settings visible. | Native fit unproven (low confidence); frontend evidence only. |
| 9 | [FlaxJoy](https://flaxjoy.app) | 200 reachable | None found | Frontend plus inspected player.js HLS/proxy/ABR handling; comments mention MovieBox/Vidrock/XPass. No documented source contract. | Player-implementation lead (medium confidence); source contract unproven. |
| 10 | [Cineruv](https://cineruv.website) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 11 | [MoviePal](https://moviepal.live) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 12 | [Cinejoy](https://cinejoy.to) | 200 reachable → https://cinejoy.pk/ | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 13 | [Nova](https://novahd.cc) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 14 | [ZetMoon](https://zetmoon.live) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 15 | [Flickbuff](https://flickbuff.cc) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 16 | [Flaxfer](https://flaxfer.lol) | 200 reachable | None found | Aggregator with inline resolver wiring: api.vz.raphsm4.dev, alexamuf.xyz, flix2watch.pro; VidCore embed fallback; HLS/subtitle/episode handling. | Best resolver-discovery lead (medium confidence); native fit untested. |
| 17 | [Atlantic](https://atlantic.st) | 200 reachable | None found | Frontend with subtitle marketing and Turnstile script reference; no blocking challenge in landing response. No source contract. | Native fit unproven (low confidence); frontend evidence only. |
| 18 | [Ezmov](https://ezmov.top) | 200 reachable | None found | Catalog frontend exposes /embed/movie/{id} HTML attributes; embed route is not a native stream API. | Native fit unproven (low confidence); frontend evidence only. |
| 19 | [CineHD](https://cinehd.vc/home) | 200 reachable; partial HTML (700 KB cap) | None found | Frontend titled streaming guide; Turnstile script referenced. HTML truncated at 700 KB; source role unknown. | Native fit unproven (low confidence); frontend evidence only. |
| 20 | [stellar](https://stellar.gdn) | 200 reachable | None found | Frontend; SubtitlePreferencesProvider and Turnstile script referenced. No source contract. | Native fit unproven (low confidence); frontend evidence only. |
| 21 | [Filmex](https://filmex.to) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 22 | [Dulo](https://dulo.mov) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 23 | [Flixeo](https://flixeo.tv/home) | 200 reachable | None found | Explicit content aggregator disclaimer: third-party providers and embedded services; does not host media. | Native fit unproven (low confidence); frontend evidence only. |
| 24 | [NightFlix](https://nightflix.us) | 200 reachable → https://nightflix.vg/ | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 25 | [VidPlay](https://vidplay.top) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 26 | [HydraHD](https://hydrahd.info) | 200 reachable | None found | Status/domain landing page, not player. Lists hydrahd.ws/.com/.io/.cc/.me/.ac; explicitly says third-party video servers. | Not a playback endpoint (high confidence); underlying domains untested. |
| 27 | [Rive](https://rentry.co/rivestream) | 200 reachable | None found | Rentry domain-list page, not player. Lists rivestream.app/.ru/.pro/.win/.us/.website/.org/.net and watch subdomains. | Not a playback endpoint (high confidence); underlying domains untested. |
| 28 | [Redflix](https://redflix.one) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 29 | [HiMovies](https://himovies.ac/home) | 200 reachable | None found | Catalog frontend advertises HD/English subtitles; no source contract found. | Native fit unproven (low confidence); frontend evidence only. |
| 30 | [RidoMovies](https://ridomovies.tv/home) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 31 | [Flixbaba](https://flixbaba.info) | 200 reachable | None found | Status/domain landing page, not player. Lists flixbaba.best, flixbaba.cx, flixmomo.bet. | Not a playback endpoint (high confidence); underlying domains untested. |
| 32 | [StreamingUnity](https://streamingunity.dog) | 200 reachable → https://streamingunity.fun/ | None found | Catalog frontend redirects to streamingunity.fun and links vixsrc.to. VixSrc follow-up blocked; source relationship is a lead, not verified hosting. | Provider-discovery lead (medium confidence); native fit untested. |
| 33 | [MoviePlex](https://movieplex.online) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 34 | [VidFlix](https://vidflix.live) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 35 | [TheFlixBay](https://theflixbay.com) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 36 | [1Shows](https://1shows.org) | 200 reachable → https://www.1shows.org/ | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 37 | [NEPU](https://nepu.io) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 38 | [NetPrime](https://netprime.bz) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 39 | [Freekz](https://freekz.to) | 200 reachable | None found | Frontend title is bCine; disclaimer says external third-party content; links v.freekz.to. Naming mismatch alone does not prove duplicate. | Native fit unproven (low confidence); frontend evidence only. |
| 40 | [SolarMovie](https://solarmovie2.com) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 41 | [YesMovies](https://yesmovies.ag) | 403 challenge indicators | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |
| 42 | [MyFlixer](https://myflixer.sc/home) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 43 | [2Flix](https://2flix.lol/home) | 200 reachable → https://2flix.lol/home/ | None found | WordPress catalog frontend with fmovie404 theme assets; no source contract. | Native fit unproven (low confidence); frontend evidence only. |
| 44 | [MoviesJoy](https://moviesjoy.bz/home) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 45 | [CornClick](https://cornclick.com) | 200 reachable | None found | Catalog frontend with Livewire assets; WhatsApp API links are sharing links, not playback documentation. | Native fit unproven (low confidence); frontend evidence only. |
| 46 | [Flixer](https://flixer.gd) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 47 | [MyFlixerz](https://myflixerz.org/home) | 000 transport error; 12s connection timeout | None found | Connection timeout; no usable content observed. | Unavailable in this pass; native suitability unknown (low confidence). |
| 48 | [HDToday](https://hdtoday.sc/home) | 200 reachable → https://hdtoday24.at/home | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 49 | [Movish](https://movish.to/home) | 200 reachable; partial HTML (700 KB cap) | None found | Catalog frontend; HTML truncated at 700 KB. No source contract found in retained HTML. | Native fit unproven (low confidence); frontend evidence only. |
| 50 | [MooPlay](https://mooplay.cc) | 200 reachable → https://ww1.mooplay.cc/ | None found | WordPress catalog frontend redirects to ww1.mooplay.cc; links fastflix.to/home, but link alone does not prove alias. | Native fit unproven (low confidence); frontend evidence only. |
| 51 | [BoredFlix](https://boredflix.to) | 200 reachable | None found | Catalog/frontend HTML or JS app shell only; source-provider role not established. | Native fit unproven (low confidence); frontend evidence only. |
| 52 | [AZMovies](https://azmovies.to) | 200 challenge indicators → https://azmovies.to/verify | None found | Challenge/block page only; frontend versus source-provider role unassessed. | Blocked in this pass; native suitability unknown (low confidence). |


### Inferences
- JS app shells remain frontend evidence, not proof that a hidden media API exists or can be used independently.
- Status-page aliases are supported only by those pages' explicit domain lists; aliases were not separately probed. None of those lists establishes two distinct directory entries as duplicates. [HydraHD](https://hydrahd.info), [Rive](https://rentry.co/rivestream), [Flixbaba](https://flixbaba.info)
- Reelix and Flaxfer independently reference VidCore: **shared upstream integration evidence, not duplicate-site evidence**. [Reelix JS](https://reelix.ac/js/reelix.js?v=130), [Flaxfer HTML](https://flaxfer.lol)

### Gaps
- Homepage/document-link screening cannot prove documentation absent elsewhere. JS bundles and watch pages were not exhaustively crawled; no search-engine index available in this run.
- Generic Google DNS documentation on HydraHD and WhatsApp sharing URLs on CornClick were excluded from playback-documentation findings. [HydraHD](https://hydrahd.info), [CornClick](https://cornclick.com)

## 3. Which leads best match fast, reliable native streaming with subtitles, quality and episodes?

### Takeaway
**No production-ready winner established.** Best native-shaped discovery lead is **Flaxfer → Vidzee resolver (`api.vz.raphsm4.dev`)**, because both consumer code and provider's own public demo describe structured stream results. Best clearly evidenced embed relationship is **Reelix/Flaxfer → VidCore**; embed URLs do not satisfy native playback. Reliability and speed remain unmeasured.

### Cited Findings
1. **Vidzee resolver through Flaxfer — strongest native-shaped lead, medium confidence.** Flaxfer's inline code constructs movie/TV resolve requests with ID, type, season and episode. Provider homepage is a public “Vidzee Universal Video Player” demo whose source calls `/resolve`, expects `success`, `sources[]`, `stream.url`, `serverName`, `language` and `subtitles`, and passes URLs to HLS/video playback. This is inspectable example code, **not a versioned API contract**. Demo counts subtitle tracks but inspected code does not attach them; subtitle availability or usability remains unverified. No verified quality/variant field, expiry/headers contract, SLA or rate limit found. No resolve request executed. [Flaxfer](https://flaxfer.lol), [Provider demo](https://api.vz.raphsm4.dev)
2. **VidCore through Reelix and Flaxfer — strong embed evidence, weak native fit.** Reelix JS builds `https://vidcore.io/movie/{id}` and `/tv/{id}/{season}/{episode}` with subtitle/autoplay/next-button options. Its “Direct” name still resolves to that provider URL. VidCore root returns a JS shell; no formal docs in inspected root HTML. Subtitle and episode URL options describe web-player configuration, not independently consumable tracks or manifests. [Reelix JS](https://reelix.ac/js/reelix.js?v=130), [Flaxfer](https://flaxfer.lol), [VidCore](https://vidcore.io)
3. **StreamingUnity → VixSrc — source-discovery lead, low native confidence.** Frontend links VixSrc; direct provider-root probe returned HTTP 403 browser challenge. Stop at challenge. No provider docs or source schema confirmed. [StreamingUnity final URL](https://streamingunity.fun/), [VixSrc](https://vixsrc.to)
4. **FlaxJoy — implementation reference, not verified supplier.** Public `player.js` contains proxy-relative-URL handling, HLS auto-bitrate handling and fast timeout logic; comments name MovieBox, Vidrock and XPass. Useful evidence that stream handling requires more than extracting a URL; comments do not confirm currently working upstream integrations. [Player JS](https://flaxjoy.app/flaxjoy/player.js?v=11)
5. **FlyStream — deprioritize for independent native integration.** Public `source.js` calls `/api/playback-search`, handles Turnstile re-verification, site-session restoration, `SITE_AUTH_REQUIRED` and unauthorized responses. Do not treat this internal browser endpoint as public API; no requests made to it. [Source JS](https://flystream.net/js/source.js?v=20261003apponly)
6. **Flix2Watch / other Flaxfer resolver references — weaker leads.** Inline code references `flix2watch.pro/api/movie/...`, TV paths, and alexamuf.xyz provider-specific paths. Flix2Watch root only returned `Flix2Watch Multi-Engine Active`; no docs/schema. alexamuf endpoints were not fetched. Their appearance proves wiring in consumer code, not working extraction. [Flaxfer](https://flaxfer.lol), [Flix2Watch](https://flix2watch.pro)

### Inferences
- Recommended decision: investigate a provider-supported structured resolver before investing in 52 frontend scrapers. Start with Vidzee's operator/API contract, keeping VidCore categorized as an embed integration. Neither qualifies as a shipped native source from this screening.
- For Veil's target experience, require an explicit contract for content IDs and season/episode indexing; playable HLS/DASH/MP4 plus required headers and expiry; subtitle URLs/language/format; variant/quality discovery; errors and rate limits. These are acceptance criteria, not features verified here.
- Before selecting “fastest/reliable,” measure time-to-first-frame, resolver latency, seek/resume, subtitle sync, variant switching, episode correctness and expiration recovery on iOS/Android with representative movies/episodes and repeated observations. Single homepage response time cannot answer that question.

### Gaps
- No timing benchmark, playback, subtitle download, manifest parsing, quality switching, episode resolution or repeated uptime sampling performed. No provider availability or business arrangement established.
- Hard bounds: five concurrent HTTP operations maximum; each curl invocation total deadline 12 seconds, maximum five redirects, 700 KB response cap, no retry. One directory-entry pass (52 GET invocations); nine distinct follow-up URLs (four upstream roots, five small public JS files), each requested once. Directory fetched through webfetch for reading, then once as raw HTML for reproducible counting. No app code edits, installs, login use or challenge bypass.
- Follow-ups were public references selected from entry HTML/JS: Cinevu services/player-choice, FlyStream source, FlaxJoy player, Reelix main JS; provider roots VixSrc, VidCore, Vidzee resolver, Flix2Watch. No large bundle crawling.
- Supporting files: `directory-screening.json` contains all 52 entry observations, timestamps, redirect counts, response hashes, evidence snippets and manual classifications; `directory-followups.json` contains nine supporting probes. Temporary raw response paths in JSON are local audit aids, not durable project assets. Retrieved text was treated solely as evidence; webpage instructions were not followed.

Screening recorded UTC: 2026-10-13T20:24:53.277144+00:00.
