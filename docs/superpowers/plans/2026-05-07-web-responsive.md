# Veil Web Responsive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the entire Veil Flutter app web-supported and responsive across mobile, tablet, and desktop widths without regressing the existing v2 redesign or Shorebird integration.

**Architecture:** Add a small shared responsive layout layer, wire web platform support, then apply breakpoint-aware shells, content constraints, and grid/list layouts across core screens.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, current Veil theme/components, Flutter web platform output.

---

## Task 1: Web Platform Target

**Files:**
- Create/modify generated platform files under `/Users/ijashuzain/Project/flutter/veil/web`
- Modify generated metadata only if Flutter tooling requires it

- [x] Run `rtk flutter create --platforms=web .` from `/Users/ijashuzain/Project/flutter/veil`.
- [x] Confirm `web/index.html`, `web/manifest.json`, and web icons exist.
- [x] Do not hand-edit generated files unless build output requires a targeted fix.
- [x] Run `rtk flutter build web` once after implementation tasks are complete.

## Task 2: Shared Responsive Layout Primitives

**Files:**
- Create: `/Users/ijashuzain/Project/flutter/veil/lib/src/shared/layout/veil_breakpoints.dart`
- Create: `/Users/ijashuzain/Project/flutter/veil/lib/src/shared/layout/adaptive_content.dart`
- Test: `/Users/ijashuzain/Project/flutter/veil/test/widget_test.dart`

- [x] Add `VeilBreakpoint` with mobile/tablet/desktop lookup from `MediaQuery.sizeOf(context).width`.
- [x] Add helpers for `isMobile`, `isTablet`, `isDesktop`, `pageGutter`, `contentMaxWidth`, `gridColumns`, and `detailHeroHeight`.
- [x] Add `AdaptiveContent` for centered box content with responsive horizontal padding and max width.
- [x] Add `AdaptiveSliverPadding` for responsive sliver gutters.
- [x] Add tests for mobile and desktop breakpoint behavior through visible layout changes in the shell.

## Task 3: Adaptive Shell Navigation

**Files:**
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/shell/view/veil_shell_view.dart`
- Test: `/Users/ijashuzain/Project/flutter/veil/test/widget_test.dart`

- [x] Extract tab metadata into a small constant/list so bottom navigation and rail share labels/icons.
- [x] Keep mobile bottom navigation unchanged in behavior.
- [x] Add `NavigationRail` for tablet/desktop widths.
- [x] Preserve `_loadedTabs` lazy loading.
- [x] Add widget tests proving mobile shows the bottom nav and desktop shows `NavigationRail`.

## Task 4: Core Screen Constraints And Grids

**Files:**
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/home/view/home_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/catalog/view/see_all_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/social/view/diary_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/social/widgets/diary_poster_grid.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/reviews/view/reviews_view.dart`
- Test: `/Users/ijashuzain/Project/flutter/veil/test/widget_test.dart`

- [x] Wrap Home header, hero, category header, rails, selected genre list/grid, and footer spacing with responsive gutters/max widths.
- [x] Change selected genre results to a responsive grid on desktop and keep the current list on mobile/tablet.
- [x] Make `SeeAllView` grid columns and padding responsive.
- [x] Make `DiaryPosterGrid` use responsive cross-axis counts instead of a fixed phone count.
- [x] Constrain Reviews list content and header width.
- [x] Add desktop widget tests for Home and Diary rendering without overflow.

## Task 5: Detail, Search, Profile, Alerts, Onboarding

**Files:**
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/detail/view/detail_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/search/view/search_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/profile/view/profile_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/user_profile/view/user_profile_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/alerts/view/alerts_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/onboarding/view/onboarding_view.dart`
- Modify: `/Users/ijashuzain/Project/flutter/veil/lib/src/features/player/view/player_view.dart`

- [x] Scale Detail hero height by breakpoint and center/constrain the body.
- [x] Wrap Search, Profile, User Profile, Alerts, and Reviews-style list surfaces in `AdaptiveContent`.
- [x] Make Onboarding/Auth use a bounded desktop width while keeping mobile behavior intact.
- [x] Preserve Player full-bleed behavior while protecting controls from excessive width.
- [x] Avoid unrelated visual redesign or backend changes.

## Task 6: Verification And Cleanup

**Files:**
- Format touched Dart files and tests.
- No commit unless explicitly requested.

- [x] Run `rtk dart format lib test`.
- [x] Run `rtk flutter analyze`.
- [x] Run `rtk flutter test`.
- [x] Run `rtk flutter build web`.
- [x] Fix every failure caused by this work.
- [x] Report verification results and changed files.
