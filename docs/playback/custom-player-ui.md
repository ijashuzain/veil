# Custom native player UI

## Visible behavior

- Launch sheet shows only **Player 1** (persisted server `five`, CineSrc native)
  and **Player 2** (persisted server `six`, Vidsrc native). Old server identifiers
  and history entries remain compatible; their buttons are hidden.
- Seekbar is custom drawn, with a 32-point touch area and bottom padding inside
  the control surface.
- CC/quality buttons open a shared right-side dark panel with Subtitles/Quality
  tabs. It covers the originating controls and uses the same overlay color.
- Subtitle codes are expanded to full language names. Descriptive labels such
  as English (SDH) are retained.
- Episodes open an inline panel, not a dialog. Its compact custom season picker
  uses TMDB seasons; episodes use names and still images when available.
  Missing names become `Episode N`. If season details fail, known episode counts
  supply numbered rows with a retry action; unknown seasons are not fabricated.
- Titles show the series, `S01 - E02`, and available episode name, without a
  server number.
- Double-tap the left/right half to seek backward/forward ten seconds.
- Vertical swipes on the left adjust screen brightness; right-side swipes adjust
  this player's audio volume. Brightness is restored on exit.

## Native fullscreen

The fullscreen action pauses Veil playback and passes the current stream URL,
request headers, position, play intent, and volume to a platform screen:

- iOS: `AVPlayerViewController` system playback UI.
- Android: in-app native Media3 `PlayerView` activity. Android does not expose a
  universal AVPlayerViewController equivalent.

On dismissal, the updated position/play state returns to Veil. The native screen
uses the same resolved source; it does not re-run extraction. Flutter-rendered
sidecar captions are not transferred to the system UI; the source's built-in
tracks remain subject to platform support.

## Verification

- Focused widget checks cover inline tabs, language names, season/episode
  selection, gestures, brightness restoration, and native handoff arguments.
- Simulator `player_panels_test.dart` passed using Flutter's public sample video
  and real Silo TMDB metadata. Screenshots capture track, episode, and season
  panels. This UI fixture is not a new Silo stream-provider playback claim.
- Native iOS simulator and Android debug builds compiled.
- Web debug build compiled; 42 focused tests and 24 legacy/picker regression
  checks passed. The normal simulator app was rebuilt, installed, and launched.
- Analysis reports no errors and three existing async-return warnings outside
  this feature.
- Real-device system-player interactions and physical brightness/volume behavior
  still require device validation. No desktop UI permissions were bypassed.
