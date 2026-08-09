# Poster Rating Deduplication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove duplicate rating overlay from shared poster artwork while retaining lower title metadata rating.

**Architecture:** Simplify shared `PosterCard` artwork to render `PosterArt` directly inside existing shadow decoration. Delete private overlay chip; all consumers inherit change automatically.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Remove artwork rating chip from every shared `PosterCard`.
- Keep lower star, numeric rating, and year when `showMeta` is true.
- Keep artwork-only behavior when `showMeta` is false.
- Do not change Detail/review ratings or unrelated Home/provider/iOS/generated changes.
- Do not commit.

---

### Task 1: Remove Shared Poster Artwork Rating

**Files:**
- Modify: `lib/src/shared/components/content_cards.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PosterCard(item, showMeta)`.
- Produces: one rating presentation per metadata-enabled card and no artwork overlay.

- [ ] **Step 1: Add failing shared PosterCard tests**

Pump one metadata-enabled `PosterCard`. Assert one rating text and one star exist overall, and neither appears as a descendant of the card's `PosterArt`/artwork stack. Pump `showMeta: false` and assert rating text/star are absent.

```dart
expect(find.text(_wakanda.rating.toStringAsFixed(1)), findsOneWidget);
expect(find.byIcon(Icons.star_rounded), findsOneWidget);
```

- [ ] **Step 2: Run focused poster test and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "poster card rating"`

Expected: FAIL because two rating texts and stars render.

- [ ] **Step 3: Remove artwork rating overlay**

Replace artwork `Stack` with direct `PosterArt` inside existing `DecoratedBox`. Delete `_PosterRatingChip` class. Keep lower metadata row unchanged.

- [ ] **Step 4: Format and verify**

Run: `dart format lib/src/shared/components/content_cards.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "poster card rating"`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart --plain-name "home"`

Run: `flutter analyze`

Run: `git diff --check`

Expected: focused tests pass, analyzer has no issues, diff check clean.
