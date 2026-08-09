# Home Discovery Rail Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore provider and curated image loading, simplify Home discovery rails, reposition curated content, and restore the generic Server 2 label.

**Architecture:** Fix rejected requests at existing Supabase proxy allowlists rather than bypassing Veil infrastructure. Keep data providers and navigation unchanged; reduce only Home presentation chrome and feed ordering.

**Tech Stack:** Flutter, Dart 3.11, Riverpod, Supabase Edge Functions, Deno TypeScript, Supabase CLI.

## Global Constraints

- Add only `watch` to TMDB root routes and `w200` to TMDB image sizes.
- Keep existing method, host, JWT, and traversal restrictions.
- Provider loaded/loading states are rail-only; provider errors render nothing.
- Curated loaded state contains tabs and posters without section or repeated collection headings.
- Keep curated prior-content transition and retry behavior.
- Place curated section after New this week and before Popular movies.
- Server button text is exactly `Server 2`; Cinejoy behavior remains unchanged.
- Preserve existing unrelated worktree changes, including `ios/Runner.xcodeproj/project.pbxproj`.
- Do not commit unless explicitly requested.

---

### Task 1: Supabase Proxy Contracts

**Files:**
- Modify: `supabase/functions/tmdb/index.ts`
- Modify: `supabase/functions/tmdb-image/index.ts`
- Create: `test/supabase_function_contract_test.dart`

**Interfaces:**
- Produces: TMDB proxy accepts `/3/watch/*`.
- Produces: TMDB image proxy accepts `/t/p/w200/*`.
- Preserves: unknown TMDB roots and unsupported image sizes remain rejected.

- [ ] **Step 1: Write failing source-contract tests**

```dart
test('TMDB function allows watch provider routes', () async {
  final source = await File('supabase/functions/tmdb/index.ts').readAsString();
  expect(source, contains("  'watch',"));
  expect(source, contains('return allowedRoutes.has(segments[1]);'));
});

test('TMDB image function allows w200 and keeps size allowlist', () async {
  final source = await File(
    'supabase/functions/tmdb-image/index.ts',
  ).readAsString();
  expect(source, contains("  'w200',"));
  expect(source, contains('if (!allowedSizes.has(segments[2])) return false;'));
  expect(source, contains("segment !== '..'"));
});
```

- [ ] **Step 2: Run test and verify failure**

Run: `flutter test test/supabase_function_contract_test.dart`

Expected: two failures because `watch` and `w200` are absent.

- [ ] **Step 3: Add minimal allowlist entries**

```typescript
const allowedRoutes = new Set([
  'configuration',
  'discover',
  'find',
  'genre',
  'movie',
  'search',
  'trending',
  'tv',
  'watch',
]);
```

```typescript
const allowedSizes = new Set([
  'original',
  'w92',
  'w154',
  'w185',
  'w200',
  'w342',
  'w500',
  'w780',
  'w1280',
]);
```

- [ ] **Step 4: Run contract tests**

Run: `flutter test test/supabase_function_contract_test.dart`

Expected: PASS.

### Task 2: Rail-Only Home Presentation

**Files:**
- Modify: `lib/src/features/home/widgets/watch_provider_section.dart`
- Modify: `lib/src/features/home/widgets/curated_collection_section.dart`
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `lib/src/features/detail/widgets/detail_playback_server_sheet.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: existing `watchProvidersProvider`, `curatedCollectionsProvider`, and item family.
- Produces: rail-only provider and curated UI with requested Home order.

- [ ] **Step 1: Write failing compact provider tests**

For provider data, loading, and error states assert:

```dart
expect(find.text('Watch by provider'), findsNothing);
expect(find.byKey(const ValueKey('watch-provider-retry')), findsNothing);
```

Loaded state must still find `watch-provider-list` and provider cards. Loading state must find provider skeletons. Error state must find neither provider list nor skeleton.

- [ ] **Step 2: Write failing compact curated/order tests**

With loaded metadata/items assert collection tabs and poster cards remain, then:

```dart
expect(find.text('Curated collections'), findsNothing);
expect(
  find.byKey(
    const ValueKey(
      'curated-collection-heading-psychological-thrillers',
    ),
  ),
  findsNothing,
);
expect(find.text('Slow-burn thrillers.'), findsNothing);
```

In Home, compare vertical centers after scrolling enough to build sections:

```dart
expect(newThisWeekY, lessThan(curatedTabsY));
expect(curatedTabsY, lessThan(popularMoviesY));
```

Server sheet assertion becomes `expect(find.text('Server 2'), findsOneWidget)` and `find.textContaining('Cinejoy')` finds nothing inside the sheet.

- [ ] **Step 3: Run focused widget tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart --plain-name "curated"`

Run: `flutter test test/widget_test.dart --plain-name "detail server four appears in playback server sheet"`

Expected: failures against current headings, retry row, ordering, and Server 2 label.

- [ ] **Step 4: Simplify provider widget**

Return `_ProviderRail` directly for loaded data, `_ProviderRailLoading` while loading, and `const SizedBox.shrink()` for errors. Remove `_ProviderRailError`. Remove heading padding/text from loaded and loading widgets; preserve horizontal gutter, card keys, navigation, and bottom spacing.

- [ ] **Step 5: Simplify curated widget**

Remove `Curated collections` heading from content/loading UI. Remove selected collection heading/description block. Keep choice chips, progress indicator, retained poster rail, compact errors, empty state, and retry behavior. The visible display record needs only item data after heading removal; retaining collection identity is optional if still used for transition safety.

- [ ] **Step 6: Reorder Home and rename Server 2**

Move `CuratedCollectionSection` from before Global trending to immediately after New this week and its spacing. Keep Provider rail before Global trending. Change button title to:

```dart
title: 'Server 2',
```

- [ ] **Step 7: Format and run focused tests**

Run: `dart format lib test`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart --plain-name "curated"`

Run: `flutter test test/widget_test.dart --plain-name "server"`

Expected: PASS.

### Task 3: Full Verification And Deployment

**Files:**
- No source changes unless a Task 1 or Task 2 regression is found.

**Interfaces:**
- Consumes: tested local proxy and UI changes.
- Produces: deployed Edge Functions and verified live contracts.

- [ ] **Step 1: Run focused and full verification**

Run: `flutter test test/supabase_function_contract_test.dart test/watch_provider_repository_test.dart test/curated_collection_repository_test.dart`

Run: `flutter test test/widget_test.dart`

Run: `flutter test`

Run: `flutter analyze`

Run: `git diff --check`

Expected: all commands exit 0.

- [ ] **Step 2: Confirm CLI authentication and function config**

Run: `supabase --version`

Run: `supabase functions list --project-ref verlsbmdqggejpfmvzue`

Confirm `supabase/config.toml` keeps `verify_jwt = false` for `tmdb` and `tmdb-image`.

- [ ] **Step 3: Deploy both functions**

Run: `supabase functions deploy tmdb --project-ref verlsbmdqggejpfmvzue --use-api`

Run: `supabase functions deploy tmdb-image --project-ref verlsbmdqggejpfmvzue --use-api`

Expected: both report successful deployment and retain local `verify_jwt = false` configuration.

- [ ] **Step 4: Verify live provider contracts**

Run:

```bash
curl --silent --show-error --output /tmp/veil-provider-response.json \
  --write-out '%{http_code}' \
  'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb/3/watch/providers/movie?language=en-US&watch_region=US'
```

Expected: HTTP 200, JSON `results` list with provider IDs/names/logos.

Run:

```bash
curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
  'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb/3/unknown'
```

Expected: HTTP 403.

- [ ] **Step 5: Verify live image contracts**

Run:

```bash
curl --silent --show-error --head \
  'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb-image/t/p/w200/uS9m8OBk1A8eM9I042bx8XXpqAq.jpg'
```

Expected: HTTP 200 and image content type.

Run:

```bash
curl --silent --show-error --head \
  'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/tmdb-image/t/p/w123/uS9m8OBk1A8eM9I042bx8XXpqAq.jpg'
```

Expected: HTTP 403.

- [ ] **Step 6: Report deployment and worktree state**

Run: `git status --short`

Report exact local tests, deployment results, live HTTP statuses, and any external-service residual risk. Do not alter unrelated `ios/Runner.xcodeproj/project.pbxproj` changes.
