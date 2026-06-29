## 1. Supabase Schema And Policies

- [x] 1.1 Add a migration for follow request read/dismiss metadata needed by accepted-follow notices.
- [x] 1.2 Add or replace Supabase RPCs for request/follow-back, accept request, decline request, cancel outgoing request, unfollow, and mark accepted notices read.
- [x] 1.3 Update follow request and follow edge RLS so users can only act on their own requests/edges through allowed paths.
- [x] 1.4 Update movie suggestion insert behavior so new suggestions are allowed only for mutual friends and blocked relationships are rejected.
- [x] 1.5 Preserve participant-only suggestion visibility and recipient-only read updates.

## 2. Repository And Domain State

- [x] 2.1 Extend follow request parsing/serialization with accepted-notice read or dismiss metadata while tolerating older local data.
- [x] 2.2 Add an explicit relationship state for none, requested, follows-me, following, friends, and incoming-request cases.
- [x] 2.3 Update `SocialRepository` follow methods to create pending requests for normal follows and immediate reciprocal follows for Follow Back.
- [x] 2.4 Update accept, decline, cancel, unfollow, and mark-read methods for both Supabase and local fallback parity.
- [x] 2.5 Add repository methods to load mutual friends and relationship state without duplicating UI-side graph logic.
- [x] 2.6 Update movie suggestion creation to use mutual friends and backend-enforced eligibility.

## 3. Profile And Connection UI

- [x] 3.1 Update user profile loading to consume explicit relationship state instead of only `isFollowing` plus outgoing request status.
- [x] 3.2 Update profile header labels and actions for Follow, Requested, Follow Back, Following, Friends, cancel request, and Unfollow states.
- [x] 3.3 Make follower/following member rows use resolved profile summaries instead of raw IDs where possible.
- [x] 3.4 Make Follow Back in member rows actionable and refresh local profile counts/state after completion.
- [x] 3.5 Keep blocked users hidden from profile member lists and relationship actions.

## 4. Suggestions UI And Alerts

- [x] 4.1 Update the detail suggestion sheet to load mutual friends instead of followers and adjust the empty state copy.
- [x] 4.2 Update suggestion submission feedback so successful sends only claim delivery to eligible selected friends.
- [x] 4.3 Update alerts state to include social unread counts from pending follow requests, unread accepted notices, and unread suggestions.
- [x] 4.4 Update Alerts UI to render accepted follow notices and allow mark-read/dismiss behavior.
- [x] 4.5 Ensure tapping a suggestion marks it read and navigates to the correct movie or series detail.
- [x] 4.6 Ensure the home alert badge reflects combined unread social and TMDB alert state.

## 5. Tests And Generated Files

- [x] 5.1 Add repository tests for request, accept, decline, cancel, follow-back, unfollow, friendship derivation, and block rejection.
- [x] 5.2 Update suggestion tests so only mutual friends receive suggestions and non-friends are rejected or ignored.
- [x] 5.3 Update alerts view model and widget tests for combined unread counts, pending requests, accepted notices, mark-read, and suggestion navigation.
- [x] 5.4 Update profile/widget tests for Requested, Follow Back, Friends, and Unfollow states.
- [x] 5.5 Regenerate Riverpod/Freezed outputs if provider or Freezed state shapes change.
- [x] 5.6 Run `flutter analyze` and the focused social/alerts/profile tests; run full `flutter test` if time permits.
