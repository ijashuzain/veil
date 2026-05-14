# Veil Recent Feature Updates

Generated: 2026-05-03

This document summarizes the recently added and updated Veil features across playback, social actions, diary, search, profile, Supabase, branding, and UI polish.

## New Features

### Unified Movie Action Flow

- Added a single detail-page entry point: `Rate, log, review + more`.
- Replaced separate action controls with one focused bottom sheet.
- Bottom sheet actions now include:
  - Watched
  - Like
  - Watchlist
  - Rate
  - Review
  - Done
- The old `Log` wording was removed from the detail action flow and replaced with `Watched`.

### App User Ratings

- Added app-specific 1-5 star ratings for movies and shows.
- Ratings are separate from TMDB ratings.
- Explicit user ratings are clamped to the 1-5 range.
- Saving a rating marks the title as watched.

### Review Bottom Sheet

- Added a dedicated review sheet from the unified action flow.
- Review save requires a selected rating.
- Review sheet supports:
  - 1-5 star rating
  - Review text
  - First-time watch
  - Rewatch
- Saving a review automatically adds the movie to watched entries.

### Diary Tabs

- Redesigned Diary into top-level tabs:
  - Watched
  - Watchlist
  - Favorites
- Diary entries now render in a compact 4-column poster grid.
- Section-level `See all` buttons were removed from Diary because each tab is already a full list.
- Watched entries keep compact genre and rating filtering.

### Search Scopes

- Search now supports switchable scopes:
  - All
  - Users
  - Films
  - Cast
- `All` searches across supported result types.
- `Users` surfaces app user/member results.
- `Films` focuses on movie/TV content.
- `Cast` is reserved for person/cast-style results when available from TMDB data.

### Follow System

- Added follow/unfollow behavior for users.
- My profile and other user profiles now show:
  - Following count
  - Followers count
  - Following list
  - Followers list
- Other user profiles include a Follow/Unfollow button.

### Supabase Follow Storage

- Added `public.user_follows` schema support.
- Added row-level security policies for:
  - Public follow reads
  - Own follow inserts
  - Own follow deletes
- Follow data works with Supabase when authenticated.
- Local fallback follow storage remains available when Supabase auth is unavailable.

### IMDb Playback Resolution

- Detail playback now uses the enriched TMDB detail IMDb ID before resolving the player URL.
- Redirect extraction logs each hop and uses the final embed URL.
- Fullscreen landscape player receives the resolved embed URL.

### Home Category Results

- The `All` home category keeps the existing layout.
- Selected genres/categories now render as vertical results instead of horizontal rows.
- Redundant selected-category title text was removed.
- `See all` remains available where needed.
- Vertical category lists support pagination/loading more results.

### App Branding Assets

- Android launcher icon assets are present across density buckets.
- Android adaptive icon foreground/background configuration is wired.
- iOS AppIcon assets are present in the runner asset catalog.

## Updated UX And Visual Design

### Detail Page Social Panel

- Ratings/action panel was restyled away from copied reference colors.
- Ratings now use Veil's own gold accent.
- Social actions use restrained red and neutral graphite surfaces.
- The bottom sheet is more compact and cleaner.

### Review Sheet

- Review UI now uses neutral panel styling.
- Save button uses Veil red instead of the copied green style.
- Inputs and segmented controls were tightened for a more professional feel.

### Diary Screen

- Stats, tabs, filters, and grid spacing were made more compact.
- Selected filters no longer use oversized red blocks.
- Poster ratings use the new gold rating accent.

### Profile Screen

- Removed the heavy red gradient card treatment.
- Profile metrics were condensed into a cleaner single-row layout.
- Following/follower sections were tightened and restyled.

### Shared Theme

- Added neutral panel colors for denser app surfaces.
- Added a gold rating accent for stars and rating charts.
- Reduced reliance on bright red as the only active UI state.

## Backend And Data Updates

- Social repository supports watched, rating, review, favorite, watchlist, follow, unfollow, followers, and following operations.
- `SocialLibraryViewModel` exposes wrappers for the newer social actions.
- Supabase remains optional so the app can run with local storage fallback.
- Supabase schema documentation was updated in `docs/supabase/veil_social_schema.sql`.

## Verification

Recent verification included:

- `rtk flutter analyze`
- `rtk flutter test test/widget_test.dart`
- `rtk flutter test`
- Supabase migration retry after reauthentication
- Supabase advisory checks after the follow-table migration

The latest full Flutter test run passed with 41 tests.

