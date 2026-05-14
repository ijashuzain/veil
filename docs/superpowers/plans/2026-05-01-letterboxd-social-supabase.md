# Letterboxd-Style Social Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a first working Letterboxd-style social layer using TMDB media data, local fallback storage, and optional Supabase persistence.

**Architecture:** Keep TMDB as the media source of truth and put user-owned activity behind a `social` feature. Views use Riverpod view models; view models call `SocialRepository`; the repository writes to Supabase when configured and to `SharedPreferences` fallback otherwise.

**Tech Stack:** Flutter, Riverpod generator, Freezed, JsonSerializable, SharedPreferences, optional `supabase_flutter`, TMDB `ContentItem` snapshots.

---

### Task 1: Social Data Model And Repository

**Files:**
- Create: `lib/src/features/social/models/social_entry/social_entry.dart`
- Create: `lib/src/features/social/repository/social_repository.dart`
- Create: `test/social_repository_test.dart`

- [ ] **Step 1: Write failing repository tests**

```dart
test('logs watched films with rating, review, and tags', () async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.init();
  final repo = SocialRepository();
  final entry = await repo.logWatched(item, rating: 4.5, review: 'Excellent', tags: ['imax']);
  expect(entry.rating, 4.5);
  expect((await repo.diary()).single.review, 'Excellent');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/social_repository_test.dart`
Expected: fail because `SocialRepository` does not exist.

- [ ] **Step 3: Implement model and repository**

Create `SocialEntry` with `tmdbId`, `mediaType`, `title`, poster/backdrop snapshot, `rating`, `review`, `tags`, `watchedOn`, `isFavorite`, `inWatchlist`, timestamps. Implement local JSON persistence and optional Supabase table IO.

- [ ] **Step 4: Run focused test**

Run: `flutter test test/social_repository_test.dart`
Expected: all social repository tests pass.

### Task 2: Supabase Config And Schema

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/src/core/config/app_environment.dart`
- Create: `lib/app/services/supabase_services/supabase_service.dart`
- Create: `docs/supabase/veil_social_schema.sql`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add optional Supabase dependency/config**

Add `supabase_flutter`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`. Initialize Supabase only when both values are present so the app stays runnable without credentials.

- [ ] **Step 2: Add SQL schema with RLS**

Create `film_entries` table with `user_id uuid`, TMDB snapshot columns, rating/review/tags/watchlist/favorite flags, and RLS policies using `auth.uid() = user_id`.

### Task 3: Social View Model And UI

**Files:**
- Create: `lib/src/features/social/view_model/social_library_view_model/social_library_view_model.dart`
- Create: `lib/src/features/social/view/diary_view.dart`
- Modify: `lib/src/features/shell/view/veil_shell_view.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Modify: `lib/src/features/profile/view/profile_view.dart`

- [ ] **Step 1: Add social view model**

Load entries, expose diary/watchlist/favorites/reviews/stats, and actions for log watched, rate/review, favorite, and watchlist.

- [ ] **Step 2: Add Diary tab**

Render diary entries, recent reviews, watchlist, favorites, and empty-state starter actions.

- [ ] **Step 3: Add detail actions**

Wire “Log watched”, “Review”, “Favorite”, and “Watchlist” buttons to the social view model.

- [ ] **Step 4: Update profile**

Replace static stats/watchlist/recently watched with user-owned social data when present.

### Task 4: Verification

- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Run `flutter test`
- [ ] Run `flutter analyze`
- [ ] Run `flutter build apk --debug`
