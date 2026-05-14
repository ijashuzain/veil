# Social Actions, Diary, Search, And Follow Integration Plan

**Goal:** Move Veil closer to the supplied Letterboxd-style references while fitting the current Flutter/Riverpod/Supabase architecture.

**Scope:**
- Movie detail gets one unified action entry: `Rate, log, review + more`.
- User ratings are app-specific 1-5 stars. TMDB ratings remain separate metadata.
- The unified action sheet includes only Watched, Like, Watchlist, Rating, Review, and Done.
- Review flow opens as a dedicated bottom sheet, requires a rating, supports first-time/rewatch, and saving a rating or review marks the title watched.
- Diary becomes tabbed: Watched, Watchlist, Favorites, with compact 4-column grids and no section-level See All.
- Search gains switchable chips: All, Users, Films, Cast. All shows every supported result type.
- Profiles expose following/followers counts and lists; other profiles can be followed/unfollowed.

**Architecture:**
- Keep `SocialEntry.rating` as the app user rating, clamped to 1-5 when a user explicitly rates.
- Use existing `tags` for first-time/rewatch until a separate normalized watch metadata column is required.
- Keep Supabase as optional. Local fallback will persist follows in shared preferences; authenticated Supabase users will use a new `user_follows` table.
- Avoid new top-level packages.

## Task 1: Data And Behavior Tests

- Add repository tests proving explicit social ratings clamp to 1-5 and rating/review saves also create watched diary entries.
- Add follow repository tests for follow, unfollow, follower list, and following list.
- Add widget tests for detail unified action sheet and diary tabs.

## Task 2: Social Repository And View Model

- Add methods:
  - `rate(ContentItem item, {required double rating, List<String> tags})`
  - `setWatched(ContentItem item, {required bool watched, double rating, List<String> tags})`
  - `followUser(String userId)`, `unfollowUser(String userId)`, `followers(String userId)`, `following(String userId)`, `isFollowing(String userId)`
- Clamp explicit rating values to 1-5 while preserving 0 as "unrated" for older/empty entries.
- Update `SocialLibraryViewModel` to expose wrappers for the new actions.

## Task 3: Detail UX

- Replace the four-button detail action strip with a ratings/action panel and one primary button.
- Open a bottom sheet modeled on the reference with Watched, Like, Watchlist, 1-5 rating, Review, and Done.
- Rename Log to Watched in UI.
- The Review row opens the review bottom sheet.
- The review sheet uses 1-5 stars, a review text field, First-time/Rewatch toggle, and Save. Save is disabled until a rating is selected.

## Task 4: Diary UX

- Convert `DiaryView` to a stateful tabbed view.
- Top tabs: Watched, Watchlist, Favorites.
- Render entries as compact 4-column poster grid with star rating below posters.
- Remove See All buttons because each tab shows its full list.
- Keep compact genre/rating filters for the Watched tab.

## Task 5: Search UX

- Add local search scope state in `SearchView`: All, Users, Films, Cast.
- Update placeholder to match the reference: `Find films, cast + crew, members...`.
- All shows users and TMDB results. Users shows only users. Films shows movie/TV content. Cast shows person/studio-like TMDB results when available through `ContentItem.type`; otherwise it shows the current TMDB results filtered away from films.

## Task 6: Profiles And Follows

- Update Supabase schema doc with `user_follows`.
- Show Following and Followers counts on my profile and other user profiles.
- Add Follow/Following button on other profiles.
- Provide followers/following list bottom sheets from profile stats.

## Verification

- Run `dart run build_runner build --delete-conflicting-outputs`.
- Run `flutter test`.
- Run `flutter analyze`.
- Run `flutter build apk --debug`.
- Run `flutter build ios --simulator --debug`.
