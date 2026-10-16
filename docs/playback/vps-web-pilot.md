# VPS custom web playback pilot

Date: 2026-10-15. Target: existing Vexellab VPS, separate pilot installation at
`/opt/veil-player-pilot`. No public service or Nginx route was deployed.

## Method

Playwright 1.63.0 and Chromium headless shell executed in transient systemd units:
dynamic unprivileged user, 600 MB memory limit, no swap allowance, 50% CPU quota,
120-second runtime limit, protected filesystem/home, private temporary directory,
and private-network access restrictions. Missing browser libraries were extracted
inside the pilot directory, not installed/upgraded system-wide.

Chromium's sandbox remained enabled. A temporary AppArmor profile allowed user
namespaces for the exact root-owned pilot executable. The profile was unloaded
and removed after testing; global user-namespace restrictions remain enabled.

The resolver captured HLS responses and required session headers in memory.
After closing that browser, a fresh browser played the captured stream using
HLS.js 1.6.13. Playwright request interception simulated a separate-origin proxy:
Node fetched resources, restored applicable headers, rewrote playlists and key
URIs, and supplied CORS headers. This tests the architecture, not a deployed
HTTP proxy or the Flutter web UI. Signed URLs/cookies were not persisted.

## Results

| Provider | Content | Result |
| --- | --- | --- |
| Player 1 / CineSrc | Interstellar, TMDB 157336 | Playback advanced to 5.009s; 1280×720; readyState 4; zero fatal HLS errors; 8 proxy requests, zero failures. |
| Player 1 / CineSrc | Spider-Man: Brand New Day, TMDB 969681 | Playback advanced to 5.018s; 1280×534; readyState 4; 11 initial proxy requests, zero failures. Seek to 45s resumed to 47.017s with seeking=false. |
| Player 2 / Vidsrc | Both titles above | No playlist captured during either 40-second wait. Page ended blank, no video elements. Cause not established. |

Player 1 successful playback runs peaked at 505 MB and 461.2 MB and consumed
11.535s and 12.025s CPU respectively. One earlier resolution-only run reached the
600 MB cap. Concurrency and memory need explicit limits on this shared 1-CPU VPS.
No remote-client network, Safari, TV episode, long-duration, expiry, or concurrent
user playback certification is implied by these movie samples.

## End state / next implementation

Transient probe units exited and were collected. Nginx, TileTribe and Chillara
remained active; both app health endpoints returned OK. Pilot browser, libraries
and scripts remain inert under `/opt/veil-player-pilot` for reuse. No persistent
browser worker, public endpoint, Firebase deployment, or Flutter behavior change.

Next: implement an authenticated, bounded resolver/session proxy and Flutter web
video adapter for Player 1. Player 2 needs separate resolution investigation;
do not silently substitute Player 1 when Player 2 is selected.

## Player 2 diagnostic follow-up

Eight bounded diagnostic variants ran against Interstellar (157336): untouched
Playwright baseline, traced provider callback, mobile-style UA/viewport with
tracing, original pilot behaviour, mobile-style settings without callback
instrumentation, raw CDP without Runtime enabled, desktop with the existing mobile
script filter, and mobile-style settings with that filter.

Confirmed first blocker: the mobile implementation already blocks
`disable-devtool.js` through `playbackBlockedScriptUrlFilters`; the initial VPS
pilot omitted this policy. Traces recorded detector **6 / Performance**, followed
by the provider callback navigating the main frame to `about:blank` around 3s.
The same warning/navigation occurred without callback instrumentation. The
provider's script explicitly pauses video, clears its source and redirects on
detection. This is a console timing heuristic, not proof of a specific IP ban.

The untouched baseline and raw-CDP control did not blank the main page in those
runs, but also did not resolve a stream. Thus the detection is environment/timing
sensitive; merely reaching the page is insufficient.

Matching the existing mobile script filter removed the blank-page behaviour and
allowed navigation through `vs_src.php` (HTTP 200) into
`stellarconductornexus.com/embed/player/movie/157336`, where a video element and
player controls appeared. Both desktop and mobile-style variants then failed
Cloudflare Turnstile with **600010**, twice per run, and produced no HLS response.
Cloudflare documents the 600* family as generic challenge failure. These tests do
not isolate whether IP reputation, browser characteristics, resource limits, or
another signal caused challenge rejection. No challenge-solving workaround was
attempted.

Conclusion: initial blank screen was a mobile/VPS policy mismatch; after matching
that policy, provider verification remains a separate blocker. Neither a CORS
change nor a Flutter widget change addresses the remaining resolution failure.
Use provider-supported access or a different explicitly selected web provider
before promising Player 2 support.

Diagnostics peaked at 346.4 MB RAM. All transient units stopped; the temporary
AppArmor profile was removed again, global restrictions stayed enabled, and
TileTribe/Chillara health checks remained OK. No app or Firebase deployment made.
