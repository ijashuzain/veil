## Why

Server 1 currently depends on `cine.su` direct HLS URLs that now return 404 for known movie and TV playback IDs, leaving the first playback option broken. Replacing Server 1 with Vidsrc restores the primary Android/iOS playback path using the provider's documented embed API.

## What Changes

- Replace Server 1's `cine.su` direct HLS playback flow with Vidsrc embed URLs.
- Keep the existing Server 1 movie behavior as one tap from the server sheet.
- Keep the existing Server 1 TV behavior that asks for season and episode before playback.
- Generate Vidsrc URLs from TMDB IDs when available, with IMDb IDs as a fallback.
- Open Vidsrc through the embedded web player on Android and iOS instead of the direct HLS player.
- Stop using the direct stream availability checker for Server 1, because Vidsrc is an iframe embed provider rather than a direct playlist provider.
- Exclude Flutter web desktop and web mobile behavior from this change.

## Capabilities

### New Capabilities
- `mobile-playback-servers`: Mobile movie and series playback server routing, including Server 1 Vidsrc embed playback on Android and iOS.

### Modified Capabilities
- None.

## Impact

- Affects Server 1 playback URL generation in `lib/src/features/detail/utils/playback_entry_url.dart`.
- Affects Server 1 selection flow in `lib/src/features/detail/view/detail_view.dart`.
- Affects widget and URL-builder tests in `test/widget_test.dart`.
- Removes Server 1 reliance on the Supabase HLS proxy for `cine.su` URLs, but leaves the proxy and other servers unchanged.
- No new Flutter package dependency is expected.
