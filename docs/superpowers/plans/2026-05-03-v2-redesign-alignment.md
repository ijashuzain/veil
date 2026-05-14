# Veil V2 Redesign Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the Flutter app with the latest `/Users/ijashuzain/Desktop/Veil_v2` redesign while preserving Veil's own compact, professional visual language and the social features already added.

**Architecture:** Treat the v2 JSX/CSS files as a design source, not code to copy directly. Keep Riverpod state and the existing Supabase/local fallback social repository intact, split oversized private widgets into focused feature widgets where a screen is already getting heavy, and make visual-only improvements without forcing new backend work unless a v2 feature genuinely needs persistence.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Freezed models, Supabase optional storage, TMDB data, existing `PosterArt`/`BackdropArt` shared components, existing `VeilTheme`.

---

## V2 Inputs Reviewed

- `/Users/ijashuzain/Desktop/Veil_v2/index.html`
- `/Users/ijashuzain/Desktop/Veil_v2/tokens.css`
- `/Users/ijashuzain/Desktop/Veil_v2/components.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/design-canvas.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/ios-frame.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/tweaks-panel.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/home.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/detail.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/sheets.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/diary.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/search-v2.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/profile-v2.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/search-profile.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/player-alerts.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/screens/onboarding.jsx`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/veil_scope.docx`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/veil_scope-cc926425.docx`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/recent-feature-updates.md`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/IMG_6728.jpg`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/IMG_6729.PNG` through `/Users/ijashuzain/Desktop/Veil_v2/uploads/IMG_6737.PNG`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/original-f017a445a88712ffa871b78d6b0fa8b3.webp`
- `/Users/ijashuzain/Desktop/Veil_v2/uploads/original-f017a445a88712ffa871b78d6b0fa8b3-e2bf3405.webp`

## 2026-05-03 V2 Recheck Notes

- `index.html` is the current source-of-truth canvas for the refreshed v2 target. It defines these artboards: Splash, Onboarding, Home, Detail, Trailer Player, Action Sheet, Review Sheet, Diary, Diary Filter Sheet, Search Recent, Search Results, Profile Self, Profile Other User, Alerts, and legacy Search/Profile references.
- `design-canvas.jsx`, `ios-frame.jsx`, and `tweaks-panel.jsx` are design tooling. Do not port them into Flutter. Use them only to understand viewport framing, iOS safe-area expectations, and the currently selected accent/density options.
- `search-profile.jsx` includes older legacy search/profile references. Use `search-v2.jsx` and `profile-v2.jsx` as the implementation target unless a task explicitly says to preserve behavior from the current Flutter app.
- `player-alerts.jsx` confirms the player and alerts visual direction. The existing Flutter player already resembles this screen, so only polish spacing/controls if tests or manual QA reveal mismatch.
- The uploaded scope documents still describe an older trailer/discovery MVP with no auth. The current Flutter app has Supabase auth/social features; keep those newer app features and do not regress to local-only MVP scope.

## Current App Baseline

- `lib/src/core/theme/veil_theme.dart` already has the v2 red, graphite surfaces, gold rating accent, text levels, and hairlines.
- `lib/src/features/home/view/home_view.dart` already has the v2-style top greeting, hero, category tabs, all-category rails, and selected-genre vertical paginated list.
- `lib/src/features/detail/view/detail_view.dart` already has the full hero, rating/action panel, social bottom sheet, review sheet, 1-5 user rating, and IMDb playback redirect flow.
- `lib/src/features/social/view/diary_view.dart` already has Diary stats, Watched/Watchlist/Favorites tabs, compact 4-column grid, and inline genre/rating filters.
- `lib/src/features/search/view/search_view.dart` already has All/Users/Films/Cast scopes and vertical result rows.
- `lib/src/features/profile/view/profile_view.dart` and `lib/src/features/user_profile/view/user_profile_view.dart` already show follow counts/lists and follow/unfollow.
- `lib/src/features/alerts/view/alerts_view.dart` and `lib/src/features/onboarding/view/onboarding_view.dart` already broadly match the v2 direction.

## Product Decisions

- Keep Veil's own palette: graphite surfaces, red for primary actions only, gold for ratings. Do not copy the reference green or the prototype's one-note red blocks.
- Keep the previous product scope for the detail action sheet: Watched, Like, Watchlist, Rate, Review, first-time/rewatch, Done. The refreshed `screens/sheets.jsx` still shows prototype-only rows like Add to lists, Change poster/backdrop, Share to Instagram, and Share; do not implement those rows unless explicitly requested again.
- Diary filters must move from inline chip rows to a bottom sheet. This is the most important v2 delta.
- Review tags can be added using existing `SocialEntry.tags` without a schema migration. Treat `first-time` and `rewatch` as reserved watch-kind tags; user-entered tags should be stored alongside them.
- Profile activity can initially derive from existing social entries and global reviews. Do not introduce a new activity table in this redesign pass.
- Continue Watching on Home appears in the refreshed canvas, but the app does not currently persist playback progress. For this pass, either omit it or derive a clearly non-persistent preview from mock/current detail data only. Persistent progress should be a later feature.
- The current bottom navigation includes Diary instead of the design canvas's older Search/Alerts split. Preserve the real Flutter navigation model unless the user requests a navigation IA change.

## File Structure

- Modify `lib/src/core/theme/veil_theme.dart`: add small reusable durations, sheet radius, chip radius, and rating/star text helpers if needed.
- Create `lib/src/shared/components/veil_filter_chips.dart`: compact selectable chip used by Diary/Search/Profile filters.
- Create `lib/src/shared/components/veil_sheet.dart`: shared modal sheet shell with handle, header, footer, safe-area padding, and neutral surface styling.
- Create `lib/src/shared/components/ratings_display.dart`: reusable read-only star rows and compact histogram bars.
- Modify `lib/src/features/social/view/diary_view.dart`: remove inline filters, add toolbar, active filter summary, sort/year filters, and wire bottom sheet.
- Create `lib/src/features/social/widgets/diary_filter_sheet.dart`: bottom sheet UI and filter result model.
- Create `lib/src/features/social/widgets/diary_poster_grid.dart`: move grid/tile/star footer out of `diary_view.dart`.
- Modify `lib/src/features/detail/view/detail_view.dart`: keep behavior, refine spacing, split action/review sheet widgets.
- Create `lib/src/features/detail/widgets/detail_social_action_sheet.dart`: social action sheet contents.
- Create `lib/src/features/detail/widgets/detail_review_sheet.dart`: review composer with rating, watch kind, review text, and optional tags.
- Create `lib/src/features/detail/widgets/detail_rating_panel.dart`: ratings histogram and `Rate, log, review + more` pill.
- Modify `lib/src/features/search/view/search_view.dart`: add recent searches, scope counts, tighter focused/results states, and clearer empty states.
- Modify `lib/src/features/profile/view/profile_view.dart`: move to v2 profile header, stats row, tabs for Following/Followers/Activity.
- Modify `lib/src/features/user_profile/view/user_profile_view.dart`: mirror profile v2 for other users and replace inline filters with the same compact filter sheet pattern if keeping diary entries on profiles.
- Modify `lib/src/features/home/view/home_view.dart`: small polish only; current home already matches the main v2 direction.
- Modify `lib/src/features/alerts/view/alerts_view.dart`: small polish only; current alerts already matches the v2 direction.
- Modify `lib/src/features/player/view/player_view.dart`: small polish only if needed to match `player-alerts.jsx`; do not change playback/routing behavior in this visual redesign task.
- Modify `test/widget_test.dart`: add widget coverage for the new sheet flows, search recent/scopes, and profile tabs.
- Modify `test/social_repository_test.dart`: add tag preservation tests if review tags are implemented.

## Task 1: Shared Design Components

**Files:**
- Modify: `lib/src/core/theme/veil_theme.dart`
- Create: `lib/src/shared/components/veil_filter_chips.dart`
- Create: `lib/src/shared/components/veil_sheet.dart`
- Create: `lib/src/shared/components/ratings_display.dart`
- Test: `test/widget_test.dart`

- [ ] Add compact visual helpers to `VeilColors`/`VeilTheme` only when reused by at least two screens: `sheetRadius`, `controlRadius`, `chipHeight`, and a gold star style.
- [ ] Implement `VeilChoiceChip` with selected, leading icon, compact height, horizontal padding, and no oversized full-red selected state by default.
- [ ] Implement `VeilSheetScaffold` with a drag handle, optional `leading`, `title`, `trailing`, content, and optional footer button.
- [ ] Move star rows and small rating bars from `detail_view.dart`/`diary_view.dart` into `ratings_display.dart`.
- [ ] Add a small widget test that pumps a `VeilChoiceChip` selected/unselected and verifies label/icon colors do not overflow.
- [ ] Run `rtk dart format lib/src/core/theme/veil_theme.dart lib/src/shared/components/veil_filter_chips.dart lib/src/shared/components/veil_sheet.dart lib/src/shared/components/ratings_display.dart test/widget_test.dart`.
- [ ] Run `rtk flutter test test/widget_test.dart`.

## Task 2: Diary V2 With Bottom-Sheet Filters

**Files:**
- Modify: `lib/src/features/social/view/diary_view.dart`
- Create: `lib/src/features/social/widgets/diary_filter_sheet.dart`
- Create: `lib/src/features/social/widgets/diary_poster_grid.dart`
- Test: `test/widget_test.dart`

- [ ] Replace `_CompactFilters` with a toolbar under the tabs: left text like `12 watched · recent`, right compact `Filter` button with a badge count when filters are active.
- [ ] Add filter state to `DiaryView`: selected tab, selected genre, minimum rating, sort mode, release-year filter.
- [ ] Implement sort modes: `recent`, `highestRated`, `lowestRated`, `az`, `year`.
- [ ] Implement year filters: `any`, `from2024`, `from2020`, `from2010`, `from2000`, `older`.
- [ ] Keep Watched/Watchlist/Favorites as top tabs. Each tab remains a full page and keeps the 4-column grid.
- [ ] Match v2 grid footer behavior:
  - Watched: star row under poster.
  - Watchlist: year under poster.
  - Favorites: heart icon or favorite mark under poster.
- [ ] Add an active filter strip only when filters are active. Include chips like `Action`, `4.0+`, `2020s`, `Highest rated`, and a clear button.
- [ ] Add `showModalBottomSheet` using `DiaryFilterSheet` with Reset, title `Filter & sort`, close icon, grouped chips, and footer button `Show N results`.
- [ ] Reset filters when switching tabs only for tab-specific genre if it no longer exists; preserve rating/sort/year because those are global filters.
- [ ] Add widget test: open Diary, tap `Filter`, verify `Filter & sort`, `Sort by`, `Genre`, `Minimum rating`, and `Release year` appear.
- [ ] Add widget test: select `4.0+`, apply, verify the active badge/strip appears and lower-rated entries are hidden.
- [ ] Add widget test: switch to Watchlist and verify poster footers show year instead of star rows.
- [ ] Run `rtk flutter test test/widget_test.dart --name diary`.

## Task 3: Detail Page And Social Sheets Polish

**Files:**
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Create: `lib/src/features/detail/widgets/detail_rating_panel.dart`
- Create: `lib/src/features/detail/widgets/detail_social_action_sheet.dart`
- Create: `lib/src/features/detail/widgets/detail_review_sheet.dart`
- Test: `test/widget_test.dart`

- [ ] Keep the v2 full-bleed hero but refine it for real TMDB art: avoid over-darkening posters, keep text readable, and ensure title/subtitle do not overlap on small screens.
- [ ] Move `_RatingsActionPanel`, `_MiniRatingBars`, `_ReadOnlyStars`, `_ActionSheetCard`, `_SheetActionButton`, `_SheetRowButton`, `_StarRatingSelector`, and `_WatchKindToggle` into focused widgets.
- [ ] Rename the sheet row from `Review` to `Review or log` only if product wording still wants both actions. Otherwise keep the cleaner `Review`.
- [ ] Preserve current actions only: Watched, Like, Watchlist, Rate, Review, first-time/rewatch, Done.
- [ ] Do not add the prototype-only rows from `screens/sheets.jsx`: Add to lists, Change poster/backdrop, Share to Instagram, Share.
- [ ] Use gold for selected stars and a restrained red/graphite selected state for Watched/Like/Watchlist.
- [ ] Update review sheet to the v2 structure: top header with Cancel, `I Watched...`, Save; movie row; date/like row; rate row; first-time/rewatch segmented control; review text area.
- [ ] Add optional tag input using existing `SocialEntry.tags`. Save tags as `[watchKind, ...reviewTags]` and avoid duplicating reserved tags.
- [ ] Keep saving a rating or review auto-marking the title watched.
- [ ] Add widget test: tapping `Rate, log, review + more` opens the sheet and shows Watched, Like, Watchlist, Rate, Review, Done.
- [ ] Add widget test: review save is disabled without both rating and text.
- [ ] Add widget/repository test: review save stores watch kind and custom tags while preserving 1-5 rating.
- [ ] Run `rtk flutter test test/widget_test.dart --name detail`.

## Task 4: Search V2

**Files:**
- Modify: `lib/src/features/search/view/search_view.dart`
- Test: `test/widget_test.dart`

- [ ] Convert the default search screen into a focused v2 layout: search field, Cancel/back behavior when pushed, scope chips, recent searches, and clear recent.
- [ ] Add recent searches in local widget state first. Each recent row should show the query text and a right-side scope tag like `All`, `Users`, `Films`, or `Cast`. Persisting recent searches can be a later storage task unless requested.
- [ ] Change placeholder to `Find films, cast + crew, members...`.
- [ ] Add result counts to scope chips when a query has results: `All`, `Users`, `Films`, `Cast`.
- [ ] Keep `All` showing both app users and TMDB content.
- [ ] Keep `Users` based on current `globalReviews` user derivation.
- [ ] Keep `Films` for movie/TV results.
- [ ] Treat `Cast` as person/cast/studio results when TMDB returns those types; otherwise show a clear empty state instead of pretending movie results are cast.
- [ ] Redesign result rows to v2 compact list: poster/avatar, title, type/year/genre, rating row, trailing circular action/navigation button.
- [ ] Keep `search-v2.jsx` as the target. Use `search-profile.jsx` only as a legacy reference for existing behavior that must not regress.
- [ ] Add widget test: entering a query adds it to recent searches after search.
- [ ] Add widget test: tapping scope chips changes visible sections.
- [ ] Add widget test: clear recent removes recent search rows.
- [ ] Run `rtk flutter test test/widget_test.dart --name search`.

## Task 5: Profile V2 And Social Tabs

**Files:**
- Modify: `lib/src/features/profile/view/profile_view.dart`
- Modify: `lib/src/features/user_profile/view/user_profile_view.dart`
- Test: `test/widget_test.dart`

- [ ] Replace the current nested follow-list card with v2 profile structure: header row, avatar/name/email or handle, settings button for self, follow/unfollow button for others.
- [ ] Keep a compact single stats row with Watched, Reviews, Favorites, Following, Followers.
- [ ] Add tabs: Following, Followers, Activity.
- [ ] Following tab shows member rows with avatar, display name, short handle, and `Following`/`Follow` button where applicable.
- [ ] Followers tab shows member rows with `Follows you`/`Follow back` state where derivable.
- [ ] Activity tab shows recent social entries/reviews from current available data. Use `globalReviews` for community-like activity and local entries for mine.
- [ ] Use `profile-v2.jsx` as the target for both self and other-user profile layouts. Do not copy the legacy red gradient profile card from `search-profile.jsx`.
- [ ] Make stats tappable to switch to the matching tab for Following/Followers.
- [ ] Mirror the same structure in `UserProfileView`, preserving follow/unfollow and current user's self-detection.
- [ ] Replace `@userIdPrefix` helper text only if a richer display name is available; otherwise keep stable generated handles.
- [ ] Add widget test: Profile shows the three tabs and switches between empty following/follower states.
- [ ] Add widget test: User profile follow/unfollow button still calls repository and updates state.
- [ ] Run `rtk flutter test test/widget_test.dart --name profile`.

## Task 6: Home, Player, Alerts, Onboarding, And Shell Polish

**Files:**
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `lib/src/features/player/view/player_view.dart`
- Modify: `lib/src/features/alerts/view/alerts_view.dart`
- Modify: `lib/src/features/onboarding/view/onboarding_view.dart`
- Modify: `lib/src/features/shell/view/veil_shell_view.dart`
- Test: `test/widget_test.dart`

- [ ] Leave Home's selected genre/category behavior intact: All uses existing rails; other genres use vertical paginated list and keep See All.
- [ ] Apply only polish from v2: tighter hero metadata, dot indicators if useful, ranked trending readability, and no text overlap.
- [ ] Do not add persistent Continue Watching until playback progress exists. If a visual preview is needed, derive a static non-persistent rail from existing mock data and label it honestly.
- [ ] Keep `PlayerView` behavior intact. If polishing, match `player-alerts.jsx` only for top controls, center play treatment, progress bar, and bottom controls; do not replace the existing embedded-player redirect flow.
- [ ] Keep Alerts close to current implementation; tighten spacing, unread state, and header action.
- [ ] Keep Onboarding close to current poster collage/auth form; adjust copy only if it fits the real authenticated app, not the older no-auth scope doc.
- [ ] Confirm bottom navigation active pill is compact and does not overflow labels on 390px-wide mobile screens.
- [ ] Add/adjust widget test for Home selected genre vertical list and pagination footer.
- [ ] Run `rtk flutter test test/widget_test.dart --name home`.

## Task 7: Data And Supabase Review

**Files:**
- Modify: `lib/src/features/social/repository/social_repository.dart`
- Modify: `lib/src/features/social/view_model/social_library_view_model/social_library_view_model.dart`
- Modify: `docs/supabase/veil_social_schema.sql`
- Test: `test/social_repository_test.dart`

- [ ] If review tags are implemented, confirm `tags` already round-trips through local and Supabase paths. It does, but tests should cover reserved and custom tag combinations.
- [ ] Do not add a new Supabase migration for visual-only redesign.
- [ ] Add a migration only if a new persisted concept is introduced. Current plan avoids that.
- [ ] Keep follow storage exactly as already added: `user_follows` table with local fallback.
- [ ] Add repository test: `rateReview` with `['first-time', 'mind-bending']` stores both tags and marks watched.
- [ ] Add repository test: updating from first-time to rewatch replaces the reserved watch-kind tag and preserves custom tags.
- [ ] Run `rtk flutter test test/social_repository_test.dart`.

## Task 8: Verification And QA

**Files:**
- No new files unless screenshots are intentionally saved under an agreed QA folder.

- [ ] Run `rtk dart format lib test`.
- [ ] Run `rtk flutter analyze`.
- [ ] Run `rtk flutter test`.
- [ ] Run `rtk flutter build apk --debug`.
- [ ] If an iOS simulator is available, run `rtk flutter build ios --simulator --debug`.
- [ ] Manually inspect these screens on a narrow mobile viewport/device:
  - Onboarding/auth
  - Home with All selected
  - Home with a genre selected and paginated
  - Detail hero
  - Detail action sheet
  - Detail review sheet with keyboard open
  - Trailer/player controls
  - Diary Watched/Watchlist/Favorites
  - Diary filter bottom sheet
  - Search empty/focused/results states
  - Profile self and other user profile
  - Alerts
- [ ] Check that no selected state uses copied green reference styling.
- [ ] Check that no page has oversized red blocks except true primary actions.
- [ ] Check that all text fits on a 390px-wide mobile screen.
- [ ] Check that modal sheets respect keyboard and safe-area insets.

## Suggested Execution Order

1. Shared components.
2. Diary bottom-sheet filters.
3. Detail sheet extraction and review polish.
4. Search v2.
5. Profile v2.
6. Home/Alerts/Onboarding/Shell polish.
7. Data tests for tags, if tags ship.
8. Full verification.

This order gives a visible win early with Diary filters, then reduces risk by reusing shared components across the remaining screens.

## Coverage Check

- Diary bottom-sheet filters: Task 2.
- Compact professional UI, not copied references: Tasks 1, 3, 4, 5, 6, 8.
- Detail rating/action/review sheets: Task 3.
- 1-5 app rating and watched auto-add behavior: already present, preserved in Tasks 3 and 7.
- Diary watched/watchlist/favorites tabs and 4-column grid: already present, refined in Task 2.
- Search All/Users/Films/Cast: already present, refined in Task 4.
- Follow/followers/following in profiles: already present, refined in Task 5.
- Home genre vertical pagination: already present, preserved in Task 6.
- Supabase: no new migration required unless review tags become a normalized table; Task 7 covers confirmation.
