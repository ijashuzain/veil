# Provider Pagination And Home Hero Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Paginate provider catalogs with sticky media tabs and replace Home's greeting/card hero with a full-bleed cinematic hero matching the supplied reference while preserving Veil navigation and social actions.

## Provider Pagination State

Each provider/media identity owns independent state keyed by provider ID and media type:

- ordered, deduplicated items
- latest successful page
- initial load status
- loading-more flag
- can-load-more flag
- load-more error

Initial load requests page 1. Infinite pagination requests the next page when selected grid scrolls within 500 logical pixels of its end. New pages append after deduplication by media type and TMDB ID. Empty next page sets can-load-more false. Page failure preserves existing items and blocks automatic repeated retries until user taps footer Retry.

Movies and TV Series state persists when switching tabs during the provider screen session. Existing `TmdbRepository.discoverByProvider` remains the page transport.

## Provider Catalog Screen

- Use a single `CustomScrollView`.
- Keep transparent Veil app bar with glass circular back action and no title.
- Provider logo/name header scrolls normally.
- Movies/TV Series pills live in a pinned `SliverPersistentHeader` below app bar.
- Header is fully transparent with no blur, fill, or divider; tab pills provide their own contrast while content scrolls behind.
- Selected tab renders responsive poster `SliverGrid`: three phone columns and existing wider-screen counts.
- Initial loading uses matching grid skeleton.
- Initial empty/error states replace grid content.
- Loading more shows compact footer spinner.
- Load-more failure shows compact footer Retry while preserving grid.
- Remove `Streaming availability data by JustWatch · Catalog data by TMDB` from this screen.
- Keep provider route, US filtering, item Detail navigation, and tab-specific retry.

## Home Hero Structure

- Remove `Tonight on Veil` and `Hello, {username}` entirely.
- Remove separate header spacing above hero.
- Hero is full bleed to left/right/top edges with no card radius.
- Hero height is cinematic and viewport-aware, approximately 60-70 percent of phone height with bounded tablet/desktop values.
- Keep top-five trending source, seven-second automatic rotation, and 500ms reduced-motion-aware fade.
- Hide hero dot indicators.
- Keep category rail immediately after hero.

Hero backdrop treatment:

- cover-fit TMDB backdrop
- left and right dark vignette
- strong bottom gradient blending into `VeilColors.bg0`
- top contrast gradient for controls

Top controls:

- Veil/movie mark at top left
- existing Search and Alerts glass buttons at top right
- alert unread badge preserved
- controls respect safe-area inset

Lower centered content:

- uppercase title, maximum two lines
- metadata row with calendar icon/year and category icon/primary genre
- centered description, maximum three lines
- primary white View pill, never Play
- secondary dark capsule containing plus action, divider, and info action

Actions:

- View opens featured Detail.
- Info opens featured Detail.
- Plus opens Veil's existing social action sheet for featured item.
- Social sheet receives current watched, favorite, watchlist, and rating state.
- Watched/favorite/watchlist/rating actions use `socialLibraryViewModelProvider`.
- Review action opens existing `DetailReviewSheet` and saves through existing social view model.
- Plus does not launch playback.

## Error And Empty Behavior

- Missing featured data keeps full-width hero skeleton.
- Provider initial errors keep selected-tab Retry.
- Provider page errors never clear existing successful items.
- Search/Alerts and category rail remain available regardless provider service state.

## Testing

- Provider page 1 and page 2 append and dedupe.
- Empty page disables further loads.
- Load-more error preserves items and requires explicit retry.
- Movie and TV states survive tab switching.
- Near-bottom scroll triggers one request at a time.
- Tabs use pinned persistent header.
- Attribution text is absent.
- Greeting labels are absent.
- Hero is full bleed, radius zero, viewport-aware, and has required gradients/controls/content.
- Hero rotates without dots.
- View and info open Detail.
- Plus opens existing social action sheet and review flow.
- Search/Alerts and unread badge remain.
- Run focused tests, full Flutter suite, and analyzer.

## Non-Goals

- No provider API contract or region changes.
- No playback changes.
- No Home category/data ordering changes.
- No social schema changes.
- No bottom-navigation changes.
