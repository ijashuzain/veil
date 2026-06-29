## Why

Veil already has partial follow requests, follower lists, alerts, and movie suggestions, but the behavior is inconsistent with an Instagram-like social model. This change makes follow requests, follow-back, friend status, and suggested movies/series coherent across the profile, alerts, repository, and Supabase layers.

## What Changes

- Formalize user relationships as asymmetric follows with pending follow requests and derived mutual-friend status.
- Keep acceptance as an approval for the requester to follow the recipient, then expose a real Follow Back path for mutual friendship.
- Show incoming follow requests in Alerts with Accept and Decline actions.
- Show accepted follow notifications and provide a way for them to stop appearing after read/dismiss handling.
- Replace passive Follow Back labels with actionable profile/list states where appropriate.
- Limit movie/series suggestions to friends, defined as mutual follows.
- Show suggested movies/series from friends in Alerts with unread/read handling and navigation to content detail.
- Move sensitive follow/request/suggestion state transitions behind Supabase-enforced behavior so RLS and RPCs match app expectations.

## Capabilities

### New Capabilities
- `social-connections`: Follow request lifecycle, accepted follows, follow-back, unfollow, derived friend state, and follow-related alerts.
- `friend-content-suggestions`: Suggesting movies/series to friends, receiving suggestion alerts, marking suggestions read, and opening suggested content.

### Modified Capabilities
- None.

## Impact

- Flutter social/profile/search/detail/alerts UI and Riverpod view models.
- `SocialRepository` follow request, follow status, follower/following, and movie suggestion methods.
- Supabase migrations for follow request RPCs/RLS, suggestion authorization, and read/dismiss metadata.
- Existing tests for social repository, alerts, profile follow flows, and suggestion delivery.
