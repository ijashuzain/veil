## Why

The playback sheet currently offers three providers, and recent Server 1 work showed that provider availability can shift quickly. Adding VidLink as Server 4 gives Android and iOS users another documented TMDB-based embedded playback option without changing the existing Server 1, Server 2, or Server 3 flows.

## What Changes

- Add a fourth playback server option labeled Server 4 in the detail playback server sheet.
- Route Server 4 movie playback to VidLink movie embed URLs using the title's TMDB ID.
- Route Server 4 TV and series playback through the existing season/episode selection flow, then open the matching VidLink TV episode URL.
- Open Server 4 VidLink URLs through the existing embedded web player path on Android and iOS.
- Do not add VidLink anime playback in this change, because current content data does not include MyAnimeList IDs.
- Do not change Server 1 Vidsrc, Server 2 PlayIMDB/StreamIMDB, or Server 3 Cinesrc behavior.

## Capabilities

### New Capabilities
- `mobile-playback-server-four`: Mobile movie and series playback routing for a fourth VidLink-backed server on Android and iOS.

### Modified Capabilities
- None.

## Impact

- Affects playback URL generation in `lib/src/features/detail/utils/playback_entry_url.dart`.
- Affects the playback server sheet in `lib/src/features/detail/widgets/detail_playback_server_sheet.dart`.
- Affects Server 4 selection flow in `lib/src/features/detail/view/detail_view.dart`.
- Affects embedded mobile WebView navigation allowances in `lib/src/features/embeded_player/view/player_mobile.dart` if VidLink is loaded as a top-level page.
- Affects widget and URL-builder tests in `test/widget_test.dart`.
- No new package dependency is expected.
