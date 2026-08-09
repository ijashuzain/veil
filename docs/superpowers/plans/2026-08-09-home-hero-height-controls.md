# Home Hero Height And Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce Home hero height by 25 percent, remove its app mark, and place Search at top left.

**Architecture:** Change `VeilLayout.homeHeroHeight` source values so sliver geometry remains correct. Simplify hero top row without scaling content or changing callbacks.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Mobile height uses factor `.51` and bounds `420–510`.
- Tablet height is `450`; desktop height is `465`.
- Search remains functional at top left; Alerts remains functional at top right.
- Preserve all hero content, gradients, actions, rotation, and category placement.
- Do not modify unrelated iOS changes or commit.

---

### Task 1: Resize Hero And Simplify Top Controls

**Files:**
- Modify: `lib/src/shared/layout/veil_breakpoints.dart`
- Modify: `lib/src/features/home/widgets/home_cinematic_hero.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `VeilLayout.homeHeroHeight(BuildContext)` and existing Search/Alerts callbacks.
- Produces: 25-percent shorter hero and Search-left/Alerts-right top row.

- [ ] **Step 1: Update hero expectations to fail**

```dart
expectCinematicGeometry(width: 390, height: 844 * .51);
expect(find.byKey(const ValueKey('home-hero-logo')), findsNothing);
expect(find.byKey(const ValueKey('home-hero-search')), findsOneWidget);
expect(find.byKey(const ValueKey('home-hero-alerts')), findsOneWidget);
```

Keep desktop expectation at `465`.

- [ ] **Step 2: Run focused test and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "home hero is full bleed"`

Expected: FAIL on old height and existing logo.

- [ ] **Step 3: Apply exact dimensions and top row**

```dart
static double homeHeroHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (VeilBreakpoint.of(context).isDesktop) return 465;
  if (VeilBreakpoint.of(context).isTablet) return 450;
  return (size.height * .51).clamp(420.0, 510.0);
}
```

Replace logo/search/spacer/alerts row with Search/spacer/Alerts. Remove unused asset/logo code only.

- [ ] **Step 4: Format and verify**

Run: `dart format lib/src/shared/layout/veil_breakpoints.dart lib/src/features/home/widgets/home_cinematic_hero.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Run: `flutter analyze`

Run: `git diff --check`

Expected: all focused tests pass, analyzer has no issues, diff check clean.
