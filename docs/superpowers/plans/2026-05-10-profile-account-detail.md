# Profile Account Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved Profile/account deletion cleanup and TMDB-backed detail hero/clips behavior.

**Architecture:** Profile remains a self-contained Flutter view with small local pages for member lists, activity, and legal text. SocialRepository owns account deletion persistence, using a Supabase RPC when authenticated and a local fallback for tests/offline state. DetailViewModel enriches detail state with a trending rank from TMDB; DetailView renders the rank and YouTube clip actions.

**Tech Stack:** Flutter, Riverpod, Supabase Flutter, SharedPreferences local fallback, TMDB repository, widget/unit tests.

---

### Task 1: Tests

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/social_repository_test.dart`

- [ ] Add widget tests for Profile removing TMDB/reviews/tabs, opening dedicated Following/Followers pages, showing settings rows, and delete-account reason/confirmation.
- [ ] Add widget tests for Detail showing title as large text, tagline as subtitle, hiding/showing TMDB trending rank dynamically, and using Clips/YouTube labels.
- [ ] Add a repository test that local account deletion removes follows/private entries while retaining reviews.
- [ ] Run the targeted tests and confirm they fail for missing behavior before implementation.

### Task 2: Profile UI

**Files:**
- Modify: `lib/src/features/profile/view/profile_view.dart`

- [ ] Remove the gear, TMDB disclaimer, profile review count, and profile tabs.
- [ ] Add tappable Following/Followers stats that push dedicated member-list pages.
- [ ] Add grouped settings sections above Sign out.
- [ ] Add My Activity and static legal pages.
- [ ] Wire Import/Export row to the existing Letterboxd sheet.

### Task 3: Account Deletion

**Files:**
- Modify: `lib/src/features/social/repository/social_repository.dart`
- Modify: `lib/src/features/social/view_model/social_library_view_model/social_library_view_model.dart`
- Modify: `lib/src/features/profile/view/profile_view.dart`
- Add: `docs/supabase/veil_account_deletion.sql`

- [ ] Add `deleteCurrentAccount(reason)` to SocialRepository.
- [ ] Authenticated path calls Supabase RPC `delete_current_account`.
- [ ] Local path removes follow rows involving the current user, removes private/non-review entries, keeps reviews, and clears retained review flags that should not remain private library state.
- [ ] Profile delete flow collects reason, confirms, calls repository, refreshes state, signs out, and navigates to onboarding.
- [ ] SQL doc adds soft-delete columns and the RPC.

### Task 4: Detail Trending And Clips

**Files:**
- Modify: `lib/src/features/detail/view_model/detail_view_model/detail_view_model.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Modify generated files only via build_runner if needed.

- [ ] Add nullable `trendingRank` to DetailViewState.
- [ ] Load TMDB detail and trending together; compute rank by `mediaType + remoteId`.
- [ ] Render the banner only when rank is present.
- [ ] Swap title/subtitle display.
- [ ] Rename `Episodes` tab to `Clips`.
- [ ] Render TMDB video rows only, with clean source text.
- [ ] Add clip tap handling and route YouTube clips to a launcher callback.

### Task 5: Verify

**Files:**
- No direct code edits.

- [ ] Run `flutter pub get` if dependencies/generated metadata changed.
- [ ] Run `flutter test test/social_repository_test.dart`.
- [ ] Run targeted widget tests.
- [ ] Run full `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter build web --release`.
