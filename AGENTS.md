# AGENTS.md

## Project Shape
- Root is a Flutter app named `veil` with Dart SDK `^3.11.0`; the real entrypoint is `lib/main.dart`.
- `lib/main.dart` boot order matters: `LocalStorage.init()` runs before `SupabaseService.init()`, and a persisted Supabase session controls the initial route.
- Main app code is flat feature-first: `lib/src/features/<feature>/`, shared UI/data in `lib/src/shared/`, core config/router/theme in `lib/src/core/`, infrastructure in `lib/app/services/`.
- `lib/src/features/embeded_player/` is misspelled in the current imports; do not rename it in incidental edits.
- `app-store-screenshots/` is a separate Next.js screenshot editor, not part of the Flutter build.
- `docs/claude-architecture/` is a generic architecture pack. Keep only rules verified in this repo; its Firebase/Enviro references are stale here.

## Commands
- Install Flutter deps: `flutter pub get`.
- Run the app: `flutter run`. Development Supabase config is hardcoded, so no env file is required.
- Regenerate Riverpod/Freezed/JSON/GoRouter/flutter_gen outputs: `dart run build_runner build --delete-conflicting-outputs`.
- Regenerate ARB localizations after `lib/l10n/*.arb` changes: `flutter gen-l10n`.
- Analyze: `flutter analyze`.
- Full tests: `flutter test`.
- Single test file: `flutter test test/tmdb_repository_test.dart`.
- Focused test: `flutter test test/widget_test.dart --plain-name "detail shows floating play only for premium users"`.
- Web release build: `flutter build web --release`; Firebase Hosting serves `build/web`.
- Firebase deploy target: `firebase deploy --only hosting --project veil-12353`.
- Android release signing reads `android/key.properties`; without it, release builds fall back to debug signing.
- No `.github/workflows` or pre-commit config was found; local commands are the source of truth.

## Generated Code
- Generated files are committed. Do not hand-edit `*.g.dart`, `*.freezed.dart`, `lib/gen/assets.gen.dart`, or `lib/src/l10n/app_localizations*.dart`.
- Re-run build_runner after changing any `@riverpod`, `@freezed`, `@JsonSerializable`, `@TypedGoRoute`, or asset-gen input.
- Routing is typed in `lib/src/core/router/app_router.dart`; the reset-password route is manually inserted before `...$appRoutes` to handle Supabase recovery links.
- The ARB scaffold exists, but `VeilApp` currently wires only Flutter global localization delegates; do not assume `AppLocalizations` is active without wiring it.

## Runtime Config And Data
- Runtime constants live in `lib/src/core/config/app_environment.dart`; `.env` and `.env.*` are gitignored and not loaded by current app code.
- Dart defines supported by code: `TMDB_READ_ACCESS_TOKEN`, `TMDB_API_KEY`, `TMDB_BASE_URL`, `TMDB_IMAGE_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `PASSWORD_RESET_REDIRECT_URL`.
- By default, TMDB requests go through Supabase edge-function proxies derived from `SUPABASE_URL`; direct TMDB mode needs a TMDB token or API key.
- `SupabaseService.client` can be null if Supabase is unconfigured or init fails; social/auth repositories and tests rely on local SharedPreferences fallback paths.
- `tester@vexellab.com` is a special account in `TmdbRepository` that hides Disney/Pixar content; keep this behavior covered by tests.
- Premium playback affordances depend on `user_profiles.is_premium` in Supabase.

## Backend And Deploy Notes
- Supabase migrations are under `supabase/migrations/`; `docs/supabase/*.sql` is reference material, not the migration source of truth.
- Supabase edge functions live in `supabase/functions/tmdb`, `tmdb-image`, and `proxy`.
- The HLS `proxy` function currently comments out its host allowlist, so do not assume `HLS_PROXY_ALLOWED_HOSTS` is enforced.
- `firebase.json` configures SPA rewrites and no-store headers for core web artifacts.
- `shorebird.yaml` is bundled as an asset, `auto_update` is false, and web uses `NoopShorebirdUpdateService`.

## App Store Screenshots Tool
- Work in `app-store-screenshots/`; use `bun install`, `bun dev`, and `bun run build` from that directory.
- The Next app has only `dev`, `build`, and `start` scripts; no lint/test script is defined.
- The editor autosaves canonical state to `app-store-screenshots/app-store-screenshots.json` and uploaded images to `app-store-screenshots/public/screenshots/uploaded/<hash>.*`.
- `next.config.mjs` has `reactStrictMode: false`; TypeScript is strict and uses `@/*` for `src/*`.
