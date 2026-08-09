# Provider Pagination And Home Hero Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add infinite provider pagination and sticky media tabs, remove provider attribution, and replace Home's greeting/card hero with the approved full-bleed cinematic hero and social quick-add action.

**Architecture:** A generated Riverpod notifier family owns paged provider state by provider ID and media type while `ProviderView` renders that state as one sliver scroll surface. A focused `HomeCinematicHero` widget owns rotation and presentation; `HomeView` supplies routes and existing social-sheet callbacks.

**Tech Stack:** Flutter, Dart 3.11, Riverpod codegen, Freezed `Status`, typed go_router, flutter_test.

## Global Constraints

- Infinite provider loads start near grid bottom and preserve existing items on page failure.
- Provider page has no app-bar title and no streaming/TMDB attribution footer.
- Movies/TV Series tabs remain pinned while provider content scrolls.
- Hero primary action copy is exactly `View`, never `Play`.
- Hero keeps Search/Alerts controls and unread badge.
- Hero plus action opens existing Veil social action sheet; it never launches playback.
- Home category rail remains immediately after hero.
- Do not change playback, provider region, API contracts, bottom navigation, or category ordering.
- Do not modify unrelated `ios/Runner.xcodeproj/project.pbxproj`.
- Do not commit.

---

### Task 1: Paged Provider Catalog State

**Files:**
- Modify: `lib/src/features/catalog/view_model/provider_catalog_providers.dart`
- Regenerate: `lib/src/features/catalog/view_model/provider_catalog_providers.g.dart`
- Test: `test/watch_provider_repository_test.dart`

**Interfaces:**
- Consumes: `TmdbRepository.discoverByProvider({required int providerId, required String mediaType, int page = 1})`.
- Produces: `ProviderCatalogState`, `providerCatalogProvider(int providerId, String mediaType)`, `ProviderCatalog.loadInitial()`, `loadMore()`, `retryLoadMore()`.

- [ ] **Step 1: Add failing notifier tests**

Cover page-1 success, page-2 append/dedupe, empty-page completion, preserved items after load-more error, explicit retry, and separate movie/TV state. Override `tmdbRepositoryProvider` with a fake that records `(providerId, mediaType, page)` requests.

```dart
final container = ProviderContainer(
  overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
);
addTearDown(container.dispose);

final provider = providerCatalogProvider(8, 'movie');
container.listen(provider, (_, __) {}, fireImmediately: true);
await container.read(provider.notifier).loadInitial();
await container.read(provider.notifier).loadMore();

expect(container.read(provider).items.map((item) => item.id), [
  'movie-1',
  'movie-2',
  'movie-3',
]);
expect(repository.requests, [(8, 'movie', 1), (8, 'movie', 2)]);
```

- [ ] **Step 2: Run provider tests and confirm failure**

Run: `flutter test test/watch_provider_repository_test.dart`

Expected: FAIL because `providerCatalogProvider` and paged state do not exist.

- [ ] **Step 3: Implement paged notifier state**

Replace one-page movie/TV providers with one family notifier. Keep watch-provider list provider unchanged.

```dart
class ProviderCatalogState {
  const ProviderCatalogState({
    this.items = const [],
    this.page = 0,
    this.canLoadMore = true,
    this.isLoadingMore = false,
    this.loadStatus = const Status.initial(),
    this.loadMoreError = '',
  });

  final List<ContentItem> items;
  final int page;
  final bool canLoadMore;
  final bool isLoadingMore;
  final Status loadStatus;
  final String loadMoreError;

  ProviderCatalogState copyWith({
    List<ContentItem>? items,
    int? page,
    bool? canLoadMore,
    bool? isLoadingMore,
    Status? loadStatus,
    String? loadMoreError,
  }) => ProviderCatalogState(
    items: items ?? this.items,
    page: page ?? this.page,
    canLoadMore: canLoadMore ?? this.canLoadMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadStatus: loadStatus ?? this.loadStatus,
    loadMoreError: loadMoreError ?? this.loadMoreError,
  );
}

@riverpod
class ProviderCatalog extends _$ProviderCatalog {
  late int _providerId;
  late String _mediaType;

  @override
  ProviderCatalogState build(int providerId, String mediaType) {
    ref.keepAlive();
    _providerId = providerId;
    _mediaType = mediaType;
    Future.microtask(loadInitial);
    return const ProviderCatalogState();
  }
}
```

`loadInitial` requests page 1, dedupes by `item.id`, and writes success/failure `Status`. `loadMore` guards concurrent calls, completed catalogs, and unresolved page errors; requests `state.page + 1`; appends unique IDs; and keeps existing items on failure. `retryLoadMore` clears `loadMoreError` before retrying.

- [ ] **Step 4: Regenerate and verify state tests**

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `dart format lib/src/features/catalog/view_model/provider_catalog_providers.dart test/watch_provider_repository_test.dart`

Run: `flutter test test/watch_provider_repository_test.dart`

Expected: all provider repository/notifier tests pass.

---

### Task 2: Sticky Paginated Provider Screen

**Files:**
- Modify: `lib/src/features/catalog/view/provider_view.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `providerCatalogProvider(provider.id, 'movie'|'tv')` from Task 1.
- Produces: pinned `provider-media-tabs`, responsive catalog grid, `provider-load-more-progress`, `provider-load-more-retry`.

- [ ] **Step 1: Update provider widget tests to fail**

Replace overrides of `providerMoviesProvider`/`providerTvProvider` with paged notifier state overrides or repository fakes. Add assertions:

```dart
expect(find.byKey(const ValueKey('provider-media-tabs')), findsOneWidget);
expect(
  tester.widget<SliverPersistentHeader>(
    find.byKey(const ValueKey('provider-media-tabs-header')),
  ).pinned,
  isTrue,
);
expect(find.textContaining('Streaming availability'), findsNothing);
expect(find.textContaining('Catalog data by TMDB'), findsNothing);
```

Scroll within 500 pixels of end and verify page 2 request occurs once; expose load-more failure, tap keyed Retry, and verify next request.

- [ ] **Step 2: Run focused tests and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: FAIL because current page uses one-page `AsyncValue`, `ListView`, non-pinned tabs, and attribution.

- [ ] **Step 3: Convert page to one sliver scroll surface**

Use a `NotificationListener<ScrollNotification>` around `CustomScrollView`. For selected tab only:

```dart
final mediaType = _selectedTab == 0 ? 'movie' : 'tv';
final catalog = ref.watch(
  providerCatalogProvider(widget.provider.id, mediaType),
);

bool onScroll(ScrollNotification notification) {
  if (notification.metrics.extentAfter < 500 &&
      catalog.loadMoreError.isEmpty) {
    ref
        .read(providerCatalogProvider(widget.provider.id, mediaType).notifier)
        .loadMore();
  }
  return false;
}
```

Render provider identity as normal sliver, tabs as `SliverPersistentHeader(pinned: true)`, initial skeleton/error/empty as slivers, successful items as `SliverGrid`, and progress/retry as footer sliver. Delete `_CatalogAttribution` and its call site.

- [ ] **Step 4: Verify sticky/pagination widget behavior**

Run: `dart format lib/src/features/catalog/view/provider_view.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: provider tests pass with one page-2 request, pinned tabs, preserved page error items, successful retry, and absent attribution.

---

### Task 3: Full-Bleed Cinematic Home Hero

**Files:**
- Create: `lib/src/features/home/widgets/home_cinematic_hero.dart`
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `lib/src/shared/layout/veil_breakpoints.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: trending `List<ContentItem>`, alert unread count, route callbacks.
- Produces: `HomeCinematicHero(items, height, unreadAlerts, onSearch, onAlerts, onView, onInfo, onQuickAdd)`.

- [ ] **Step 1: Add failing hero presentation tests**

Assert greeting removal, full-bleed geometry, hidden dots, labels, and callbacks:

```dart
expect(find.text('Tonight on Veil'), findsNothing);
expect(find.textContaining('Hello,'), findsNothing);
expect(find.byKey(const ValueKey('home-cinematic-hero')), findsOneWidget);
expect(find.byKey(const ValueKey('home-hero-view')), findsOneWidget);
expect(find.byKey(const ValueKey('home-hero-add')), findsOneWidget);
expect(find.byKey(const ValueKey('home-hero-info')), findsOneWidget);
expect(find.text('View'), findsOneWidget);
expect(find.text('Play'), findsNothing);
expect(find.byKey(const ValueKey('home-hero-dots')), findsNothing);
expect(tester.getTopLeft(find.byKey(const ValueKey('home-cinematic-hero'))).dx, 0);
```

Pump at 390px and 1200px widths; assert no overflow and category header follows hero.

- [ ] **Step 2: Run focused Home tests and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Expected: FAIL because current greeting and rounded hero card remain.

- [ ] **Step 3: Create focused rotating hero widget**

Move rotation, timer, item reconciliation, and backdrop precaching from private Home classes into `HomeCinematicHero`. Preserve seven-second timer and 500ms fade, but remove indicators and direct whole-card tap.

Build the selected item with:

- `BackdropArt(radius: 0, width: double.infinity)`
- horizontal black/transparent/black vignette
- strong transparent-to-`VeilColors.bg0` bottom gradient
- top contrast gradient
- safe-area top row containing Veil movie mark and Search/Alerts glass controls
- centered title, year/genre icon metadata, overview, and action row
- white `View` pill with visibility icon
- graphite plus/divider/info capsule

Keys: `home-cinematic-hero`, `home-hero-logo`, `home-hero-search`, `home-hero-alerts`, `home-hero-view`, `home-hero-add`, `home-hero-info`.

- [ ] **Step 4: Integrate full-bleed hero into Home slivers**

Delete the greeting/header sliver and private `_RotatingHomeHero`, `_HomeHero`, `_HeroBadge`, and `_HeroDots`. Remove horizontal hero padding so the hero spans viewport width. Keep category persistent header directly after hero.

Update `VeilLayout.homeHeroHeight` to use viewport-aware bounded sizing:

```dart
static double homeHeroHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (isDesktop(context)) return 620;
  if (isTablet(context)) return 600;
  return (size.height * .68).clamp(560.0, 680.0);
}
```

Make `_HeroSkeleton` radius zero and use the same height/full width.

- [ ] **Step 5: Verify hero presentation and routing**

Run: `dart format lib/src/features/home/widgets/home_cinematic_hero.dart lib/src/features/home/view/home_view.dart lib/src/shared/layout/veil_breakpoints.dart test/widget_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Expected: hero tests pass at phone and desktop sizes; View/info route to Detail; Search/Alerts still route correctly; no greeting or dots.

---

### Task 4: Hero Quick-Add Social Flow And Full Verification

**Files:**
- Modify: `lib/src/features/home/view/home_view.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `DetailSocialActionSheet`, `DetailReviewSheet`, current `socialLibraryViewModelProvider` state.
- Produces: Home hero plus action with existing watched/favorite/watchlist/rating/review behavior.

- [ ] **Step 1: Add failing quick-add tests**

Tap `home-hero-add`; assert `detail-social-action-panel`, Watched, Favorite, Watchlist, Rate, and Review appear. Seed social state and assert selected values. Tap Review and assert existing `DetailReviewSheet` opens for featured item. Verify plus does not call playback launcher or navigate away.

- [ ] **Step 2: Run quick-add test and confirm failure**

Run: `flutter test test/widget_test.dart --plain-name "hero quick add"`

Expected: FAIL because hero plus callback is not connected.

- [ ] **Step 3: Wire existing social sheet from Home**

Add a private `_openHeroSocialActions(ContentItem item)` method to `_HomeViewState`. Read current item state from `socialLibraryViewModelProvider`, then call `showVeilBottomSheet` with `DetailSocialActionSheet`. Connect:

```dart
onSetWatched: ({required watched, required rating}) => social.setWatched(
  item,
  watched: watched,
  rating: rating,
),
onToggleFavorite: () => social.toggleFavorite(item),
onSetWatchlist: ({required inWatchlist}) => social.setWatchlist(
  item,
  inWatchlist: inWatchlist,
),
onRate: ({required rating}) => social.rate(item, rating: rating),
```

Close social sheet before opening `DetailReviewSheet`; save review through existing social view-model API using the same tags and watched semantics as Detail. Keep Suggest behavior routed through existing Detail flow or suggestion sheet without changing its contract.

- [ ] **Step 4: Run focused and complete verification**

Run: `dart format lib test`

Run: `flutter test test/widget_test.dart --plain-name "hero quick add"`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Run: `flutter test test/widget_test.dart --plain-name "home hero"`

Run: `flutter test test/widget_test.dart`

Run: `flutter test`

Run: `flutter analyze`

Run: `git diff --check`

Expected: all tests pass, analyzer reports no issues, and diff check is clean.
