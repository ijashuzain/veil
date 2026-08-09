# Provider Transparent Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove separate background treatment from pinned Movies/TV Series tab section.

**Architecture:** Keep existing `SliverPersistentHeader` geometry and pill controls, but make delegate return padding plus child directly. Remove blur, gradient, fill, and divider without changing scrolling or state.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Tab section is fully transparent with no blur, fill, gradient, or divider.
- Selected and unselected pill surfaces remain unchanged.
- Pinned behavior, provider identity transition, pagination, and grid remain unchanged.
- Do not modify unrelated Home/backend/iOS/generated changes or commit.

---

### Task 1: Remove Provider Tab Section Surface

**Files:**
- Modify: `lib/src/features/catalog/view/provider_view.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `_ProviderTabsHeaderDelegate` and existing `provider-media-tabs-header` key.
- Produces: transparent pinned header containing unchanged `_ProviderTabs`.

- [ ] **Step 1: Add failing transparent-header test**

```dart
final header = find.byKey(const ValueKey('provider-media-tabs-header'));
expect(
  find.descendant(of: header, matching: find.byType(BackdropFilter)),
  findsNothing,
);
```

Also retain `SliverPersistentHeader.pinned == true` and selected/unselected pill styling assertions.

- [ ] **Step 2: Run focused provider tests and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: FAIL because current tab header contains `BackdropFilter`.

- [ ] **Step 3: Remove tab section decoration**

In `_ProviderTabsHeaderDelegate.build`, replace `ClipRect`, `BackdropFilter`, gradient `DecoratedBox`, and border with:

```dart
return Padding(
  padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 12),
  child: child,
);
```

Remove unused `dart:ui` import. Keep min/max extent at 64.

- [ ] **Step 4: Format and verify**

Run: `dart format lib/src/features/catalog/view/provider_view.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter analyze`

Run: `git diff --check`

Expected: focused tests pass, analyzer has no issues, diff check clean.
