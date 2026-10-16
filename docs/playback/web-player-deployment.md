# Player 1 custom web playback

## Deployment

- Flutter site: https://veil-12353.web.app
- Resolver/proxy: https://api.vexellab.com/veil-player/
- Health: `/veil-player/health`
- VPS code: `/opt/veil-player`; service: `veil-player.service`.
- Environment: `/etc/veil-player/backend.env` (root-readable).
- Nginx snippet: `/etc/nginx/snippets/veil-player.conf`, included in the existing
  API HTTPS server block. The prior site file was backed up before adding it.
- Nginx talks to `/run/veil-player/service.sock`; no public Node port.

Player 1 uses our Flutter player UI and HTML video. HLS.js 1.6.13 handles HLS in
browsers that lack native HLS support; Safari uses native HLS when advertised.
Player 2 is explicitly unavailable on web. Mobile provider selection is unchanged.
The sizing, subtitle language picker/timing controls and playback history use the
existing shared widgets. Browser brightness uses a visual dimming overlay.
The web toolbar includes browser fullscreen for the whole Flutter surface, keeping
custom controls/captions visible. Fullscreen state follows browser exit events and
is released when the player closes. Shared mute/unmute restores the previous
volume and retains the setting across episode/quality changes. Mobile sources
include mute/unmute; browser fullscreen is web-only.
Web quality is automatic ABR; manual rendition selection is not exposed yet.

## Backend protocol and limits

`POST /resolve` takes `provider: cinesrc`, `type: movie|tv`, numeric `id`, and TV
`season`/`episode`. It validates the Supabase bearer session and the caller's
`user_profiles.user_id` premium flag before starting resolution.

Response contains an opaque session URL; provider URLs, cookies and auth headers
remain server-side. Rewritten playlists include opaque URLs for child playlists,
segments and encryption keys. Streaming supports range requests. All upstream
HTTPS destinations undergo public-IP validation and use a pinned DNS answer;
redirects are checked again and cross-origin credentials are stripped.

- One resolver browser, at most three outstanding resolve requests.
- Three-entry, 30-second source cache.
- Per-minute resolve limits: 20/IP, 6/user.
- At most 30 sessions, eight concurrent media requests/session, 5,000 resource
  URLs/session. Idle expiry: 30 minutes; absolute expiry: six hours.
- Close/switch sends session DELETE; idle expiry handles disconnected tabs.
- Browser launch/navigation timeouts and a 60-second browser lifetime watchdog.
- Service limits: 700 MB RAM, no swap, 60% CPU, 160 tasks. Unprivileged dynamic
  user, protected filesystem/home, private temp directory and private-IP blocks.
- Chromium sandbox is enabled using an AppArmor profile scoped to its exact
  root-owned executable. Browser/runtime libraries are reused from
  `/opt/veil-player-pilot`; do not delete that directory while this service uses it.
- Session routes are excluded from Nginx access logs. API logs never include
  signed stream URLs, bearer tokens or cookies.

Required environment: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `PUBLIC_URL`,
`ALLOWED_ORIGINS`. Frontend override: `WEB_PLAYER_BASE_URL`.
Allowed browser origins are the project's web.app and firebaseapp.com domains,
`https://veil.is-live.dev`, and `https://veil.vexellab.com`. Add future hosting
domains explicitly. Both custom domains were added after a live CORS failure.

## Verification

- Five Node tests cover private destinations, playlist/key rewriting, content
  validation, resolver queue/cache, HTTP auth/premium/CORS and expired sessions.
- 25 focused Flutter tests passed for player UI, selection/history and subtitles.
- Chrome smoke build of `tool/web_player_smoke.dart` exercised the real web
  platform adapter: advancing HLS playback, Fit control, language selection,
  downloaded tag-free captions and seek/resume.
  Follow-up checks also passed mute/unmute, fullscreen entry/exit and external
  fullscreen exit synchronization; 18 updated native player tests passed.
- Production resolver code on VPS resolved Interstellar and Breaking Bad S1E1;
  master, variant and media requests returned HTTP 200 after browser disposal.
- Public deployment health 200, missing auth 401, Firebase preflight 204, invalid
  session 410. Fresh Chrome loaded the deployed sign-in screen and HLS.js without
  page errors. TileTribe and Chillara remained healthy.

Authenticated end-to-end playback against a real premium user session, Safari,
long-duration expiry and concurrency/load testing remain unverified. No test
account or user session was created to impersonate an existing user.

## Commands

Backend tests: `npm test` in `server/web-player`.
Browser smoke: build `tool/web_player_smoke.dart` into a temporary directory,
then `node smoke-web.mjs <build-directory>` from `server/web-player`.
Web release: `flutter build web --release`.
Firebase: `firebase deploy --only hosting --project veil-12353`.
VPS restart after syncing reviewed code: `systemctl restart veil-player`.

The `deploy/activate.sh` script validates backend tests and Nginx syntax; on Nginx
validation failure it restores the prior site config. It does not alter any other
application service. Fresh hosts must provision the pinned sandboxed Chromium
runtime first; the script deliberately does not upgrade shared server packages.
