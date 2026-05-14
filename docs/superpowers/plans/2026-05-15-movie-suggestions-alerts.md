# Movie Suggestions And Social Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build movie suggestions, follow request alerts, and display-name user search.

**Architecture:** Extend `SocialRepository` with profile search, movie suggestions, and follow request APIs. Add plain Dart model classes for these social objects. Update `AlertsViewModel`, `AlertsView`, `SearchViewModel`, `SearchView`, `DetailSocialActionSheet`, and `DetailView` to consume the new APIs.

**Tech Stack:** Flutter, Riverpod codegen, Freezed state classes, Supabase, SharedPreferences local fallback, Flutter widget tests.

---

### Task 1: Repository Models And Local Fallbacks

**Files:**
- Create: `lib/src/features/social/models/user_profile_summary.dart`
- Create: `lib/src/features/social/models/movie_suggestion.dart`
- Create: `lib/src/features/social/models/follow_request.dart`
- Modify: `lib/src/features/social/repository/social_repository.dart`
- Test: `test/social_repository_test.dart`

- [ ] Add failing tests for profile search, follow requests, and movie suggestions.
- [ ] Add model classes with `fromJson`, `toJson`, Supabase mapping, and `ContentItem` conversion for suggestions.
- [ ] Add local storage keys and methods for profiles, suggestions, and follow requests.
- [ ] Add Supabase branches using RPC/table calls.
- [ ] Run `rtk flutter test test/social_repository_test.dart`.

### Task 2: Search By Display Name

**Files:**
- Modify: `lib/src/features/search/view_model/search_view_model.dart`
- Modify: `lib/src/features/search/view/search_view.dart`
- Test: `test/widget_test.dart`

- [ ] Add `users` to `SearchViewState`.
- [ ] Query `SocialRepository.searchUserProfiles` alongside TMDB search.
- [ ] Merge directory users with existing review-derived user rows in `SearchView`.
- [ ] Add or update widget tests proving a member is found by display name.
- [ ] Run targeted search widget tests.

### Task 3: Alerts Tabs And Follow/Suggestion Rows

**Files:**
- Modify: `lib/src/features/alerts/view_model/alerts_view_model.dart`
- Modify: `lib/src/features/alerts/view/alerts_view.dart`
- Test: `test/alerts_view_model_test.dart`
- Test: `test/alerts_view_test.dart`

- [ ] Add suggestions and follow requests to `AlertsViewState`.
- [ ] Load social alerts along with TMDB alerts.
- [ ] Add `Alerts` and `Suggestions` tab UI.
- [ ] Add accept/decline and mark-read actions.
- [ ] Run alerts tests.

### Task 4: Detail Suggest Flow

**Files:**
- Modify: `lib/src/features/detail/widgets/detail_social_action_sheet.dart`
- Create: `lib/src/features/detail/widgets/detail_suggestion_sheet.dart`
- Modify: `lib/src/features/detail/view/detail_view.dart`
- Test: `test/widget_test.dart`

- [ ] Add `Suggest` row under `Review`.
- [ ] Add follower multi-select sheet.
- [ ] Send selected followers through `SocialRepository.suggestMovie`.
- [ ] Show loading/empty/success/error states.
- [ ] Run detail widget tests.

### Task 5: Follow Request UI

**Files:**
- Modify: `lib/src/features/user_profile/view/user_profile_view.dart`
- Test: `test/widget_test.dart`

- [ ] Load pending request state for the viewed user.
- [ ] Change `Follow` tap to send a request.
- [ ] Show `Requested` while pending and `Unfollow` only after acceptance.
- [ ] Run user profile follow tests.

### Task 6: Supabase Documentation And Verification

**Files:**
- Modify: `docs/supabase/veil_social_schema.sql`

- [ ] Append profile-search, movie-suggestions, and follow-request SQL to the Supabase schema doc.
- [ ] Run `rtk dart run build_runner build --delete-conflicting-outputs`.
- [ ] Run `rtk flutter test`.
