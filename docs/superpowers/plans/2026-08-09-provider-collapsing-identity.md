# Provider Collapsing Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reveal compact provider logo/name in catalog app bar as large provider header scrolls away.

**Architecture:** Drive app-bar identity opacity, translation, and scale directly from existing catalog scroll position through `ScrollController` and `AnimatedBuilder`. Keep fixed Scaffold app bar so pinned tabs continue stacking below it without scroll-layout changes.

**Tech Stack:** Flutter, Dart, flutter_test.

## Global Constraints

- Compact identity uses 38x38 rounded logo and one-line ellipsized name.
- Identity is invisible at offset zero and fully visible at offset 88 or greater.
- Large provider identity remains in scroll content.
- Sticky tabs, pagination, selected-only provider state, and poster navigation remain unchanged.
- Do not modify unrelated Home/backend/iOS/generated changes or commit.

---

### Task 1: Animate Provider Identity Into App Bar

**Files:**
- Modify: `lib/src/features/catalog/view/provider_view.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: resolved provider name/logo URL and provider catalog `CustomScrollView`.
- Produces: `provider-collapsed-identity`, `provider-collapsed-logo`, and scroll-driven compact app-bar title.

- [ ] **Step 1: Add failing transition tests**

At initial offset assert compact identity opacity zero. Scroll provider list beyond 88 pixels and assert opacity one, 38x38 logo, one-line ellipsized name, and moved large header. Keep pinned-header assertion.

```dart
Opacity collapsedOpacity() => tester.widget<Opacity>(
  find.byKey(const ValueKey('provider-collapsed-identity')),
);

expect(collapsedOpacity().opacity, 0);
await tester.drag(
  find.byKey(const ValueKey('provider-catalog-list')),
  const Offset(0, -120),
);
await tester.pump();
expect(collapsedOpacity().opacity, 1);
expect(
  tester.getSize(find.byKey(const ValueKey('provider-collapsed-logo'))),
  const Size.square(38),
);
```

- [ ] **Step 2: Run focused provider test and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: FAIL because compact identity keys do not exist.

- [ ] **Step 3: Add scroll-driven app-bar identity**

Create and dispose a `ScrollController` in `_ProviderViewState`; attach it to `CustomScrollView`. Add app-bar title using `AnimatedBuilder(animation: _scrollController, ...)`.

```dart
final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
final progress = (offset / 88).clamp(0.0, 1.0);

return Opacity(
  key: const ValueKey('provider-collapsed-identity'),
  opacity: progress,
  child: Transform.translate(
    offset: Offset(0, 8 * (1 - progress)),
    child: Transform.scale(
      alignment: Alignment.centerLeft,
      scale: .94 + (.06 * progress),
      child: _CollapsedProviderIdentity(name: resolvedName, logoUrl: logoUrl),
    ),
  ),
);
```

Set `AppBar.titleSpacing` to zero. `_CollapsedProviderIdentity` uses existing logo fallback semantics, 38x38 logo, 10px gap, and one-line 16px bold name with `TextOverflow.ellipsis`. Wrap hidden state in semantics exclusion.

- [ ] **Step 4: Format and verify**

Run: `dart format lib/src/features/catalog/view/provider_view.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart`

Run: `flutter analyze`

Run: `git diff --check`

Expected: provider and full widget tests pass, analyzer has no issues, diff check clean.
