# Live playback audit — 13 October 2026

## Environment and method

- iPhone 17 Pro simulator, iOS 26.5; current Mac network.
- Actual app login succeeded using the supplied account; premium access verified.
- Production mobile WebView, navigation policy, and playback URL builder used.
- Four movies and three specific series episodes tested on all four servers.
- Each full matrix contains 28 attempts: one baseline and one post-fix matrix.
- Additional controlled attempts isolated the provider's anti-devtools script,
  Safari user-agent branding, and removal of the forced player query parameter.
- Native video dimensions, advancing playback, buffering, source responses,
  media errors, and a seek to 45 seconds were observed. Screenshots were captured
  from the simulator framebuffer.
- Isolated Chrome comparisons confirmed the same Server 4 media failure and
  Server 1's inspection-triggered page wipe. This was an instrumented browser,
  not a claim that ordinary Safari must fail identically.

Login credentials are not stored in source or the report. The account was not
modified; direct playback launches avoid filling playback history with test data.

## Matrix

`Pass` means visible, advancing movie/episode video and successful seeking.

| Title | Server 1 baseline → fixed | Server 2 baseline → fixed | Server 3 baseline → fixed | Server 4 baseline → fixed |
| --- | --- | --- | --- | --- |
| Fall 2: Deadpoint | Fail → Pass | Pass → Pass | Pass → Pass | Fail → Fail |
| Interstellar | Fail → Pass | Pass → Pass | Pass → Pass | Unavailable → Unavailable |
| Dune: Part Two | Fail → Pass | Pass → Pass | Pass → Pass | Fail → Pass |
| Avatar | Fail → Pass | Pass → Pass | Pass → Pass | Fail → Fail |
| Breaking Bad S1E1 | Fail → Pass | Pass → Pass | Pass → Pass | Fail → Fail |
| Game of Thrones S2E3 | Fail → Pass | Pass → Pass | Pass → Pass | Unavailable → Unavailable |
| Arcane S2E3 | Fail → Pass | Pass → Pass | Pass → Pass | Pass → Fail |

Server 4's changes between attempts are important. A working adaptive source can
be replaced by a denied progressive source for the same title. These outcomes
must not be represented as a stable app-only codec or rendering problem.

## Root causes

### Server 1: provider detector aborts embedded playback

The outer and inner provider pages vendor `disable-devtool.js`. Their detector
calls `location.replace('about:blank')` and relays `VS_DEVTOOLS` to parent frames.
In the baseline, a valid outer page and stream-resolution API response were
followed by a top-level blank navigation; no playable video was created.

Isolating that exact script allowed the poster and Play gate to load. Exercising
the Play gate then produced real video and working seeking for both initial
control movies. After the compatibility rule was applied to the app, all seven
titles passed on Server 1.

Domain-only filtering missed this because the detector is served from the
provider's own domain. Player bootstrap/decryption scripts remain allowed.

### Server 4: upstream source denial and changing availability

For Fall 2, movie data resolved successfully. The selected media endpoint on
`noon.mooncase.online` returned HTTP 403 and HTML instead of video bytes. Avatar
also returned the provider's nonstandard `427 Forbidden` response. JWPlayer then
reported `224003`, which corresponds to `MEDIA_ERR_SRC_NOT_SUPPORTED`.

The error code alone does not establish a missing codec: HTML/error responses
are also unsupported media. Isolated Chrome showed the same Fall 2 failure with
media requests blocked by its opaque-response checks.

Interstellar and Game of Thrones S2E3 returned the provider's unavailable-content
UI. Dune 2 failed in the baseline and played in the post-fix attempt. Arcane
initially played a DASH source with successful manifest/segment responses, then
later resolved to a denied MP4 source. This is source-selection/availability
variability beyond the app's rendering layer.

Safari-branded user-agent controls did not improve the failing titles and also
failed for Arcane in that trial. The app retains its real platform user agent.
Removing the forced JWPlayer parameter was also tested on Fall 2, Dune 2, and
Arcane; none played in that control. There is no demonstrated benefit from
changing the provider's player selection globally.

### Startup watchdog conflated a Play gate with buffering

Server 1 initially renders a poster and Play control; its video element is only
created after interaction. Starting a video-download watchdog when entering the
page caused a false stalled-playback warning while the user was waiting at that
gate. The app now distinguishes waiting for Play from an attempted video load.

## Applied changes

- Block the exact vendored detector filename before execution, including on
  first-party provider hosts. Reject unsolicited top-level `about:blank` wipes.
- Recognize the provider's Play gate and start the watchdog on playback attempts.
- Capture large-player media failures before JWPlayer clears the error object;
  allow a brief provider recovery window and surface persistent failure sooner.
- Recognize the observed unavailable-content message instead of waiting only for
  the generic timeout.
- Clear error UI when media recovers. Ignore aborted/invalid media notifications
  and small hidden video elements.
- Add targeted blocking for ad/identity domains actually observed in the traces:
  `adexchangerapid.com`, `connatix.com`, `id5-sync.com`, `crwdcntrl.net`,
  `dtscout.com`, and `onaudience.com`.
- Add a reusable, credential-free-source live test harness and local evidence
  bridge. Debug instrumentation is inert in release builds.

## Further optimization priorities

1. **Provider health and source-aware fallback.** Offer another server promptly
   when a source returns a denial or unavailable-content result; use measured
   reliability rather than repeatedly retrying the same denied URL.
2. **Stable adaptive sources.** Prefer supported HLS/DASH variants when the
   provider offers a documented selection mechanism. Server 4 demonstrated why
   a denied progressive URL should not be treated as a decoder-tuning problem.
3. **Native playback for stable source APIs.** A supported, durable stream API
   would allow ExoPlayer/AVPlayer playback without provider-page scripts, trackers,
   and nested player initialization. A brittle scraper is not a durable contract.
4. **Separate time-to-interactive, play request, and first decoded frame.** The
   matrix includes an eight-second delayed play request where needed. Aggregate
   startup figures must account for that deliberate wait and provider gating.
5. **Physical-device/network validation.** Repeat the same harness on affected
   phones and real networks. Simulator success does not certify hardware codec,
   Android composition, or cellular/CDN behavior.

Rust is not indicated by these observations. The demonstrated failures are
provider JavaScript, source responses, playback-state handling, and native
WebView behavior—not a measured Dart CPU bottleneck.

## Timing and verification

In the post-fix matrix, first decoded frames appeared at approximately:

- Server 1: 15.8–19.1 seconds from route entry, including the deliberate
  eight-second wait before clicking its Play gate.
- Server 2: 6.3–12.8 seconds from route entry.
- Server 3: 7.7–9.7 seconds from route entry.
- Server 4: Dune 2 produced a first frame at 5.4 seconds in its working attempt.

These are live observations on one network, not controlled performance claims.
Provider caches, source selection, and deliberate interaction delays affect them.

- 67 recorded simulator playback attempts: 56 matrix attempts plus 11 controls.
- 41 focused unit/widget playback checks passed.
- Analysis reported no errors and only three existing async-return warnings in
  ad services and the social repository.
- The normal `lib/main.dart` simulator app built successfully and was installed
  and launched after auditing. Temporary browser and credential-bridge processes
  were stopped.
- The reusable bridge passed checks for its fixture list, browser-origin
  rejection, and private-destination rejection.
- Live screenshots verify actual video frames and progress, not only page-load
  callbacks or poster images.

## Side finding

The iOS AdMob SDK reported that no UMP consent forms are configured for its app
ID. This is separate from external provider ads and should be checked in the
AdMob account configuration; it did not explain the movie-source failures.

## Reproduction

See `integration_test/README.md`. JSON traces and screenshots from this audit are
under the local temporary `veil-playback-evidence` directory. Future runs write
to `build/playback-evidence/` by default.

The harness is observational: a completed integration-test process is not the
same as every provider passing. Use per-case playback and seeking evidence.
