# Veil Design-First MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable Flutter mobile app that completes the supplied Veil design milestone with local fallback content and API-ready boundaries.

**Architecture:** Use a feature-oriented Flutter app with shared content models, fallback catalog data, reusable cinematic widgets, and a bottom-tab shell. The first pass focuses on design fidelity and navigation while avoiding committed API secrets.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Flutter widget tests, built-in icons and procedural poster/backdrop widgets.

---

## File Structure

- Create: `lib/main.dart` for app bootstrap and top-level navigation state.
- Create: `lib/core/theme/veil_theme.dart` for colors, text styles, and theme data.
- Create: `lib/shared/models/content_item.dart` for movie/show model data.
- Create: `lib/shared/models/alert_item.dart` for notification model data.
- Create: `lib/shared/data/mock_catalog.dart` for fallback catalog, search, rows, alerts, and profile content.
- Create: `lib/shared/widgets/veil_logo.dart` for the wordmark and mark.
- Create: `lib/shared/widgets/poster_art.dart` for procedural poster/backdrop art.
- Create: `lib/shared/widgets/section_header.dart` for row headers.
- Create: `lib/shared/widgets/content_cards.dart` for poster cards, backdrop cards, and metadata chips.
- Create: `lib/features/onboarding/onboarding_screen.dart` for splash-like onboarding.
- Create: `lib/features/shell/veil_shell.dart` for bottom navigation and tab switching.
- Create: `lib/features/home/home_screen.dart` for the home feed.
- Create: `lib/features/detail/detail_screen.dart` for content details and tabs.
- Create: `lib/features/search/search_screen.dart` for local search and genres.
- Create: `lib/features/player/player_screen.dart` for the trailer player UI.
- Create: `lib/features/alerts/alerts_screen.dart` for notification cards.
- Create: `lib/features/profile/profile_screen.dart` for profile/watchlist/settings.
- Modify: `test/widget_test.dart` for startup/navigation widget coverage.
- Create: `test/catalog_test.dart` for catalog behavior.

### Task 1: Scaffold Flutter Project

- [ ] **Step 1: Generate Flutter mobile project**

Run:

```bash
rtk proxy flutter create --platforms=ios,android .
```

Expected: Flutter creates iOS, Android, `lib/main.dart`, `pubspec.yaml`, and `test/widget_test.dart`.

- [ ] **Step 2: Inspect generated files**

Run:

```bash
rtk rg --files
```

Expected: generated Flutter project files are listed.

### Task 2: Write Failing Tests

- [ ] **Step 1: Replace generated tests with Veil behavior tests**

Write `test/catalog_test.dart` to assert catalog sections are non-empty, search for `wakanda` returns Black Panther, and the featured title exists.

Write `test/widget_test.dart` to assert the app starts on onboarding, tapping `Get started` reveals Home, tapping a content card opens a detail page, and tapping play opens the trailer screen.

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
rtk proxy flutter test
```

Expected: tests fail because Veil app classes, screens, and data are not implemented yet.

### Task 3: Implement Theme, Models, and Catalog

- [ ] **Step 1: Create design tokens**

Add `VeilTheme` with red accent, dark surfaces, text colors, Material theme, and helper gradients.

- [ ] **Step 2: Create content models**

Add immutable `ContentItem` and `AlertItem` classes with simple value constructors and fields used by all screens.

- [ ] **Step 3: Create fallback catalog**

Add curated content matching the design package: Wakanda Forever, Oppenheimer, Dune: Part Two, Peaky Blinders, Transformers, Tanhaji, Spider-Verse, Arcane, Joker, Furiosa, Godzilla x Kong, Past Lives, The Fall Guy, Monkey Man, and Challengers.

- [ ] **Step 4: Run catalog test**

Run:

```bash
rtk proxy flutter test test/catalog_test.dart
```

Expected: catalog tests pass or fail only on implementation typos that should be fixed immediately.

### Task 4: Implement Shared Design Widgets

- [ ] **Step 1: Create reusable brand and media widgets**

Implement `VeilLogo`, `PosterArt`, and `BackdropArt` using gradients, abstract glyphs, film grain, and title overlays.

- [ ] **Step 2: Create cards and section primitives**

Implement `SectionHeader`, `PosterCard`, `BackdropCard`, `MetaPill`, and compact action buttons.

- [ ] **Step 3: Run widget tests**

Run:

```bash
rtk proxy flutter test test/widget_test.dart
```

Expected: tests still fail on missing screens until screen implementation is complete.

### Task 5: Implement Screens and Navigation

- [ ] **Step 1: Replace `lib/main.dart`**

Bootstrap `VeilApp`, hold onboarding/tab/detail/player state, and apply `VeilTheme.dark()`.

- [ ] **Step 2: Add onboarding and shell**

Implement onboarding with poster collage, logo, headline, dots, and `Get started`. Implement `VeilShell` with Home, Search, Alerts, and Profile bottom tabs.

- [ ] **Step 3: Add Home and Detail**

Implement the home feed rows and detail page with full-bleed artwork, metadata, play/watchlist CTAs, tabs, cast, reviews, and technical details.

- [ ] **Step 4: Add Search, Player, Alerts, and Profile**

Implement local search, trailer player UI, notification list, and profile/watchlist/settings surfaces.

- [ ] **Step 5: Run widget tests and fix failures**

Run:

```bash
rtk proxy flutter test
```

Expected: tests pass after navigation and visible labels match the assertions.

### Task 6: Verify and Polish

- [ ] **Step 1: Analyze**

Run:

```bash
rtk proxy flutter analyze
```

Expected: no analyzer errors.

- [ ] **Step 2: Run all tests**

Run:

```bash
rtk proxy flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Build a debug APK**

Run:

```bash
rtk proxy flutter build apk --debug
```

Expected: debug APK build exits successfully.

- [ ] **Step 4: Final review**

Review the implemented screens against `/tmp/veil_design_extract` and the scope document, then document any deferred API work in the final response.
