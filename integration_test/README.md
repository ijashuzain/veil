# Live playback audit

`playback_live_test.dart` runs the real app and its production mobile WebView on
an iOS simulator. It authenticates through the app login UI when no session is
present, checks the requested account and premium state, and launches real
movie/episode URLs through the normal playback launcher.

## Run

Requirements: Flutter, Node.js 22+, a booted iOS simulator, and a premium test
account. From the repository root, start the local bridge in one terminal:

```zsh
export VEIL_TEST_EMAIL='your-test-account-email'
read -rs 'VEIL_TEST_PASSWORD?Test account password: '
export VEIL_TEST_PASSWORD
node tool/playback_live_bridge.mjs
```

In another terminal:

```sh
flutter devices
flutter test integration_test/playback_live_test.dart -d <simulator-id> \
  --dart-define=PLAYBACK_RUN_LABEL=local-audit
```

Credentials travel through the loopback bridge at runtime. They are not Dart
defines, source constants, or evidence-file fields. Stop the bridge after the
run and unset its credential environment variables.

## Evidence and interpretation

The bridge writes JSON traces and simulator screenshots to
`build/playback-evidence/`. Set `VEIL_TEST_EVIDENCE_DIR` to choose another output
directory, and `VEIL_TEST_SIMULATOR_ID` to select the screenshot device.

Each case records navigation decisions, relevant resource responses, video
dimensions, ready/network state, buffered duration, playback errors, provider
text, and startup timing. URL queries and fragments are removed from traces.
A small HTTPS range probe can distinguish media bytes from upstream error pages.

Playback success requires a video longer than five minutes, nonzero width,
unpaused state, and at least three seconds of advancing playback. This excludes
short ad clips. Seeking is checked by playback advancing beyond 46 seconds after
a seek to 45 seconds. A poster-only provider gate is exercised using its Play
control; other players receive a play request after eight seconds if necessary.

Server 5 records native controller initialization, dimensions, playback progress,
and resolver disposal instead of browser video-element events. Use
`--dart-define=PLAYBACK_SERVER_FILTER=5` for its dedicated native matrix.
Server 6 selects Vidsrc independently. Use `PLAYBACK_SERVER_FILTER=5,6` to
compare the two selected providers. `PLAYBACK_CHECK_CONTROLS=true` additionally
checks auto-hide, pause spinner state, and opens track menus.
`PLAYBACK_NATIVE_PROVIDER=vidzee` (or `cinesrc`, `vidsrc`, `cinejoy`, `vidlink`)
overrides Server 5 only for isolated diagnostic adapter trials.

The test is an observational audit: completion does **not** assert that every
external server worked. Read each case's `playing`, `seekSucceeded`, and error
events. Live provider availability and timing can change between attempts.
First-frame measurements include any deliberate wait before the Play request;
they are not a pure decoder or network benchmark.

## Focused runs and controls

```sh
flutter test integration_test/playback_live_test.dart -d <simulator-id> \
  --dart-define=PLAYBACK_CASE_FILTER=fall-2,arcane-s2e3 \
  --dart-define=PLAYBACK_SERVER_FILTER=1,4 \
  --dart-define=PLAYBACK_RUN_LABEL=focused
```

Additional diagnostic defines:

- `PLAYBACK_WAIT_SECONDS`: startup observation limit; default `40`.
- `PLAYBACK_BRIDGE_URL`: bridge URL; default `http://127.0.0.1:18765`.
- `PLAYBACK_SAFARI_UA=true`: compare a Safari-branded user agent.
- `PLAYBACK_NO_CONTENT_BLOCKERS=true`: disable native content rules for a control.
- `PLAYBACK_BLOCK_ANTI_DEBUG=true`: isolate the vendored detector rule.
- `PLAYBACK_VIDLINK_PLAYER=default`: remove the forced JWPlayer query parameter;
  other values are passed as the provider's `player` parameter.

These controls are debug-only and do not change release settings. The local
bridge accepts no browser origins and probes only public HTTPS destinations.

Tests use the simulator's current network. They do not emulate different ISPs,
prove physical-device codec support, or inspect the user's desktop/browser
profile. After auditing, run `lib/main.dart` normally to replace the test-entry
build on the simulator.
