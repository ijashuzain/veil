# Cinejoy Playback And Home Discovery Design

**Date:** 2026-08-08
**Status:** Approved

## Goal

Replace Veil's Server 2 PlayIMDb flow with Cinejoy, then improve Home using the supplied visual references and catalog APIs without removing Veil's social features or presenting invented playback progress.

## Confirmed Product Decisions

- Server 2 uses Cinejoy and TMDB IDs.
- Continue Watching means locally persisted recently started playback. Veil does not show progress percentages, remaining time, or resume positions it cannot measure.
- Home may use both TMDB and `lists.shegu.st`.
- Bottom navigation keeps Home, Diary, Reviews, and Profile.
- TMDB requests continue using Veil's configured credentials or Supabase proxy. The API key shown in captured Cinejoy traffic is not copied into Veil.
- Watch-provider region is US for this pass, matching the supplied requests. Region selection is deferred.

## Verified Constraints

- Cinejoy movie URLs use `https://cinejoy.to/watch/movie/{tmdbId}`.
- Cinejoy TV URLs use `https://cinejoy.to/watch/tv/{tmdbId}/{season}/{episode}`. The supplied `94997` example is a TMDB ID, not an IMDb ID.
- Cinejoy returns `Content-Security-Policy: frame-ancestors 'none'`. Flutter web cannot render Cinejoy inside an iframe.
- Android and iOS can load Cinejoy as a top-level WebView page.
- Cinejoy's cross-origin player does not expose reliable playback position, duration, or completion events to Veil.
- TMDB watch-provider data is powered by JustWatch. Provider surfaces must show attribution and use TMDB provider IDs, names, logos, and region-filtered discover results.
- Shegu is an undocumented third-party API. Its failure or schema change must not break core Home loading.

## Scope

### Included

- Server 2 Cinejoy URL construction and TV episode selection.
- Native top-level Cinejoy WebView loading and external Flutter web launch.
- Shared playback requests so recently started cards can relaunch the same server and episode.
- Per-user local recently started history with edit and remove controls.
- Five-item auto-rotating Home hero with fade animation and tappable indicators.
- TMDB watch-provider logo rail and provider detail screen.
- Provider-filtered movie and TV results for US region.
- Shegu collection selector and one on-demand curated poster rail.
- Existing TMDB recommendations and similar titles rendered on Detail.
- Screenshot-inspired polish for current four-tab floating navigation.
- Focused repository, utility, and widget tests.

### Excluded

- True playback progress, remaining time, cross-device history sync, and resume-to-second.
- Supabase schema changes.
- Replacing Server 1, 3, or 4.
- Extracting direct streams from Cinejoy.
- Copying Cinejoy analytics, ad calls, API key, or third-party streaming links.
- Provider-region settings, provider subscription management, and provider deep links.
- Replacing Diary or Reviews with Movies/TV tabs.
- Importing all Shegu ratings, parental scores, JustWatch clickout URLs, or streaming links.

## Architecture

### Playback Request And Launcher

Introduce a small playback request value containing:

- `ContentItem item`
- server number
- season and episode, defaulting to 1

A shared launcher maps the request to the current URL builders and player flags. Detail keeps responsibility for server and episode selection. Home uses the same launcher for recently started entries. This avoids storing stale provider URLs and avoids duplicating platform behavior.

Server behavior remains:

| Server | Native | Web | TV selection |
| --- | --- | --- | --- |
| 1 | Top-level in-app WebView | Existing embedded player | Existing picker |
| 2 | Top-level Cinejoy WebView | External Cinejoy launch on every viewport | Existing picker reused |
| 3 | Existing embedded player | Existing embedded player | Season 1, episode 1 |
| 4 | Top-level in-app WebView | Existing embedded player | Existing picker |

Server 2 no longer requires IMDb, redirect extraction, StreamIMDb, PlayIMDb, or VSEmbed fallback. It requires a positive TMDB ID. The mobile top-level navigation allowlist accepts Cinejoy `/watch/movie/` and `/watch/tv/` paths while preserving same-host restrictions and ad blocking. Flutter web performs direct top-level navigation without availability-prefetch proxies.

The shared launcher reports whether navigation was initiated. History is recorded only after an external launch succeeds or an in-app player route is pushed. It does not claim media playback actually began.

Premium entitlement remains required. Detail keeps its current Play-button gate. Home rechecks premium state before relaunching a history item so local data cannot bypass entitlement after logout, account change, or subscription loss.

### Recently Started Storage

Add a plain JSON-serializable playback-history entry rather than serializing Flutter-specific `ContentItem` fields such as `IconData` and colors. Stored fields are:

- TMDB ID, media type, title, subtitle, year, genre, rating, description
- poster and backdrop URLs
- IMDb ID when present for other servers
- server number
- season and episode
- last-started timestamp

Storage uses `LocalStorage` and a versioned key scoped by authenticated user ID. Entries use a stable key derived from media type, TMDB ID, server, season, and episode. Relaunching an entry moves it to the front. Keep at most 20 entries.

A Riverpod notifier exposes newest-first entries, records launches, removes one entry, and clears all entries for the current user. Malformed JSON is treated as empty history and replaced on the next write.

Home labels the section `Continue Watching` to match the approved UI, but cards show only real metadata:

- TV: `S{season} · E{episode}`
- Movie: `Recently started`

No progress bar, percentage, duration, or time-left label is shown. Edit mode replaces the pencil with a confirmation check and shows an accessible remove button on each card. Empty history removes the entire section.

### Rotating Hero

Home derives up to five hero items from weekly trending. It starts at index zero, advances every seven seconds, and wraps. `AnimatedSwitcher` fades the complete hero using item ID as its key. Indicators reflect the actual item count and allow direct selection; manual selection restarts the seven-second interval.

The timer is disposed with the view. Index resets safely when refreshed data changes or shrinks. The next backdrop is precached when possible. Reduced-motion settings collapse transition duration while preserving content rotation.

Hero actions retain current behavior: tapping the hero or View action opens Detail. This pass does not bypass premium gating or open a playback server directly from the hero.

### Watch Providers

Add a provider model with TMDB provider ID, name, logo path, and display priority. Repository calls:

- `/watch/providers/movie?language=en-US&watch_region=US`
- `/watch/providers/tv?language=en-US&watch_region=US`

Results merge by provider ID. Prefer the lowest US display priority and a non-empty logo. Home shows a capped, sorted logo rail. Provider data loads independently from existing Home data; failure hides only this rail.

Provider selection opens a typed `/provider/:id` route. The provider screen loads these requests independently:

- `/discover/movie` with `watch_region=US`, `with_watch_providers={id}`, `with_watch_monetization_types=flatrate|free|ads`, `sort_by=popularity.desc`, and `include_adult=false`
- `/discover/tv` with the same provider filters

The screen shows provider logo/name, Movies, and TV Series sections. One failed section does not hide the other. Empty sections state that no US titles were returned. The footer shows `Streaming availability data by JustWatch` and identifies TMDB as the catalog source.

Provider results continue through `TmdbRepository` filtering, including the special tester-account Disney/Pixar restriction.

### Curated Shegu Collections

Add an isolated repository using `https://lists.shegu.st/joy`. It maps collection metadata from the root response and fetches selected items from `/joy/{collectionId}?limit=12`.

Home shows collection choices using titles from the metadata response. Only the selected collection's items load, starting with the first collection. Results are cached by collection ID for the session. Changing selection retains current content until the new collection resolves, with a compact loading indicator.

Only these item fields are consumed:

- type, title, year, description, poster
- `ids.tmdb` and `ids.imdb`
- collection score, clamped to Veil's 0-10 display range

Items without a positive TMDB ID are omitted because Veil detail navigation depends on TMDB identity. Streaming links, provider links, multi-source ratings, parental ratings, and analytics fields are ignored. Tester-account filtering is applied through the existing TMDB restriction path before items reach Home.

Collection metadata or item errors show a small retry state inside the curated section. They never alter core Home load status.

### Detail Recommendations

`ContentDetail.recommendations` and `ContentDetail.similar` already load through TMDB. Render recommendations as a poster rail and render similar titles only when they add distinct TMDB IDs. Empty lists render nothing. No additional network request or model change is needed.

### Bottom Navigation

Keep current destinations and lazy `IndexedStack` behavior. Retain desktop NavigationRail behavior. On mobile:

- preserve floating safe-area placement and backdrop blur
- use a more translucent neutral glass panel
- keep inactive destinations icon-only
- keep a compact active pill with icon and label
- reserve Veil red for primary actions instead of filling the selected navigation pill
- preserve readable contrast and 390px layout without overflow

No navigation information architecture or routing change is included.

## Data And Failure Flow

Home has independent data lanes:

1. Existing TMDB Home sections keep current load state.
2. Playback history reads synchronously from initialized local storage.
3. Provider data has its own loading/error state.
4. Collection metadata and selected collection items have their own loading/error states.

Optional provider or Shegu outages cannot leave the existing hero in a permanent skeleton or remove existing TMDB rails. Provider movie and TV calls also fail independently.

Playback failures retain current toast behavior. Missing TMDB ID blocks Cinejoy with a clear message. Web external-launch failure records no history. Native navigation errors record no history.

## Testing

### Unit And Repository Tests

- Cinejoy movie and TV URL shapes.
- Season and episode values clamp to at least 1.
- Server 2 no longer requires IMDb or calls redirect extraction.
- Playback-history JSON round trip, per-user isolation, ordering, cap, malformed data, and removal.
- TMDB provider merge, logo URL, US discover query, and movie/TV mapping.
- Shegu collection metadata and item mapping, missing TMDB ID filtering, score clamping, and failure isolation.
- Tester-account restriction remains active for provider and curated results.

### Widget Tests

- Server 2 movie opens Cinejoy with TMDB ID.
- Server 2 TV opens episode selection and uses selected season/episode.
- Native Cinejoy uses top-level player mode; web uses external launch.
- Hero rotates after seven seconds, fades, wraps, and responds to indicator taps.
- Continue Watching is absent when empty, appears after a recorded launch, relaunches matching server/episode, and removes entries in edit mode.
- Provider rail opens provider detail; movie and TV sections handle loading, data, empty, and partial failure.
- Curated selector changes the visible poster rail and can retry failures.
- Detail recommendations navigate to the selected title.
- Mobile bottom navigation fits narrow layouts; desktop still uses the rail.

### Verification Commands

- Regenerate Riverpod, Freezed, JSON, and GoRouter outputs with `dart run build_runner build --delete-conflicting-outputs` when annotated inputs change.
- Run focused tests while implementing.
- Run `dart format` on changed Dart files.
- Run `flutter test`.
- Run `flutter analyze`.

## Rollout Risks

- Cinejoy can change paths, block WebViews, or add navigation behavior without notice. URL construction and top-level navigation restrictions remain isolated for replacement.
- Shegu has no documented compatibility contract. Parsing is defensive, optional, and isolated.
- Provider availability is region-specific and does not prove an active user subscription. UI says availability, not ownership.
- Recently started data is local and device-specific. UI avoids sync or exact-resume claims.
- External Flutter web playback leaves Veil. This is required by Cinejoy's frame policy, not a UI preference.
