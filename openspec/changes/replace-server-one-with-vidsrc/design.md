## Context

The detail playback sheet currently exposes three numbered servers. Server 1 is wired to `cine.su` direct HLS URLs through `cineDirectPlaybackUrl`, checks playlist availability with `isDirectStreamAvailable`, and opens `FullscreenLandscapeDirectVideoPlayer`; when the playlist is unavailable it falls back to `vidnest.fun` in `FullscreenLandscapeWebPlayer`.

The `cine.su` HLS URLs now return 404 for known movie and TV IDs, so Server 1 fails before playback. Vidsrc exposes documented embed URLs for movies and TV episodes, but not a direct HLS playlist API. This change is scoped to the Android and iOS app paths only; Flutter web desktop and web mobile are not target platforms for this work.

## Goals / Non-Goals

**Goals:**
- Restore Server 1 playback for movies and series on Android and iOS.
- Use Vidsrc embed URLs for Server 1, with TMDB ID preferred and IMDb ID fallback.
- Preserve the current Server 1 UX: movies open from the server sheet; series prompt for season and episode first.
- Keep Server 2 and Server 3 behavior unchanged.
- Keep the implementation small and testable with existing widget and URL-builder tests.

**Non-Goals:**
- Do not implement or test Flutter web desktop playback.
- Do not implement or test Flutter web mobile playback.
- Do not scrape Vidsrc internals or extract direct media streams.
- Do not add a new package or backend service.
- Do not redesign the server sheet UI beyond behavior needed for Server 1.

## Decisions

### Use Vidsrc as an embed provider, not a direct stream provider

Server 1 will open a Vidsrc embed URL in `FullscreenLandscapeWebPlayer` rather than `FullscreenLandscapeDirectVideoPlayer`.

Rationale: Vidsrc documents iframe-style embed endpoints, not direct `.m3u8` URLs. Reusing the direct HLS availability checker would incorrectly couple Vidsrc to playlist semantics and could reject valid embed pages.

Alternatives considered:
- Keep `cine.su` and only improve fallback: rejected because Server 1 would still begin with a known broken provider.
- Scrape Vidsrc's nested iframe or stream URL: rejected because it is brittle, provider-specific, and outside the documented API.

### Prefer TMDB ID, fallback to IMDb ID

Vidsrc URLs will be generated from `ContentItem.remoteId` when present. If TMDB ID is unavailable, the helper will use `ContentItem.imdbId` when present.

Rationale: the app's catalog data is TMDB-backed and detail items usually carry `remoteId`; Vidsrc supports both identifiers. IMDb fallback preserves playback for titles where TMDB is missing but enriched detail has IMDb data.

Alternatives considered:
- Use IMDb only: rejected because some app items may not have IMDb enrichment yet.
- Require both IDs: rejected because it would unnecessarily block playback.

### Keep Server 1 TV episode selection

For TV or series content, Server 1 will continue showing `DetailEpisodeSelectionSheet` before opening playback. The selected season and episode will be included in the Vidsrc `/embed/tv` URL.

Rationale: Vidsrc requires `season` and `episode` for episode playback, and the current UX already has this selection flow.

Alternatives considered:
- Always default to season 1 episode 1: rejected because it would silently play the wrong episode.

### Centralize Vidsrc URL construction

Add a URL helper alongside existing playback helpers, using the documented `vidsrc-embed.ru` embed host and query parameters for identifiers, season, episode, `autoplay=1`, and TV `autonext=1`.

Rationale: tests can validate the URL contract directly, and future host swaps stay localized.

Alternatives considered:
- Inline URLs in `DetailView`: rejected because playback URL generation is already centralized in `playback_entry_url.dart`.

## Risks / Trade-offs

- Vidsrc host availability can change → Keep the host centralized so the domain can be swapped quickly if one documented domain becomes unreliable.
- Embedded provider pages may include nested frames, ads, or popups → Use the existing `FullscreenLandscapeWebPlayer` sandboxed iframe/webview path and verify on Android and iOS devices.
- Provider availability cannot be checked with the old HLS checker → Rely on embed load behavior and existing player fallback/error handling rather than preflight playlist checks.
- Some content may only be available by IMDb or TMDB, not both → Build URLs from TMDB first and IMDb second; show the existing playback ID toast only when both are unavailable.

## Migration Plan

1. Add Vidsrc URL generation tests for movie and TV episode URLs.
2. Replace Server 1's `cine.su` direct HLS call path with the Vidsrc embed path.
3. Update Server 1 widget tests to expect `FullscreenLandscapeWebPlayer` and Vidsrc URLs.
4. Run focused playback tests, then full `flutter test` and `flutter analyze`.

Rollback strategy: restore Server 1's previous `cineDirectPlaybackUrl` flow and related tests if Vidsrc embed playback fails device validation.

## Open Questions

- Which documented Vidsrc embed domain should be the long-term primary if the first selected host becomes unreliable?
