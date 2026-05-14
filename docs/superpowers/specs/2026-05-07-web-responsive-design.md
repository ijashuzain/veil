# Veil Web Responsive Design Specification

## Summary

Veil must become a responsive Flutter app that supports web as a first-class target while preserving the current v2 mobile experience. Mobile should keep the compact bottom-navigation app. Tablet and desktop/web should use wider, calmer layouts that fit the available screen instead of stretching phone views.

This pass treats responsive behavior as an app-wide layout system, not a one-off visual patch. Shared breakpoints, content width constraints, adaptive navigation, and adaptive grids should be introduced first, then applied across the core screens.

## Current Baseline

- The project has Android and iOS platform folders, but no `web/` folder yet.
- `lib/main.dart` wraps the app with `TheResponsiveBuilder` at a mobile baseline of 390 x 844.
- `lib/src/features/shell/view/veil_shell_view.dart` currently uses a phone-first `Scaffold` with a bottom navigation bar for all screen sizes.
- The major feature views are mostly mobile-first:
  - Home uses a vertical `CustomScrollView` with horizontal rails.
  - Detail uses a tall phone hero followed by a single column.
  - Diary uses fixed compact poster-grid behavior.
  - Search, Reviews, Alerts, Profile, and Onboarding use phone-oriented padding and card widths.
- The prior v2 redesign work is already present and should not be undone.
- Shorebird update checks are already guarded for unsupported platforms/debug contexts and must not block web startup.

## Responsive Targets

Use these product breakpoints consistently:

- Mobile: less than 700 logical pixels wide.
- Tablet: 700 to 1023 logical pixels wide.
- Desktop/web: 1024 logical pixels wide and above.

Mobile behavior:

- Preserve the existing bottom navigation and phone-dense vertical flows.
- Keep current visual density and v2 mobile polish.
- Ensure all labels fit at 390 px wide.

Tablet behavior:

- Constrain content to readable widths.
- Use wider grids and moderate page gutters.
- Prefer a navigation rail when the viewport has enough width for it without crowding content.

Desktop/web behavior:

- Use a left-side `NavigationRail` in the shell.
- Center content areas with max-width constraints instead of full-window stretched phone layouts.
- Increase grid columns and rail density where appropriate.
- Keep player/media surfaces immersive and full-bleed when that is the expected experience.

## Product Decisions

- Keep the current top-level tabs: Home, Diary, Reviews, Profile.
- Do not replace the existing product flow with a marketing website or landing page.
- Do not regress the v2 redesign changes already completed.
- Do not add new persistence or backend requirements for responsive layout.
- Do not require Shorebird behavior on web. Web support and Shorebird patching are separate platform concerns.
- Use Flutter-native responsive primitives and the existing theme/components. Do not add a new UI framework.

## Layout System

Create shared layout helpers under `lib/src/shared/layout/`:

- `VeilBreakpoint`: mobile, tablet, desktop.
- Width helpers for content max-width, page gutter, and grid column count.
- `AdaptiveContent`: centers and constrains normal page content.
- `AdaptiveSliverPadding`: applies responsive horizontal gutters in slivers.
- Optional reusable primitives for responsive sliver grids/lists when they remove duplication.

The shared helpers should be small, explicit, and easy to test. Screens should read as normal Flutter code with a clear breakpoint decision near the layout boundary.

## Screen Requirements

Shell:

- Mobile uses bottom navigation.
- Tablet/desktop uses `NavigationRail` with icons and labels.
- Tab lazy-loading behavior remains intact.

Home:

- Header and category tabs respect responsive gutters and max-widths.
- Hero uses a wider desktop height and constrained content.
- Default rails stay horizontal on mobile/tablet and become more comfortable on desktop.
- Selected genre results become a responsive grid/list treatment instead of a narrow phone list stretched across the browser.

Detail:

- Mobile keeps the current vertical hero/details flow.
- Desktop uses a wider constrained layout with readable details and action panel spacing.
- Hero height scales down/up by breakpoint so text and metadata do not overlap.

Diary:

- Poster grid columns adapt by width.
- Filters and stats remain usable on tablet/desktop without stretched phone cards.

Search, Reviews, Alerts, Profile, User Profile:

- Wrap content with responsive gutters and max-widths.
- Increase poster/list widths only where useful.
- Keep lists readable, with long text constrained.

Onboarding/Auth:

- Keep mobile onboarding/auth intact.
- On tablet/desktop, center the auth form in a bounded panel and allow the poster collage to use the extra width without overflowing.

Player:

- Preserve full-bleed video/player treatment.
- Ensure controls do not overlap on wide or narrow web viewports.

## Testing

Add widget tests that prove responsive behavior is real:

- Shell uses bottom navigation on a 390 x 844 mobile viewport.
- Shell uses `NavigationRail` on a 1200 x 900 desktop viewport.
- Home can render at desktop width without layout exceptions and still exposes the existing primary content.
- Diary poster grid renders without overflow at desktop width.

Run full verification:

- `rtk flutter create --platforms=web .`
- `rtk dart format lib test`
- `rtk flutter analyze`
- `rtk flutter test`
- `rtk flutter build web`

## Completion Criteria

The responsive-web pass is complete when:

- A Flutter web target exists and `flutter build web` succeeds.
- Mobile, tablet, and desktop breakpoints have distinct layout behavior.
- The shell changes navigation layout by screen size.
- Core screens are constrained/adaptive rather than stretched phone layouts.
- Existing v2 redesign behavior and tests still pass.
