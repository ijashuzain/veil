# Cinejoy Playback And Home Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Server 2 with TMDB-based Cinejoy playback and add honest local playback history, rotating Home art, provider browsing, curated Shegu collections, Detail recommendations, and screenshot-inspired navigation polish.

**Architecture:** Resolve every server selection into a shared `PlaybackRequest` and `PlaybackTarget`, then use one platform-aware launcher from Detail and Home. Keep playback history local and per user, while loading TMDB providers and Shegu collections through independent Riverpod async lanes so optional failures cannot break existing Home data.

**Tech Stack:** Flutter, Dart 3.11, Riverpod 3 code generation, GoRouter typed routes, Dio, SharedPreferences through `LocalStorage`, existing WebView player, TMDB API v3, and `lists.shegu.st`.

## Global Constraints

- Keep `LocalStorage.init()` before Supabase initialization.
- Keep Server 1, 3, and 4 behavior unchanged except routing their launches through shared request code.
- Cinejoy uses positive TMDB IDs; never copy the TMDB API key from captured Cinejoy traffic.
- Native Cinejoy loads as a top-level WebView page. Flutter web always launches Cinejoy externally because `frame-ancestors 'none'` forbids iframe use.
- Continue Watching stores launch metadata only. Never display fake progress, duration, time-left, or resume-to-second.
- Store history under authenticated user ID and recheck premium entitlement before Home relaunch.
- Provider region is exactly `US` for this pass.
- Show JustWatch attribution on provider results.
- Shegu failures remain optional and isolated from `HomeViewState.loadStatus`.
- Preserve tester-account Disney/Pixar filtering for TMDB provider and Shegu results.
- Keep Home, Diary, Reviews, and Profile destinations.
- Do not hand-edit generated `*.g.dart` or `*.freezed.dart` files.
- Do not commit unless user explicitly requests a commit.

## File Structure

### Playback

- Create `lib/src/shared/models/playback_request.dart`: server enum plus immutable request.
- Create `lib/src/features/embeded_player/utils/playback_target.dart`: pure request-to-URL/player-policy resolution.
- Create `lib/src/features/embeded_player/utils/playback_launcher.dart`: external web versus in-app player navigation.
- Modify `lib/src/features/embeded_player/utils/external_player_launcher_stub.dart`: direct-launch stub API.
- Modify `lib/src/features/embeded_player/utils/external_player_launcher_web.dart`: direct top-level Cinejoy launch without preflight proxies.
- Modify `lib/src/features/detail/utils/playback_entry_url.dart`: add Cinejoy builder and remove PlayIMDb/VSEmbed Server 2 helpers.
- Modify `lib/src/features/detail/view/detail_view.dart`: use shared requests, Cinejoy TV picker, launcher injection, and history recording.
- Modify `lib/src/features/detail/widgets/detail_playback_server_sheet.dart`: identify Server 2 as Cinejoy.
- Modify `lib/src/features/embeded_player/view/player_mobile.dart`: permit same-host Cinejoy `/watch/` top-level paths.

### Playback History And Home

- Create `lib/src/features/playback_history/models/playback_history_entry.dart`: manual JSON snapshot and `PlaybackRequest` conversion.
- Create `lib/src/features/playback_history/repository/playback_history_repository.dart`: per-user load/record/remove/clear.
- Create `lib/src/features/playback_history/view_model/playback_history_view_model.dart`: auth-aware Riverpod notifier.
- Create `lib/src/features/home/widgets/continue_watching_section.dart`: honest history cards and edit/remove mode.
- Modify `lib/src/features/home/view/home_view.dart`: rotating hero, history section, relaunch, provider and curated section placement.
- Modify `lib/src/shared/components/content_cards.dart`: remove fake hardcoded progress metadata from reusable continue card or replace its usage with history card.

### Providers

- Create `lib/src/features/catalog/models/tmdb_watch_provider.dart`: provider identity, logo, and priority.
- Create `lib/src/features/catalog/view_model/provider_catalog_providers.dart`: provider list plus movie/TV async families.
- Create `lib/src/features/catalog/view/provider_view.dart`: provider header, independent Movies/TV sections, attribution.
- Create `lib/src/features/home/widgets/watch_provider_section.dart`: Home provider logo rail.
- Modify `lib/src/features/catalog/repository/tmdb_repository.dart`: provider list merge and provider discover methods.
- Modify `lib/src/core/constants/endpoints.dart`: provider list endpoints.
- Modify `lib/src/core/router/route_paths.dart`: `/provider/:id`.
- Modify `lib/src/core/router/app_router.dart`: typed provider route.

### Curated Collections And Polish

- Create `lib/src/features/catalog/models/curated_collection.dart`: collection metadata.
- Create `lib/src/features/catalog/repository/curated_collection_repository.dart`: defensive Shegu parsing and filtering.
- Create `lib/src/features/catalog/view_model/curated_collection_providers.dart`: metadata and selected-item async providers.
- Create `lib/src/features/home/widgets/curated_collection_section.dart`: collection selector and one poster rail.
- Create `lib/src/features/detail/widgets/detail_recommendation_rails.dart`: recommendations and deduplicated similar titles.
- Modify `lib/src/features/detail/view/detail_view.dart`: render recommendation rails.
- Modify `lib/src/features/shell/view/veil_shell_view.dart`: neutral glass active treatment.

---

### Task 1: Playback Requests And Cinejoy Targets

**Files:**
- Create: `lib/src/shared/models/playback_request.dart`
- Create: `lib/src/features/embeded_player/utils/playback_target.dart`
- Modify: `lib/src/features/detail/utils/playback_entry_url.dart`
- Create: `test/playback_request_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `enum PlaybackServer { one, two, three, four }`
- Produces: `PlaybackRequest({required ContentItem item, required PlaybackServer server, int season = 1, int episode = 1})`
- Produces: `PlaybackTarget? playbackTargetFor(PlaybackRequest request)`
- Produces: `Uri? cinejoyPlaybackUrl({required int? tmdbId, String? contentType, int season = 1, int episode = 1})`

- [ ] **Step 1: Write failing URL and target tests**

Create tests with movie and TV fixtures and exact expected values:

```dart
test('cinejoy uses TMDB movie and episode paths', () {
  expect(
    cinejoyPlaybackUrl(tmdbId: 1284041, contentType: 'Movie').toString(),
    'https://cinejoy.to/watch/movie/1284041',
  );
  expect(
    cinejoyPlaybackUrl(
      tmdbId: 94997,
      contentType: 'TV Show',
      season: 0,
      episode: -2,
    ).toString(),
    'https://cinejoy.to/watch/tv/94997/1/1',
  );
  expect(cinejoyPlaybackUrl(tmdbId: 0, contentType: 'Movie'), isNull);
});

test('server two target is top-level native and external on web', () {
  final target = playbackTargetFor(
    PlaybackRequest(item: movie, server: PlaybackServer.two),
  )!;
  expect(target.url.toString(), 'https://cinejoy.to/watch/movie/1284041');
  expect(target.loadAsPage, isTrue);
  expect(target.externalOnWeb, isTrue);
  expect(target.fallbackUrls, isEmpty);
});
```

Keep target assertions for Servers 1, 3, and 4 matching their current URL, fallback, `forceEmbedded`, and `loadAsPage` behavior.

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test test/playback_request_test.dart`

Expected: compile failure because `PlaybackRequest`, `PlaybackTarget`, and `cinejoyPlaybackUrl` do not exist.

- [ ] **Step 3: Add request and target types**

Implement immutable value types with clamped episode fields:

```dart
enum PlaybackServer { one, two, three, four }

class PlaybackRequest {
  const PlaybackRequest({
    required this.item,
    required this.server,
    this.season = 1,
    this.episode = 1,
  });

  final ContentItem item;
  final PlaybackServer server;
  final int season;
  final int episode;

  int get safeSeason => season < 1 ? 1 : season;
  int get safeEpisode => episode < 1 ? 1 : episode;
}

class PlaybackTarget {
  const PlaybackTarget({
    required this.url,
    this.fallbackUrls = const [],
    this.forceEmbedded = false,
    this.loadAsPage = false,
    this.externalOnWeb = false,
  });

  final Uri url;
  final List<Uri> fallbackUrls;
  final bool forceEmbedded;
  final bool loadAsPage;
  final bool externalOnWeb;
}
```

Use `playbackTargetFor` as the only server switch. Return `null` when required IDs are unavailable.

- [ ] **Step 4: Replace PlayIMDb URL helpers with Cinejoy builder**

Delete `playbackEntryUrl` and `playbackFallbackUrls`. Add:

```dart
Uri? cinejoyPlaybackUrl({
  required int? tmdbId,
  String? contentType,
  int season = 1,
  int episode = 1,
}) {
  if (tmdbId == null || tmdbId <= 0) return null;
  if (isTvPlaybackContent(contentType)) {
    final safeSeason = season < 1 ? 1 : season;
    final safeEpisode = episode < 1 ? 1 : episode;
    return Uri.https(
      'cinejoy.to',
      '/watch/tv/$tmdbId/$safeSeason/$safeEpisode',
    );
  }
  return Uri.https('cinejoy.to', '/watch/movie/$tmdbId');
}
```

Delete obsolete PlayIMDb/VSEmbed URL tests from `test/widget_test.dart`; retain redirect extractor tests only if another production caller still exists.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/playback_request_test.dart`

Expected: PASS for all four target policies and Cinejoy URL shapes.

### Task 2: Shared Launcher And Detail Integration

**Files:**
- Create: `lib/src/features/embeded_player/utils/playback_launcher.dart`
- Modify: `lib/src/features/embeded_player/utils/external_player_launcher_stub.dart`
- Modify: `lib/src/features/embeded_player/utils/external_player_launcher_web.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Modify: `lib/src/features/detail/widgets/detail_playback_server_sheet.dart`
- Modify: `lib/src/features/embeded_player/view/player_mobile.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PlaybackRequest`, `PlaybackTarget`, `playbackTargetFor`
- Produces: `typedef PlaybackRequestLauncher = Future<bool> Function(BuildContext context, PlaybackRequest request)`
- Produces: `Future<bool> launchPlaybackRequest(BuildContext context, PlaybackRequest request)`
- Produces: `Future<bool> openExternalPlayerDirect(Uri url)`

- [ ] **Step 1: Replace old Server 2 widget tests with failing Cinejoy tests**

Inject a launcher into `DetailView`, capture requests, and assert movie behavior:

```dart
PlaybackRequest? launched;
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      detailViewModelProvider(movie).overrideWithValue(
        DetailViewState(detail: ContentDetail.fallback(movie)),
      ),
      currentUserIsPremiumProvider.overrideWith((ref) async => true),
    ],
    child: MaterialApp(
      home: DetailView(
        item: movie,
        playbackLauncher: (_, request) async {
          launched = request;
          return true;
        },
      ),
    ),
  ),
);
// Tap Play, then playback-server-2.
expect(launched?.server, PlaybackServer.two);
expect(launched?.item.remoteId, 1284041);
```

Add a TV test that taps Server 2, verifies `detail-season-episode-panel`, increments season/episode, taps `playback-season-episode-play`, and expects season 2 episode 2. Add a test using an item with TMDB ID but no IMDb ID to prove Server 2 works.

- [ ] **Step 2: Run focused Detail tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "detail server two"`

Expected: compile failure because `DetailView.playbackLauncher` is absent and Server 2 still calls PlayIMDb.

- [ ] **Step 3: Implement platform-aware launcher**

Use existing external launcher and compact policy:

```dart
typedef PlaybackRequestLauncher = Future<bool> Function(
  BuildContext context,
  PlaybackRequest request,
);

Future<bool> launchPlaybackRequest(
  BuildContext context,
  PlaybackRequest request,
) async {
  final target = playbackTargetFor(request);
  if (target == null) return false;
  final viewportWidth = MediaQuery.sizeOf(context).width;
  if (kIsWeb && target.externalOnWeb) {
    return openExternalPlayerDirect(target.url);
  }
  if (!target.forceEmbedded &&
      shouldOpenPlayerExternally(
        isWeb: kIsWeb,
        viewportWidth: viewportWidth,
      )) {
    return openExternalPlayerCandidates([
      target.url,
      ...target.fallbackUrls,
    ]);
  }
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => FullscreenLandscapeWebPlayer(
        url: target.url.toString(),
        fallbackUrls: target.fallbackUrls,
        loadAsPage: target.loadAsPage,
      ),
    ),
  );
  return true;
}
```

Implement `openExternalPlayerDirect` as `false` in the non-web stub and `window.location.assign(url)` followed by `true` in the web implementation. Do not call HEAD, AllOrigins, or Jina for Cinejoy. Do not await the player route before returning success; route push itself initiates navigation.

- [ ] **Step 4: Replace Detail's provider-specific launch methods**

Add `playbackLauncher = launchPlaybackRequest` to `DetailView`. Remove `RedirectUrlExtractor`, Server 2 redirect extraction, and VSEmbed fallback wiring. Keep one `_launchPlayback(PlaybackRequest request)` method that guards duplicate taps, calls the injected launcher, and shows existing missing-ID/unavailable toasts.

Reuse `DetailEpisodeSelectionSheet` for Server 2 TV. Server 1 and 4 keep their picker. Server 3 remains season 1 episode 1. Rename `_isExtractingRedirectUrl` to `_isLaunchingPlayback` and preserve loading-button behavior.

- [ ] **Step 5: Allow Cinejoy top-level mobile paths**

Extend `_isAllowedPlayerPagePath` without broadening hosts:

```dart
if (uri.host == 'cinejoy.to') {
  return uri.path.startsWith('/watch/movie/') ||
      uri.path.startsWith('/watch/tv/');
}
```

Add a fake-WebView test proving a Cinejoy `/watch/movie/` navigation is allowed and `https://ad.example/` remains blocked.

- [ ] **Step 6: Update server label and run tests**

Change Server 2 title to `Server 2 · Cinejoy` while retaining `playback-server-2` key.

Run: `flutter test test/widget_test.dart --plain-name "detail server two"`

Run: `flutter test test/playback_request_test.dart`

Expected: PASS; redirect extractor is never called by Server 2 because its integration is removed.

### Task 3: Per-User Playback History

**Files:**
- Create: `lib/src/features/playback_history/models/playback_history_entry.dart`
- Create: `lib/src/features/playback_history/repository/playback_history_repository.dart`
- Create: `lib/src/features/playback_history/view_model/playback_history_view_model.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Create: `test/playback_history_repository_test.dart`

**Interfaces:**
- Produces: `PlaybackHistoryEntry.fromRequest(PlaybackRequest request, DateTime startedAt)`
- Produces: `ContentItem PlaybackHistoryEntry.toContentItem()`
- Produces: `PlaybackRequest PlaybackHistoryEntry.toRequest()`
- Produces: `List<PlaybackHistoryEntry> PlaybackHistoryRepository.load(String userId)`
- Produces: `Future<List<PlaybackHistoryEntry>> record(String userId, PlaybackRequest request)`
- Produces: `Future<List<PlaybackHistoryEntry>> remove(String userId, String entryKey)`
- Produces: `@riverpod class PlaybackHistoryViewModel`

- [ ] **Step 1: Write failing repository tests**

Initialize storage with `SharedPreferences.setMockInitialValues({})` and `LocalStorage.init()`. Cover:

```dart
test('record keeps newest first, deduplicates, and isolates users', () async {
  final repository = PlaybackHistoryRepository(
    now: () => DateTime.utc(2026, 8, 8, 12),
  );
  await repository.record('user-a', request);
  await repository.record('user-a', request);
  expect(repository.load('user-a'), hasLength(1));
  expect(repository.load('user-b'), isEmpty);
});

test('malformed local JSON returns empty history', () async {
  await LocalStorage.setString(
    PlaybackHistoryRepository.storageKeyFor('user-a'),
    '{broken',
  );
  expect(repository.load('user-a'), isEmpty);
});
```

Also test TV season/episode round trip, server round trip, removal, clear, and 21 inserts retaining entries 2 through 21.

- [ ] **Step 2: Run repository tests and verify failure**

Run: `flutter test test/playback_history_repository_test.dart`

Expected: compile failure because history classes do not exist.

- [ ] **Step 3: Implement manual JSON history model**

Use only primitives and strings in JSON. Define stable key as:

```dart
String get entryKey =>
    '${mediaType.isEmpty ? type.toLowerCase() : mediaType}:'
    '$tmdbId:${server.name}:$season:$episode';
```

`toContentItem()` restores a neutral Veil palette and chooses `Icons.live_tv_rounded` for TV, otherwise `Icons.movie_rounded`. Clamp parsed season and episode to at least 1. Reject malformed rows lacking positive `tmdbId`, title, or valid server.

- [ ] **Step 4: Implement repository and provider**

Use key `veil.playback_history.v1.$userId`, JSON array persistence, newest-first order, and maximum 20. The notifier watches `authViewModelProvider.user?.id`; missing user returns an empty list and mutation methods no-op.

```dart
@riverpod
class PlaybackHistoryViewModel extends _$PlaybackHistoryViewModel {
  @override
  List<PlaybackHistoryEntry> build() {
    final userId = ref.watch(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return const [];
    return ref.watch(playbackHistoryRepositoryProvider).load(userId);
  }

  Future<void> record(PlaybackRequest request) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    final entries = await ref
        .read(playbackHistoryRepositoryProvider)
        .record(userId, request);
    if (ref.read(authViewModelProvider).user?.id == userId) state = entries;
  }

  Future<void> remove(String entryKey) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    final entries = await ref
        .read(playbackHistoryRepositoryProvider)
        .remove(userId, entryKey);
    if (ref.read(authViewModelProvider).user?.id == userId) state = entries;
  }

  Future<void> clear() async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    await ref.read(playbackHistoryRepositoryProvider).clear(userId);
    if (ref.read(authViewModelProvider).user?.id == userId) state = const [];
  }
}
```

Provide the repository through generated Riverpod code:

```dart
@riverpod
PlaybackHistoryRepository playbackHistoryRepository(Ref ref) {
  return PlaybackHistoryRepository();
}
```

- [ ] **Step 5: Record Detail launches**

After injected launcher returns `true`, call:

```dart
await ref
    .read(playbackHistoryViewModelProvider.notifier)
    .record(request);
```

Do not record when launcher returns false or throws. Keep toast handling after mounted checks.

- [ ] **Step 6: Generate provider output and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `flutter test test/playback_history_repository_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "detail server two"`

Expected: PASS and generated `playback_history_view_model.g.dart` plus repository provider output exist.

### Task 4: Rotating Hero And Continue Watching UI

**Files:**
- Create: `lib/src/features/home/widgets/continue_watching_section.dart`
- Modify: `lib/src/features/home/view/home_view.dart`
- Modify: `lib/src/shared/components/content_cards.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `playbackHistoryViewModelProvider`, `PlaybackRequestLauncher`
- Produces: `ContinueWatchingSection({required List<PlaybackHistoryEntry> entries, required bool editing, required ValueChanged<PlaybackHistoryEntry> onPlay, required ValueChanged<String> onRemove, required VoidCallback onToggleEditing})`

- [ ] **Step 1: Write failing hero rotation test**

Pump `HomeView` with five trending items, provider/collection async providers overridden empty, and assert:

```dart
expect(find.text('Hero 1'), findsOneWidget);
await tester.pump(const Duration(seconds: 7));
await tester.pump(const Duration(milliseconds: 350));
expect(find.text('Hero 2'), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('home-hero-dot-4')));
await tester.pump(const Duration(milliseconds: 350));
expect(find.text('Hero 5'), findsOneWidget);
```

Verify only five dots even when trending has more items, and no pending timer exception after disposing the widget.

- [ ] **Step 2: Write failing history edit/remove test**

Initialize mock SharedPreferences with one movie and one TV entry, override auth with `user-1`, and use the real history notifier. Verify `Continue Watching`, `Recently started`, and `S2 · E3`; tap `continue-watching-edit`, then `continue-watching-remove-{entryKey}` and assert notifier removal leaves one card.

Add a launch test using `HomeView.playbackLauncher` injection. Override `currentUserIsPremiumProvider` to true and expect the captured request matches stored server/episode. Override premium false and expect no launcher call.

- [ ] **Step 3: Run focused Home tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "home hero rotates"`

Run: `flutter test test/widget_test.dart --plain-name "home continue watching"`

Expected: failures because hero is static and history section is absent.

- [ ] **Step 4: Implement timer-driven hero**

Add `_heroIndex`, `_heroTimer`, `_restartHeroTimer()`, and `_selectHero(int index)`. Derive `heroItems = state.globalTrending.take(5).toList()` and guard index against refreshed list size. Wrap complete hero in:

```dart
AnimatedSwitcher(
  duration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 500),
  child: KeyedSubtree(
    key: ValueKey(featured.id),
    child: _HomeHero(
      item: featured,
      activeIndex: _heroIndex,
      itemCount: heroItems.length,
      onSelect: _selectHero,
      onOpen: () => DetailRoute(
        id: featured.id,
        $extra: featured,
      ).push(context),
    ),
  ),
)
```

Make indicators use actual item count and keys `home-hero-dot-$index`. Dispose timer. Precache next non-empty backdrop URL after frame.

- [ ] **Step 5: Implement honest history section**

Cards use backdrop, title, and only real subtitle. Do not render `LinearProgressIndicator` or `progressLabel`. Edit mode shows `Icons.close_rounded` buttons. Hide section when entries are empty. Place it below categories and before Provider/curated/existing rails when All is selected.

On card tap, check `currentUserIsPremiumProvider.value == true`, call injected launcher, then record again on success to move entry to front. Use a toast when entitlement is absent.

- [ ] **Step 6: Run Home and responsive tests**

Run: `flutter test test/widget_test.dart --plain-name "home hero rotates"`

Run: `flutter test test/widget_test.dart --plain-name "home continue watching"`

Run: `flutter test test/widget_test.dart --plain-name "home renders primary feed on desktop without overflow"`

Expected: PASS with no overflow and no fabricated progress labels.

### Task 5: TMDB Watch Providers And Provider Screen

**Files:**
- Create: `lib/src/features/catalog/models/tmdb_watch_provider.dart`
- Create: `lib/src/features/catalog/view_model/provider_catalog_providers.dart`
- Create: `lib/src/features/catalog/view/provider_view.dart`
- Create: `lib/src/features/home/widgets/watch_provider_section.dart`
- Modify: `lib/src/features/catalog/repository/tmdb_repository.dart`
- Modify: `lib/src/core/constants/endpoints.dart`
- Modify: `lib/src/core/router/route_paths.dart`
- Modify: `lib/src/core/router/app_router.dart`
- Modify: `lib/src/features/home/view/home_view.dart`
- Create: `test/watch_provider_repository_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `TmdbWatchProvider({required int id, required String name, required String logoPath, required int displayPriority})`
- Produces: `String? TmdbWatchProvider.logoUrl`
- Produces: `Future<List<TmdbWatchProvider>> TmdbRepository.watchProviders({String region = 'US'})`
- Produces: `Future<List<ContentItem>> TmdbRepository.discoverByProvider({required int providerId, required String mediaType, String region = 'US', int page = 1})`
- Produces: `watchProvidersProvider`, `providerMoviesProvider(int id)`, `providerTvProvider(int id)`
- Produces: `ProviderRoute({required int id, String? name, String? logoPath})`

- [ ] **Step 1: Write failing repository tests**

Fake both provider-list endpoints with overlapping IDs. Assert merge by ID, lowest priority, non-empty logo, and final order. Assert discover request:

```dart
expect(options.path, '$_tmdbProxyBaseUrl/discover/movie');
expect(options.queryParameters, containsPair('watch_region', 'US'));
expect(options.queryParameters, containsPair('with_watch_providers', 8));
expect(
  options.queryParameters,
  containsPair('with_watch_monetization_types', 'flatrate|free|ads'),
);
expect(options.queryParameters, containsPair('include_adult', false));
```

Repeat media mapping assertion for TV. Include a tester-account case and fake detail lookups proving Disney/Pixar results are removed.

- [ ] **Step 2: Run repository tests and verify failure**

Run: `flutter test test/watch_provider_repository_test.dart`

Expected: compile failure because provider APIs and model are absent.

- [ ] **Step 3: Implement provider repository methods**

Add endpoint getters for `/watch/providers/movie` and `/watch/providers/tv`. Parse `provider_id`, `provider_name`, `logo_path`, `display_priority`, and `display_priorities[region]`. Merge duplicates in a map and sort ascending by priority then lowercase name. Use `AppEnvironment.tmdbImageUrl('w154', logoPath)`.

For discover, validate media type is `movie` or `tv`, then call existing `_getMediaList` so credential handling and tester restrictions remain centralized.

- [ ] **Step 4: Add independent Riverpod providers**

```dart
@riverpod
Future<List<TmdbWatchProvider>> watchProviders(Ref ref) {
  return ref.watch(tmdbRepositoryProvider).watchProviders();
}

@riverpod
Future<List<ContentItem>> providerMovies(Ref ref, int providerId) {
  return ref.watch(tmdbRepositoryProvider).discoverByProvider(
    providerId: providerId,
    mediaType: 'movie',
  );
}

@riverpod
Future<List<ContentItem>> providerTv(Ref ref, int providerId) {
  return ref.watch(tmdbRepositoryProvider).discoverByProvider(
    providerId: providerId,
    mediaType: 'tv',
  );
}
```

- [ ] **Step 5: Add typed route and ProviderView**

Add `RoutePaths.provider = '/provider/:id'`. `ProviderView` watches movie and TV providers separately and handles all `AsyncValue` states. One error shows retry for that section only. Cards open `DetailRoute`. Header uses provider logo when present. Footer copy is exactly `Streaming availability data by JustWatch · Catalog data by TMDB`.

- [ ] **Step 6: Add Home provider rail**

Render up to 12 providers with square logo, name, and key `watch-provider-{id}`. Hide section on empty data. On error, show compact Retry without changing Home VM state. Tap pushes `ProviderRoute` with ID/name/logo path.

- [ ] **Step 7: Add widget tests and generate routes/providers**

Test Home provider tap using router or direct ProviderView pump. Test ProviderView partial failure by overriding movies with data and TV with `AsyncError`; verify Movies remain visible and TV Retry appears.

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `flutter test test/watch_provider_repository_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "provider"`

Expected: PASS and generated route/provider outputs compile.

### Task 6: Shegu Curated Collections

**Files:**
- Create: `lib/src/features/catalog/models/curated_collection.dart`
- Create: `lib/src/features/catalog/repository/curated_collection_repository.dart`
- Create: `lib/src/features/catalog/view_model/curated_collection_providers.dart`
- Create: `lib/src/features/home/widgets/curated_collection_section.dart`
- Modify: `lib/src/features/home/view/home_view.dart`
- Create: `test/curated_collection_repository_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `CuratedCollection({required String id, required String title, required String description, required List<String> tags})`
- Produces: `Future<List<CuratedCollection>> CuratedCollectionRepository.collections()`
- Produces: `Future<List<ContentItem>> CuratedCollectionRepository.items(String collectionId, {int limit = 12})`
- Produces: `curatedCollectionsProvider`, `curatedCollectionItemsProvider(String id)`

- [ ] **Step 1: Write failing parser tests**

Fake `https://lists.shegu.st/joy` and one `/joy/psychological-thrillers?limit=12` response. Assert metadata, movie mapping, TV mapping, score clamp, image URL proxy resolution, and rows without `ids.tmdb` omitted.

Use a fake `TmdbRepository.shouldHideForCurrentUser` override that hides one item, then assert it does not reach results.

- [ ] **Step 2: Run repository tests and verify failure**

Run: `flutter test test/curated_collection_repository_test.dart`

Expected: compile failure because curated models/repository do not exist.

- [ ] **Step 3: Implement defensive repository**

Use the existing `Api.general` Dio client with absolute URLs and no Cinejoy headers or key. Validate root keys before casting. Map only approved fields. Build IDs as `movie-{tmdbId}` or `tv-{tmdbId}`. Resolve poster only when the trimmed source is non-empty, then use:

```dart
rating: ((json['score'] as num?)?.toDouble() ?? 0)
    .clamp(0, 10)
    .toDouble(),
posterUrl: poster.isEmpty
    ? null
    : AppEnvironment.resolveTmdbImageUrl(poster),
```

Use `TmdbRepository.shouldHideForCurrentUser` for each valid item before returning. Cache successful item lists by collection ID inside repository instance; do not cache errors.

- [ ] **Step 4: Add async providers and Home selector**

Provider families delegate to repository and let exceptions become `AsyncError`:

```dart
@riverpod
Future<List<CuratedCollection>> curatedCollections(Ref ref) {
  return ref.watch(curatedCollectionRepositoryProvider).collections();
}

@riverpod
Future<List<ContentItem>> curatedCollectionItems(
  Ref ref,
  String collectionId,
) {
  return ref
      .watch(curatedCollectionRepositoryProvider)
      .items(collectionId);
}
```

`CuratedCollectionSection` owns selected ID in widget state, defaults to first returned collection, shows horizontally scrolling choice chips, and watches only selected family. Keep prior `AsyncData` visible during refresh where Riverpod supplies it.

Item cards open Detail. Error UI contains key `curated-collection-retry`. Empty collections show `No curated titles available.` without affecting other Home sections.

- [ ] **Step 5: Add widget tests**

Override collection metadata and two item-family instances. Tap second choice and verify first rail title disappears while second appears. Override selected items with `AsyncError`, tap retry, and verify provider invalidation is invoked by observing the next `AsyncData`.

- [ ] **Step 6: Generate and run focused tests**

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `flutter test test/curated_collection_repository_test.dart`

Run: `flutter test test/widget_test.dart --plain-name "curated"`

Expected: PASS; Shegu errors remain local to section.

### Task 7: Detail Recommendations And Navigation Polish

**Files:**
- Create: `lib/src/features/detail/widgets/detail_recommendation_rails.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Modify: `lib/src/features/shell/view/veil_shell_view.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `DetailRecommendationRails({required List<ContentItem> recommendations, required List<ContentItem> similar})`

- [ ] **Step 1: Write failing recommendation widget test**

Pump Detail with one recommendation and similar list containing one duplicate plus one unique title. Verify section headings `Recommended for you` and `More like this`, duplicate appears once, and tapping recommendation opens its Detail route.

- [ ] **Step 2: Write failing navigation style/overflow test**

At 390x844, verify four destination icons fit, selected Home pill remains visible, and selected container does not use `VeilColors.red`. At desktop size, verify `NavigationRail` remains.

- [ ] **Step 3: Run focused tests and verify failure**

Run: `flutter test test/widget_test.dart --plain-name "detail recommendations"`

Run: `flutter test test/widget_test.dart --plain-name "responsive shell keeps bottom navigation on mobile"`

Expected: recommendation test fails because rails are absent; style assertion fails while selected pill is red.

- [ ] **Step 4: Implement recommendation rails**

Deduplicate similar items against recommendation TMDB identity:

```dart
final recommendationIds = recommendations
    .map((item) => '${item.mediaType}:${item.remoteId}')
    .toSet();
final uniqueSimilar = similar.where(
  (item) => !recommendationIds.contains('${item.mediaType}:${item.remoteId}'),
);
```

Render nothing for empty lists. Use existing responsive poster sizing and `DetailRoute` taps. Insert rails after `_TabContent` so recommendations stay visible regardless active tab.

- [ ] **Step 5: Polish mobile glass navigation**

Keep `BackdropFilter`, safe-area margins, inactive icon-only layout, active icon+label, and `IndexedStack`. Change active background to a neutral translucent surface such as `Colors.white.withValues(alpha: .16)`, selected icon/text to white, and border to `Colors.white24`. Keep red for page actions, not selection. Preserve desktop rail code.

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/widget_test.dart --plain-name "detail recommendations"`

Run: `flutter test test/widget_test.dart --plain-name "responsive shell"`

Expected: PASS with no mobile overflow and unchanged desktop rail.

### Task 8: Generated Outputs And Full Verification

**Files:**
- Regenerate: `lib/src/core/router/app_router.g.dart`
- Regenerate: provider `*.g.dart` files created by Tasks 3, 5, and 6
- Modify generated files only through build runner.

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: analyzable, tested app with synchronized generated code.

- [ ] **Step 1: Regenerate all annotated outputs**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: success; no conflicting output warning.

- [ ] **Step 2: Format changed Dart files**

Run: `dart format lib test`

Expected: formatter exits 0.

- [ ] **Step 3: Run focused suites together**

Run: `flutter test test/playback_request_test.dart test/playback_history_repository_test.dart test/watch_provider_repository_test.dart test/curated_collection_repository_test.dart test/home_view_model_test.dart test/tmdb_repository_test.dart`

Expected: all pass.

- [ ] **Step 4: Run full widget suite**

Run: `flutter test test/widget_test.dart`

Expected: all pass; no pending timers, network leaks, or overflows.

- [ ] **Step 5: Run full tests and analyzer**

Run: `flutter test`

Run: `flutter analyze`

Expected: both exit 0 with no new diagnostics.

- [ ] **Step 6: Inspect final diff**

Run: `git diff --check`

Run: `git status --short`

Confirm no API key from supplied traffic, no generated file was manually edited, no unrelated user changes were altered, and spec requirements map to passing tests.
