## Context

The current app already has partial social primitives: `user_follows`, `follow_requests`, `movie_suggestions`, profile follow UI, alerts UI, and a detail-page suggestion sheet. The behavior is not yet coherent as a product model: accepting a follow request creates a one-way follow edge, follower rows show a passive `Follow back` label, suggestions are sent to followers rather than mutual friends, and social alert unread state is not fully represented in the home badge.

Supabase is the source of truth for authenticated users, with local SharedPreferences fallback paths used by tests and unconfigured Supabase scenarios. Any change to social semantics must keep those paths aligned.

## Goals / Non-Goals

**Goals:**
- Model connections as asymmetric follow edges with explicit pending requests and derived mutual-friend state.
- Make incoming follow requests actionable in Alerts and keep accepted-request notifications readable/dismissible.
- Make Follow Back a real action that creates a reciprocal follow when the other member already follows the viewer.
- Limit movie/series suggestions to mutual friends and show received suggestions in Alerts with unread/read behavior.
- Enforce sensitive follow/request/suggestion transitions in Supabase RPCs/RLS, with local fallback parity.
- Preserve existing feature-first Flutter structure and current Supabase/local repository split.

**Non-Goals:**
- Push notifications, OS-level notification permissions, or background delivery.
- Private profile/activity access control. Existing public authenticated diary/review visibility remains unchanged.
- A separate `friends` table. Friend status is derived from mutual rows in `user_follows`.
- Large redesign of the social/profile UI beyond the states required for this feature.

## Decisions

### Keep Asymmetric Follows and Derive Friends

Use `user_follows(follower_id, following_id)` as the only durable relationship edge. A friendship exists when both directions are present.

Alternative considered: create a separate `friendships` table. This would make friend queries direct, but it duplicates state and creates sync risks with follow/unfollow. Deriving friendship from follows fits the Instagram-like model and the existing schema.

Alternative considered: accepting a request creates both follow edges. That makes `Follow Back` meaningless and removes the useful distinction between approved follower and mutual friend.

### Follow Back Creates a Reciprocal Edge Without a Second Request

When user A already follows user B because B accepted A's request, B can tap Follow Back to immediately create `B -> A`. This avoids a ping-pong where both users must approve each other after one already initiated the relationship.

For a normal follow where the target does not already follow the viewer, create or reopen a pending follow request instead of inserting a follow edge directly.

### Centralize Social Transitions in Repository Methods Backed by RPC/RLS

Use app-facing repository methods for request, accept, decline, cancel, unfollow, relationship status, and suggestion delivery. For authenticated users, the repository should call Supabase RPCs or RLS-backed operations that enforce ownership, block checks, and mutual-friend requirements. Local fallback should mirror the same semantics for tests and offline/unconfigured paths.

Expected backend operations include:
- request or follow-back user
- accept follow request
- decline follow request
- cancel pending outgoing request
- unfollow user
- mark accepted follow notice read/dismissed
- insert movie suggestions only for mutual friends

### Represent Relationship State Explicitly in the UI Layer

Profiles and member rows should not infer state from one boolean plus request status. The UI should consume an explicit relationship state such as none, requested, followsMe, following, friends, or incomingRequest. This keeps labels and actions consistent across profile headers, follower/following lists, search-to-profile flows, and alerts.

### Treat Alerts as an In-App Inbox, Not Push Notifications

Alerts should aggregate generated TMDB alerts, pending incoming follow requests, accepted follow notices, and unread movie/series suggestions. Pending follow requests count as unread while pending. Accepted follow notices count as unread until the requester marks or dismisses them. Suggestions continue to use `read_at` for unread state.

No realtime/push transport is required in this change; alerts refresh through existing load flows.

### Restrict Suggestions to Mutual Friends

The suggestion sheet should list mutual friends, not every follower. The backend must enforce that each recipient has a reciprocal follow relationship with the sender. This prevents suggestions from becoming follower spam while matching the product wording of suggesting to friends.

## Risks / Trade-offs

- Relation state drift between Supabase and local fallback -> Add repository tests that run the full request, accept, follow-back, unfollow, and suggestion flows locally, and keep Supabase RPC semantics mirrored in Dart.
- Existing accepted follow requests have no read/dismiss marker -> Add nullable metadata and let old accepted notices appear until the requester marks them read.
- RLS/RPC mistakes could allow direct writes that bypass rules -> Prefer security-definer RPCs for transitions and restrict direct table updates/inserts to participant-safe operations.
- Mutual-friend suggestions may surprise users who previously could suggest to followers -> Update empty states and copy to explain that suggestions are for friends.
- Alerts badge remains load-driven, not realtime -> Document as in-app unread state; defer realtime or push notifications.

## Migration Plan

1. Add Supabase migration(s) for follow notice read/dismiss metadata and RPC/RLS updates.
2. Keep existing `user_follows`, `follow_requests`, and `movie_suggestions` rows; do not backfill a new friendship table.
3. Preserve existing suggestions and show them to recipients, but enforce mutual-friend eligibility for new suggestions.
4. Update local fallback serialization with any new follow-request metadata while tolerating missing fields.
5. Rollback can disable new UI paths and restore prior policies/RPC bodies; existing one-way follow rows remain valid.

## Open Questions

- Should declined follow requests ever be visible to the requester, or remain silent as they do today?
- Should accepted follow notices be auto-marked read when the requester opens Alerts, or only when tapping Mark read/dismiss?
