# Provider Catalog And Grid Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shrink and restyle provider cards, hide their Home rail for tester account, and convert provider catalogs plus Home genres to Veil-themed responsive poster grids.

**Architecture:** Keep existing repositories/routes and change presentation only. Use `VeilLayout.posterGridColumns` and `PosterCard` as shared grid language; conditionally watch only selected provider catalog data.

**Tech Stack:** Flutter, Dart 3.11, Riverpod, GoRouter, cached_network_image, existing Veil theme/layout components.

## Global Constraints

- Provider images are 58x58, edge-to-edge, cover fit, radius 12, no white background/padding.
- Provider cells are 64 pixels wide; skeletons match 58x58.
- Hide Home provider rail for normalized `tester@vexellab.com` before watching provider data.
- Provider app bar has no title and uses Veil glass back treatment.
- Provider catalog tabs are Movies and TV Series; only selected async provider is watched.
- Poster grids use 3 phone columns and existing responsive 5/6/7 wider counts.
- Keep provider route, API, US region, retries, empty states, attribution, and Detail navigation.
- Keep Home selected-genre See all, pagination, errors, and loading footer.
- Preserve unrelated worktree changes, including iOS project file.
- Do not commit unless explicitly requested.

---

### Task 1: Compact Tester-Aware Provider Rail

**Files:**
- Modify: `lib/src/features/home/widgets/watch_provider_section.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `authViewModelProvider`, `watchProvidersProvider`, `TmdbWatchProvider.logoUrl`.
- Produces: compact provider rail hidden for tester account.

- [ ] **Step 1: Write failing tester and visual tests**

Add a provider override that increments when watched. Pump tester auth and assert:

```dart
expect(providerBuilds, 0);
expect(find.byKey(const ValueKey('watch-provider-list')), findsNothing);
```

Pump normal auth with provider data and inspect image container keyed `watch-provider-image-1`:

```dart
final box = tester.widget<Container>(
  find.byKey(const ValueKey('watch-provider-image-1')),
);
expect(box.constraints?.maxWidth, 58);
expect(box.constraints?.maxHeight, 58);
expect(box.padding, isNull);
final decoration = box.decoration! as BoxDecoration;
expect(decoration.color, isNull);
expect(decoration.borderRadius, BorderRadius.circular(12));
final image = tester.widget<CachedNetworkImage>(
  find.descendant(
    of: find.byKey(const ValueKey('watch-provider-image-1')),
    matching: find.byType(CachedNetworkImage),
  ),
);
expect(image.fit, BoxFit.cover);
```

Verify loading skeleton key `watch-provider-loading-0` has width/height 58.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "home provider"`

Expected: tester still watches provider and current image is 76x76 with white background/padding/contain fit.

- [ ] **Step 3: Implement early tester return and compact cards**

Before `ref.watch(watchProvidersProvider)`:

```dart
final email = ref.watch(authViewModelProvider).user?.email?.trim().toLowerCase();
if (email == 'tester@vexellab.com') return const SizedBox.shrink();
```

Set card width 64, image container 58x58, radius 12, no padding or background color, clip anti-alias, hairline border, and `CachedNetworkImage(fit: BoxFit.cover)`. Use a graphite fallback with white initial. Set loaded rail height near 90 and skeletons 58x58 with matching keys.

- [ ] **Step 4: Format and run provider tests**

Run: `dart format lib/src/features/home/widgets/watch_provider_section.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "home provider"`

Expected: PASS.

### Task 2: Veil-Themed Tabbed Provider Catalog

**Files:**
- Modify: `lib/src/features/catalog/view/provider_view.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `providerMoviesProvider(int)`, `providerTvProvider(int)`, `PosterCard`, `VeilLayout.posterGridColumns`.
- Produces: stateful Movies/TV Series tab screen with one selected responsive grid.

- [ ] **Step 1: Write failing app bar/tab/provider-watch tests**

Pump ProviderView with provider overrides that count builds. Initially assert Movies builds once, TV builds zero, no Streaming catalog title, and back icon exists. Tap key `provider-tab-tv` and assert TV builds once plus TV fixture visible. Tap `provider-tab-movies` and assert movie fixture returns.

Inspect `provider-catalog-grid` at 390 logical pixels:

```dart
final grid = tester.widget<GridView>(
  find.byKey(const ValueKey('provider-catalog-grid')),
);
final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
expect(delegate.crossAxisCount, 3);
```

At 1200 pixels expect six columns from existing layout rules.

- [ ] **Step 2: Run provider screen tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "provider screen"`

Expected: current screen watches both providers, shows Streaming catalog, and uses horizontal rails.

- [ ] **Step 3: Convert ProviderView to selected-tab state**

Use:

```dart
enum _ProviderCatalogTab { movies, tvSeries }

class ProviderView extends ConsumerStatefulWidget {
  const ProviderView({
    super.key,
    required this.providerId,
    this.providerName,
    this.logoPath,
  });

  final int providerId;
  final String? providerName;
  final String? logoPath;

  @override
  ConsumerState<ProviderView> createState() => _ProviderViewState();
}

class _ProviderViewState extends ConsumerState<ProviderView> {
  var _tab = _ProviderCatalogTab.movies;

  AsyncValue<List<ContentItem>> _selectedValue() {
    return switch (_tab) {
      _ProviderCatalogTab.movies =>
        ref.watch(providerMoviesProvider(widget.providerId)),
      _ProviderCatalogTab.tvSeries =>
        ref.watch(providerTvProvider(widget.providerId)),
    };
  }
}
```

AppBar uses transparent background, no title, and padded circular `IconButton` with panel background, white border, and back arrow.

- [ ] **Step 4: Build themed header, tabs, and grid states**

Wrap body in Veil graphite vertical gradient. Keep filled rounded provider logo/name header without white background. Add pill tabs keyed `provider-tab-movies` and `provider-tab-tv`.

Use one parent `ListView` for header, tabs, selected state, and attribution. Selected data renders a shrink-wrapped, non-scrollable `GridView.builder` keyed `provider-catalog-grid` with:

```dart
SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: VeilLayout.posterGridColumns(context),
  mainAxisSpacing: 20,
  crossAxisSpacing: 12,
  childAspectRatio: .49,
)
```

Use `PosterCard(width: double.infinity, height: 160)`. Loading uses matching grid skeletons; empty/error states remain, with retry invalidating only selected family. Attribution remains at grid footer.

- [ ] **Step 5: Run provider tests**

Run: `dart format lib/src/features/catalog/view/provider_view.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "provider screen"`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: PASS.

### Task 3: Responsive Home Genre Poster Grid And Full Verification

**Files:**
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `VeilLayout.posterGridColumns`, `PosterCard`, existing genre state/pagination.
- Produces: selected-genre responsive poster grid and matching loading skeleton.

- [ ] **Step 1: Replace vertical-row expectations with failing grid tests**

Pump selected Action genre at 390 pixels and inspect `home-genre-grid` delegate for three columns. Assert each fixture key `genre-result-{id}` exists and opens Detail. At 1200 pixels expect six columns. Keep pagination test proving appended results remain visible.

- [ ] **Step 2: Run focused genre tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "selected home genre"`

Expected: current phone layout uses SliverList and desktop uses two wide-row columns.

- [ ] **Step 3: Replace genre rows and skeleton with poster grids**

Implement `_GenreResultList` as `SliverPadding` plus:

```dart
SliverGrid.builder(
  key: const ValueKey('home-genre-grid'),
  itemCount: items.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: VeilLayout.posterGridColumns(context),
    mainAxisSpacing: 20,
    crossAxisSpacing: 12,
    childAspectRatio: .49,
  ),
  itemBuilder: (context, index) {
    final item = items[index];
    return PosterCard(
      key: ValueKey('genre-result-${item.id}'),
      item: item,
      width: double.infinity,
      height: 160,
      onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
    );
  },
)
```

Delete `_GenreResultTile`. Convert `_GenreListSkeleton` to same responsive `SliverGrid` with poster-shaped skeletons. Preserve See all and pagination widgets unchanged.

- [ ] **Step 4: Run focused and full verification**

Run: `dart format lib test`

Run: `flutter test test/widget_test.dart --plain-name "selected home genre"`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart`

Run: `flutter test`

Run: `flutter analyze`

Run: `git diff --check`

Expected: all pass with no overflow or analyzer diagnostics.
