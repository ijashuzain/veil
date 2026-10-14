# Native controls and separate providers

## User-facing changes

- Server 5: CineSrc native. Server 6: Vidsrc native.
- No automatic cross-provider fallback. Retry stays on the selected provider;
  the explicit embedded-player action opens the same provider.
- Existing Servers 1–4 retain their playback paths.
- Controls toggle on video tap and hide after three seconds while playing.
  Paused playback, scrubbing, and open menus keep controls accessible.
- Compact controls, paused-state-aware buffering, serialized seeks, and
  accumulated ten-second skips. Old seek completions cannot override pause.
- Quality menu uses exposed HLS renditions; Auto retains the master. Switching
  quality preserves position without starting a new provider-resolution job.
- Subtitle menu supports exposed VTT/SRT sidecars and on-demand CineSrc subtitle
  discovery. Segmented HLS subtitle playlists are not yet rendered by this UI.
- Series have a top-right episode picker; switching retains the native server
  and uses the newly selected season/episode identity.
- Short-lived in-memory source cache avoids repeated resolution for immediate
  reopen. Failed native initialization invalidates that provider's entry.

## Live provider evaluation

iPhone 17 Pro simulator, iOS 26.5, current network; October 2026:

| Adapter | Trial | Result |
| --- | --- | --- |
| CineSrc | Interstellar, Arcane S2E3 | Native playback and seek passed |
| Vidsrc | Interstellar | Native playback and seek passed; three qualities exposed |
| Vidzee | Interstellar | Valid candidate resolved, native initialization failed |
| Vidzee | Arcane S2E3 | No valid HLS candidate |
| CineJoy | Interstellar | Sample native attempt failed |
| VidLink | Arcane S2E3 | Sample native attempt failed |

Vidzee's first candidate sometimes returned HTTP 200 with malformed/non-HLS
content. The adapter validates playlist bodies instead of trusting status/MIME.
Failed adapters remain in the diagnostic harness, not native server choices.

These are bounded feasibility trials, not provider uptime guarantees. The final
combined native UI trial stopped at authentication before playback, so live
subtitle synchronization/quality switching/episode switching is not certified.
Widget tests cover control behavior, parsing, selected-server routing, episode
identity, and caption loading. Cold startup still depends on provider page and
CDN latency; no universal latency reduction is claimed.

## Repository assessment

- StreamGrabber: MIT; its provider adapters are a future HTTP-resolution lead,
  not yet imported or runtime-tested in Veil.
- VortX: useful native-control architecture reference, GPL-3.0, private engine
  dependency. Not a drop-in Flutter resolver.
- Streambert: GPL-3.0 Electron app; selected extraction references, not a native
  mobile replacement.
- Watchlo: movie/TV iframe frontend; no explicit license grant found.
- CinePro core: PolyForm Noncommercial; backend reference with maintenance/
  rewrite limitations, not integrated.
- heyitswit/vidsrc-bypass: archived, last pushed October 2024, no explicit
  license file; historical VidLink assumptions are not current compatibility.

Detailed repository notes are under `research_notes/Veil streaming source evaluation/`.
