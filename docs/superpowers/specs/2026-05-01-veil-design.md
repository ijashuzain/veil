# Veil Design Specification

## Summary

Veil is a Flutter mobile app for movie and TV discovery. The first completed milestone is a high-fidelity design-first MVP that mirrors the supplied Veil Design package: cinematic dark surfaces, red brand accent, poster-heavy browsing, detail metadata, trailer/player presentation, search, alerts, and profile surfaces.

The app must not claim to stream licensed full-length video. It is positioned as a discovery and trailer app powered by TMDB when credentials are supplied, with bundled fallback content so the design runs immediately.

## Approach Options

1. Design-first Flutter MVP with mock fallback data and API-ready boundaries.
   This is the recommended approach because it completes the requested design quickly, keeps the app runnable without secrets, and leaves clear seams for TMDB data.

2. Full TMDB-first implementation before design polish.
   This validates networking early, but slows the visible design milestone and makes local review dependent on credentials and network health.

3. Direct React design wrapper shipped as a web view.
   This preserves the mockup visually but fails the Flutter-native mobile app requirement and limits native navigation, performance, and store readiness.

## Product Scope

Must-have MVP screens:

- Splash and onboarding carousel with Veil branding, dark cinematic poster collage, and primary get-started CTA.
- Home feed with featured hero, category tabs, continue-watching row, global trending row, new releases row, and mood browsing grid.
- Search tab with query field, recent searches, result list, and genre browse tiles.
- Detail screen with full-bleed artwork, metadata chips, play trailer CTA, watchlist CTA, synopsis, action row, and tabs for episodes, cast, reviews, and details.
- Trailer player screen with cinematic background, center play affordance, title chrome, timeline, and controls.
- Alerts tab with unread/read notification cards.
- Profile tab with user card, watchlist preview, recently watched list, settings rows, and sign-out affordance.

Out of scope for the first completed design milestone:

- User accounts and authentication.
- Licensed full-length video playback.
- Payments, subscriptions, live TV, sports, desktop, and web release targets.

## Visual System

The design system is based on the supplied tokens:

- Primary accent: `#E50914`.
- Dark surfaces: `#050507`, `#0B0B0F`, `#14141A`, `#1C1C24`, `#26262F`.
- Text hierarchy: white, 72% white, 50% white, 32% white.
- Radii: 8, 12, 16, 22, and pill.
- Typography: Flutter uses platform fonts with display-style weight and tight hierarchy matching the Inter / Inter Tight mockup.
- UI language: full-bleed visual surfaces, translucent dark controls, rounded poster cards, horizontal rows, and red active states.

Because TMDB image credentials should not be hardcoded, the design milestone uses procedural poster and backdrop art derived from the React mockup palettes. Network images can later replace these widgets through the same content model.

## Architecture

The app uses a feature-oriented Flutter structure:

- `core/theme`: colors, typography, and reusable theme extensions.
- `core/router`: app route names and navigation setup.
- `shared/models`: content and notification models.
- `shared/data`: fallback catalog data.
- `shared/widgets`: logo, poster art, section headers, pills, shell/navigation primitives.
- `features/onboarding`, `features/home`, `features/detail`, `features/search`, `features/player`, `features/alerts`, and `features/profile`: screen-level widgets.

For this milestone, content comes from the fallback catalog. API integration will be added behind a repository interface so UI widgets remain driven by the same `ContentItem` model.

## Navigation

The bottom navigation has four top-level tabs: Home, Search, Alerts, and Profile. Detail and Player are pushed from content cards and CTAs. Onboarding appears first in the app flow and transitions into the tab shell after `Get started`.

The design milestone keeps onboarding state in memory so the complete flow is easy to review during development. Persistent first-run storage can be added with Hive after the API/data milestone.

## Error Handling

The design milestone avoids network failure states by using local fallback data. UI states that prepare for later dynamic data include:

- Empty-search copy when a query has no local match.
- Detail tabs with stable fallback content.
- Non-destructive watchlist and action buttons that give visual feedback without requiring accounts.

When TMDB is wired in, network failures should fall back to cached or bundled content and expose a concise retry affordance.

## Testing

Automated tests cover:

- Catalog integrity and search filtering.
- App startup on onboarding.
- Navigation from onboarding to home.
- Detail/player navigation from content CTAs.
- Search rendering for a known query.

Manual verification covers `flutter analyze`, `flutter test`, and at least one platform build command that does not require a simulator.

## Completion Criteria

The design milestone is complete when:

- The Flutter project builds from an empty checkout.
- All supplied core screens are represented natively in Flutter.
- The UI uses the Veil tokens and cinematic layout language from the design package.
- The app runs without exposing API credentials.
- Tests and analyzer pass.
