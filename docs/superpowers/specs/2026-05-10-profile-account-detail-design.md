# Profile Account Detail Design

## Goal

Clean up Profile, add account deletion with retained public social content, and make the detail hero/clips areas truthful to TMDB data.

## Profile

- Remove the TMDB disclaimer from the Profile page.
- Remove Reviews from the Profile count section.
- Remove the Following, Followers, and Activity tabs from Profile.
- Keep Following and Followers as tappable counts. Each opens a dedicated member-list page with the same dark visual language and empty states.
- Remove the settings gear from the profile header.
- Add iOS-style grouped settings rows above Sign out:
  - My Activity
  - Import/Export
  - Privacy Policy
  - Terms and Condition
  - Delete Account

## Account Deletion

Deletion is implemented as a soft-delete/anonymize flow because the current Supabase schema cascades hard auth-user deletion into reviews, comments, and likes. The app must preserve those public social records and display them as from `Deleted user`.

Flow:

- User taps Delete Account.
- App opens a bottom sheet asking for a reason.
- App shows a destructive confirmation dialog.
- Repository calls a Supabase RPC named `delete_current_account`.
- The RPC marks the profile deleted, records the reason, deletes follow edges where the user is either follower or followed, removes private/non-review library rows, and keeps review/comment/like records.
- The app signs out after the delete RPC completes.

Local fallback mirrors the same behavior for tests and non-Supabase sessions.

## Detail Page

- Swap the hero title/subtitle roles: the large hero text should be the real title, and the small text should be the tagline/subtitle.
- Replace the hard-coded `ON TRENDING #1` banner with a TMDB-backed rank.
- DetailViewModel fetches weekly TMDB trending, matches `mediaType + remoteId`, and stores a 1-based rank.
- Show `ON TRENDING #N` only when a rank exists. Hide the banner otherwise.
- Rename the `Episodes` tab to `Clips`.
- Clips come from TMDB `videos.results`; do not create fake episode rows.
- YouTube clips navigate to `https://www.youtube.com/watch?v=<key>`.
- Clip source text should be `YouTube` for YouTube clips, never `YouTube trailer key`.

## Testing

- Widget tests cover Profile layout changes, dedicated member pages, settings rows, deletion reason and confirmation UI, detail title/subtitle swap, dynamic trending banner, and Clips behavior.
- Repository tests cover local soft-delete behavior.
- Existing tests for reviews, diary, search, responsive shell, and playback must continue passing.
