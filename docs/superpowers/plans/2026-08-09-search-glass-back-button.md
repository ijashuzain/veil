# Search Glass Back Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Match Search leading back button to Veil provider-page glass navigation style.

**Architecture:** Style existing conditional Search `IconButton` in place. Keep route behavior, Cancel action, and header geometry unchanged.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Button is 38x38 circular glass control with panel `.72` fill and white `.20` border.
- Arrow is white, rounded, and 20px.
- Search Cancel, title, and `showBack: false` behavior remain unchanged.
- Do not modify unrelated provider/Home/backend/iOS/generated changes or commit.

---

### Task 1: Theme Search Back Button

**Files:**
- Modify: `lib/src/features/search/view/search_view.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `SearchView.showBack` and `Navigator.maybePop()`.
- Produces: keyed `search-back-button` with provider-matching `ButtonStyle`.

- [ ] **Step 1: Add failing Search button test**

```dart
final button = tester.widget<IconButton>(
  find.byKey(const ValueKey('search-back-button')),
);
expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
expect(
  button.style?.backgroundColor?.resolve({}),
  VeilColors.panel.withValues(alpha: .72),
);
expect(button.style?.minimumSize?.resolve({}), const Size.square(38));
```

Retain route-pop and `showBack: false` assertions.

- [ ] **Step 2: Run focused Search tests and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "search"`

Expected: FAIL because `search-back-button` and glass style do not exist.

- [ ] **Step 3: Apply provider-matching button style**

Add key and use `IconButton.styleFrom` with panel `.72` background, white `.20` border, 38 minimum/maximum size, zero padding, shrink-wrapped tap target, and `CircleBorder`. Set icon size 20 and white color.

- [ ] **Step 4: Format and verify**

Run: `dart format lib/src/features/search/view/search_view.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "search"`

Run: `flutter analyze`

Run: `git diff --check`

Expected: focused tests pass, analyzer has no issues, diff check clean.
