# Continue Watching and safe playback area

- Video and all Flutter controls now share a SafeArea. Gesture coordinates use
  its actual dimensions, keeping landscape notches outside the video bounds.
- Episodes and CC/quality use identical right-panel bounds down to the action
  overlay. Episodes no longer display thumbnails; absent/generic titles show
  one `Episode N` label.
- Main close control is smaller. Resolution text is always `Resolving stream…`
  and its indicator is 20 points wide with a 1.5-point stroke.

## History behavior

Continue Watching includes only Player 1 and Player 2 (persisted IDs `five` and
`six`). Entries are identified by normalized movie/TV type plus TMDB ID, not
server, season, or episode. Existing records are normalized on read: legacy
servers are excluded, and only the newest native record for each title survives.
Changing provider or episode replaces the same content entry.

Playback position is saved in milliseconds every approximately 15 seconds, on
pause/background, and on close. Relaunching from Continue Watching seeks to that
position and retains the selected player/episode. Completed playback is removed.
Old records without a position begin at zero. Writes are serialized to avoid
lost records during concurrent checkpoints, removal, or launch updates.

The phone rail sizes its cards from available width so three complete entries
fit without horizontal scrolling. Additional entries remain scrollable. Removal
uses the content key, so older duplicate episodes cannot reappear afterward.

Verification covers stored-data normalization, native-only history, saved-position
round trips, concurrent writes, three-card phone layout, home relaunch/removal,
notch insets, and duplicate-free episode labels.
