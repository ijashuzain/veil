## Context

The detail playback sheet currently exposes three providers. Server 1 uses Vidsrc top-level embed pages, Server 2 uses the existing PlayIMDB/StreamIMDB flow, and Server 3 uses Cinesrc TMDB embeds. The app already has TMDB IDs available through `ContentItem.remoteId`, and TV playback already has a reusable season/episode selection sheet.

VidLink documents movie and TV embed URLs that require TMDB IDs. It also documents anime URLs that require MyAnimeList IDs, but the current app model and TMDB repository do not carry MAL IDs.

## Goals / Non-Goals

**Goals:**
- Add VidLink as a fourth mobile playback server for movies and TV/series content.
- Use TMDB IDs only for VidLink movie and TV URLs.
- Reuse the existing TV season/episode picker for Server 4.
- Keep Server 1, Server 2, and Server 3 behavior unchanged.
- Keep the implementation small and covered by existing widget and URL-builder test patterns.

**Non-Goals:**
- Do not implement VidLink anime playback in this change.
- Do not add MAL ID fields, anime metadata lookup, or title-to-anime matching.
- Do not implement VidLink watch-progress or player-event ingestion.
- Do not add a new backend service or package dependency.
- Do not redesign the server sheet beyond adding the fourth option.

## Decisions

### Add a dedicated VidLink URL helper

Add a `vidlinkPlaybackUrl` helper alongside the existing playback URL helpers. The helper will return `null` when the TMDB ID is missing or invalid, because VidLink movie and TV documentation requires TMDB IDs and does not document an IMDb fallback.

Rationale: URL construction remains centralized and directly testable. It also keeps provider-specific parameter choices out of `DetailView`.

Alternatives considered:
- Inline VidLink URLs in `DetailView`: rejected because playback URL generation is already centralized.
- Fall back to IMDb IDs: rejected because the VidLink documentation only describes TMDB IDs for movies and TV.

### Reuse the existing episode picker for TV and series

Server 4 TV and series playback will open `DetailEpisodeSelectionSheet` before playback, matching Server 1's Vidsrc TV flow.

Rationale: VidLink TV URLs require season and episode values, and the current UX already solves that interaction.

Alternatives considered:
- Default Server 4 TV to season 1 episode 1: rejected because it can silently play the wrong episode.
- Add a separate Server 4 picker: rejected because it would duplicate existing UI.

### Load VidLink as a top-level embedded web page

Server 4 will open VidLink URLs through `FullscreenLandscapeWebPlayer` with top-level mobile page loading, matching the working Vidsrc path. The mobile WebView main-frame guard will allow `vidlink.pro/movie/...` and `vidlink.pro/tv/...` paths.

Rationale: The recently fixed mobile WebView path already handles fullscreen orientation, iOS inspectability, adblock filtering, and main-frame redirect blocking. VidLink's documented embeds are page URLs rather than direct HLS streams.

Alternatives considered:
- Use the direct video player: rejected because VidLink documents embed pages, not direct playlists.
- Use an external browser: rejected for Server 4's first version because other forced-embedded providers stay inside the app.
- Load VidLink inside the existing iframe wrapper: rejected for the first version because recent provider testing showed top-level loading is more reliable on mobile WebViews.

### Use VidLink's JW player mode

Server 4 will append `player=jw` plus Veil accent color parameters to VidLink movie and TV URLs.

Rationale: Initial device smoke testing showed the default VidLink player page could load its UI but remain stuck at `0:00 / 0:00` in the mobile WebView after an ad/popunder navigation attempt was blocked. VidLink documents `player=jw` as an alternate player mode, and this keeps the integration provider-supported while avoiding a custom WebView workaround. VidLink/JWPlayer defaults to red controls when color parameters are omitted, so Server 4 sets `primaryColor=FFFFFF`, `secondaryColor=253034`, and `iconColor=FFFFFF` for a white/dark player theme.

Alternatives considered:
- Keep plain documented URLs: rejected because the default player stalled during mobile smoke testing.
- Keep VidLink/JWPlayer default colors: rejected because the default red controls do not match the app theme.
- Add `fallback_url` immediately: rejected because it can obscure which provider actually played and may require broader main-frame redirect allowances.

### Defer VidLink progress and player events

VidLink documents `postMessage` progress and player events, but this change will not consume them.

Rationale: The current app already has separate watched/watchlist/review flows. Persisting VidLink playback progress would require new data modeling, storage semantics, privacy decisions, and likely a wrapper page or JavaScript channel.

Alternatives considered:
- Store VidLink progress in local storage immediately: rejected as a larger feature with unclear product behavior.
- Add a JS bridge to Flutter now: rejected because playback availability is the current goal.

## Risks / Trade-offs

- VidLink may reject or redirect mobile WebViews → Use the same mobile WebView hardening path as Vidsrc and smoke-test on iOS or Android.
- VidLink has no documented IMDb fallback → Show the existing unavailable-ID toast when TMDB ID is missing.
- Adding a fourth callback extends the current hardcoded server sheet → Accept for this small change; consider a data-driven server list only if more providers are added.
- VidLink anime support may be expected because the docs include it → Explicitly keep anime out of scope until MAL IDs are available.
- Provider-specific customization parameters may be desirable later → Start with only the documented `player=jw` and color parameters and keep URL construction centralized.

## Migration Plan

1. Add VidLink URL-builder tests for movie, TV, invalid season/episode clamping, and missing TMDB ID.
2. Add Server 4 to the playback server sheet and route it from `DetailView`.
3. Reuse the existing episode picker for TV and series content.
4. Open VidLink through `FullscreenLandscapeWebPlayer` and update mobile WebView guard behavior if loaded as a top-level page.
5. Add widget coverage for Server 4 movie, TV episode selection, and missing TMDB ID behavior.
6. Run focused tests, full `flutter test`, and `flutter analyze`.
7. Smoke-test Server 4 playback on Android or iOS.

Rollback strategy: remove the Server 4 button and VidLink routing/helper/tests, leaving the existing three servers unchanged.

## Open Questions

- Should a follow-up change add VidLink customization parameters after base playback is verified?
