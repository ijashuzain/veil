# Shared subtitles

Player 1 and Player 2 share a subtitle service:

1. Wyzie searches by TMDB identity, plus season and episode for TV.
2. If Wyzie fails or returns no usable tracks, an optional self-hosted instance of
   `bipuldey19/Opensubtitles-Unofficial-API` searches by title. Movies require exact
   normalized title and year matches before fetching tracks.
3. Video-provider tracks remain available in the picker.

Shared tracks show source and release labels. Parsed SRT/VTT captions and search
results are cached for the player repository lifetime. Timing controls provide
half-second adjustments and reset, bounded to 60 seconds each way. The separate
OS fullscreen handoff does not transfer sidecar captions.

## Backend

The `subtitles` Edge Function validates the signed-in Supabase user. Provider
credentials stay server-side. Downloads are restricted to subtitle paths on fixed
provider hosts. Wyzie redirects are rejected; fallback redirects are validated.
Fallback ZIP downloads extract one SRT/VTT in memory with size limits.

Required Supabase secret: `WYZIE_API_KEY`.
Optional secret: `SUBTITLE_FALLBACK_API_URL` — HTTPS URL of your hosted instance
of https://github.com/bipuldey19/Opensubtitles-Unofficial-API.
Its advertised public host failed DNS resolution during verification; fallback
remains inactive until a working instance is configured. No OpenSubtitles paid
API key, username, or password is needed.

Wyzie live verification: Spider-Man: Brand New Day (TMDB 969681) returned 13 English
tracks; one SRT download returned HTTP 200 with caption timing lines.
The `subtitles` function is deployed to Veil and `WYZIE_API_KEY` is configured.
Unauthenticated requests return HTTP 401. Authenticated in-app playback still
requires device verification. The optional unofficial API fallback is not active
until `SUBTITLE_FALLBACK_API_URL` points to a working instance.

Tests:
- `flutter test test/shared_subtitle_repository_test.dart test/subtitle_repository_test.dart test/native_player_test.dart`
- `deno test --allow-env supabase/functions/subtitles/index_test.ts`
