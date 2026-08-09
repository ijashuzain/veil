# Home Hero Category Overlap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overlap Home category tabs 32 pixels into hero and replace hero plus/info capsule with one rounded plus button.

**Architecture:** Compose hero and in-flow category tabs in one fixed-height stack, then swap in an overlay category bar once scroll crosses its pin threshold. Keep existing scroll notification responsible for genre pagination and add pin-state updates without changing data flow.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Category tabs overlap hero by exactly 32 logical pixels.
- Provider and later sections move upward with overlap geometry.
- Sticky tabs remain below current status-bar inset.
- Only one interactive category rail exists before and after pinning.
- Hero keeps View and one rounded plus action; info action is removed.
- View and plus actions are both exactly 44 logical pixels high.
- Plus social-sheet behavior remains unchanged.
- Do not modify unrelated iOS changes or commit.

---

### Task 1: Overlap Category Rail And Simplify Hero Action

**Files:**
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `lib/src/features/home/widgets/home_cinematic_hero.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: current hero height, `_CategoryTabs`, existing scroll notifications, `HomeCinematicHero.onQuickAdd`.
- Produces: `_HeroCategoryOverlap`, `_PinnedCategoryBar`, scroll-driven `_categoryPinned`, and single `home-hero-add` action.

- [ ] **Step 1: Add failing overlap/action tests**

```dart
final hero = find.byKey(const ValueKey('home-cinematic-hero'));
final categories = find.byKey(const ValueKey('home-category-tabs'));
expect(tester.getTopLeft(categories).dy, closeTo(tester.getBottomLeft(hero).dy - 32, .01));
expect(categories, findsOneWidget);
expect(find.byKey(const ValueKey('home-hero-info')), findsNothing);
expect(find.byKey(const ValueKey('home-hero-add')), findsOneWidget);
expect(tester.getSize(find.byKey(const ValueKey('home-hero-view'))).height, 44);
expect(tester.getSize(find.byKey(const ValueKey('home-hero-add'))).height, 44);
```

Scroll beyond `heroHeight - 32 - topInset`; assert one category rail remains and its top equals status-bar inset. Keep quick-add sheet test.

- [ ] **Step 2: Run focused tests and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Expected: FAIL because current category rail starts after hero and info remains.

- [ ] **Step 3: Build in-flow overlap and pinned overlay**

Add constants `_categoryHeight = 52.0` and `_categoryHeroOverlap = 32.0`. Replace hero sliver plus `SliverPersistentHeader` with:

```dart
SliverToBoxAdapter(
  child: SizedBox(
    height: heroHeight + _categoryHeight - _categoryHeroOverlap,
    child: Stack(
      children: [
        hero,
        Positioned(
          top: heroHeight - _categoryHeroOverlap,
          left: 0,
          right: 0,
          height: _categoryHeight,
          child: pinned ? const SizedBox.shrink() : categoryTabs,
        ),
      ],
    ),
  ),
)
```

Wrap scroll view in `Stack`; when pinned, render `_PinnedCategoryBar` with height `topInset + _categoryHeight`, top padding `topInset`, graphite background, and bottom border. Remove `_CategoryHeaderDelegate`.

Update `_handleScrollNotification` before pagination guards:

```dart
final shouldPin = notification.metrics.pixels >=
    VeilLayout.homeHeroHeight(context) -
        _categoryHeroOverlap -
        MediaQuery.paddingOf(context).top;
if (shouldPin != _categoryPinned) {
  setState(() => _categoryPinned = shouldPin);
}
```

- [ ] **Step 4: Replace secondary capsule with equal-height compact actions**

Remove `onInfo` from `HomeCinematicHero`, frame, and Home call site. Constrain View to 44 pixels high with compact horizontal padding. Replace `_HeroSecondaryActions` with one 44x44 circular graphite `IconButton` retaining `home-hero-add`, `Add to Veil`, and `onQuickAdd`. Assert both keyed actions report equal 44-pixel heights.

- [ ] **Step 5: Format and verify complete behavior**

Run: `dart format lib/src/features/home/view/home_view.dart lib/src/features/home/widgets/home_cinematic_hero.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Run: `flutter test test/widget_test.dart --plain-name "pinned home genres"`

Run: `flutter test test/widget_test.dart`

Run: `flutter analyze`

Run: `git diff --check`

Expected: focused and full widget tests pass, analyzer has no issues, diff check clean.
