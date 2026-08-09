# Home Discovery Rail Fixes Design

**Date:** 2026-08-09
**Status:** Approved

## Goal

Restore provider and curated artwork loading, then reduce Home discovery sections to requested rail-only presentation.

## Root Causes

- Veil's Supabase TMDB function rejects `/3/watch/providers/*` because `watch` is absent from `allowedRoutes`.
- Shegu curated posters use TMDB `w200` URLs. Veil rewrites them through `tmdb-image`, where `w200` is absent from `allowedSizes`, producing HTTP 403.

## Backend Changes

- Add `watch` to `supabase/functions/tmdb/index.ts` allowed routes.
- Add `w200` to `supabase/functions/tmdb-image/index.ts` allowed sizes.
- Keep existing route, host, method, and path traversal protections unchanged.
- Deploy both functions to configured Veil Supabase project after local verification.
- Confirm live provider endpoint returns HTTP 200 JSON and live `w200` image request returns an image response.

## Provider Rail

- Loaded: show provider logo/name cards only.
- Loading: show horizontal square skeleton cards only.
- Error: render nothing.
- Remove `Watch by provider` heading.
- Remove provider retry button and error row.
- Keep provider card navigation and provider detail screen unchanged.

## Curated Rail

- Remove `Curated collections` heading.
- Keep horizontal collection choice tabs.
- Remove repeated selected collection title and description below tabs.
- Render selected collection posters directly below tabs.
- Preserve prior successful posters while another tab loads, with compact progress indicator.
- Keep compact curated retry behavior for metadata/item failures.
- Keep poster navigation and defensive Shegu parsing unchanged.

## Home Order

For the All feed, use this order:

1. Continue Watching, when non-empty
2. Provider rail
3. Global trending
4. New this week
5. Curated tabs and poster rail
6. Popular movies
7. Top rated movies
8. Top rated TV
9. Airing today

Selected genre layout remains unchanged.

## Playback Sheet

- Change Server 2 button text from `Server 2 · Cinejoy` to `Server 2`.
- Keep Cinejoy URL construction and behavior unchanged.

## Testing

- Assert TMDB proxy permits `watch` root route while still rejecting unknown roots.
- Assert image proxy permits `w200` while still rejecting unsupported sizes and traversal.
- Assert provider loaded/loading/error states contain no heading or retry control.
- Assert curated loaded state contains tabs and posters but no section or repeated collection heading/description.
- Assert curated section appears after New this week and before Popular movies.
- Assert playback sheet displays exact `Server 2` label.
- Run focused tests, full Flutter tests, analyzer, deployment, and live endpoint checks.

## Non-Goals

- No provider detail redesign.
- No region selector.
- No Shegu schema expansion.
- No playback mechanism changes.
- No navigation changes.
