# Veil

Veil is a Flutter streaming discovery app with TMDB-backed movie/TV data and a
Supabase-backed Letterboxd-style social layer.

## Run

The development build is hardcoded with:

- TMDB API key
- Supabase project URL
- Supabase publishable key

So no environment setup is needed for development:

```bash
flutter run
```

Those values live in `lib/src/core/config/app_environment.dart`.

## Supabase

The app is connected to the Supabase project `Veil`
(`verlsbmdqggejpfmvzue`) by default. The `film_entries` table and RLS policies
have already been applied through the Supabase MCP. User entitlement rows live
in `user_profiles`; set `is_premium` to `true` for a user to show the floating
Play action on movie and series detail pages.

The SQL file at `docs/supabase/veil_social_schema.sql` is kept only as a local
reference for recreating the schema later.

## Authentication Flow

Veil uses Supabase for app-owned identity and all user-specific social data.
TMDB is used only as the catalog data provider for movies, TV, images, videos,
credits, genres, and discovery/search results. User actions such as diary logs,
reviews, likes, favorites, ratings, and watchlist items are stored in Veil's
Supabase-backed social layer.

## Later Environment Migration

When you want to remove hardcoded development keys, `AppEnvironment` already
supports these runtime defines:

```bash
flutter run \
  --dart-define=TMDB_READ_ACCESS_TOKEN=your_tmdb_read_access_token \
  --dart-define=TMDB_API_KEY=your_tmdb_api_key \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_publishable_or_anon_key
```

## Shorebird Mobile Releases

Veil uses Shorebird automatic background updates on Android and iOS. Patches
download without blocking launch and apply after the next process restart. Web
deployments remain separate and continue through Firebase Hosting.

Verify the authenticated account, app identity, and local configuration:

```bash
shorebird account whoami
shorebird account apps
shorebird releases list
shorebird doctor
```

The first Shorebird-enabled store baseline is `1.0.4+9`. Validate each platform
without registering a remote release:

```bash
shorebird release \
  --platforms=android \
  --flutter-version=3.41.1 \
  --build-name=1.0.4 \
  --build-number=9 \
  --dry-run

shorebird release \
  --platforms=ios \
  --flutter-version=3.41.1 \
  --build-name=1.0.4 \
  --build-number=9 \
  --no-codesign \
  --dry-run
```

After signing is validated, create the release artifacts and submit its AAB and
IPA to Google Play and App Store Connect:

```bash
shorebird release \
  --platforms=android,ios \
  --flutter-version=3.41.1 \
  --build-name=1.0.4 \
  --build-number=9 \
  --export-method=app-store
```

Before App Store submission, replace the default iOS launch image placeholder.
If an unsigned Shorebird archive is distributed manually through Xcode, uncheck
**Manage Version and Build Number** so Xcode does not change `1.0.4+9`; patches
will not match a store build whose version was rewritten.

Users can receive patches only after installing these Shorebird-built store
binaries. Test every patch on `staging` before promoting it:

```bash
shorebird patch \
  --platforms=android,ios \
  --release-version=1.0.4+9 \
  --track=staging

shorebird preview \
  --platform=android \
  --release-version=1.0.4+9 \
  --track=staging

shorebird preview \
  --platform=ios \
  --release-version=1.0.4+9 \
  --track=staging

shorebird patches list --release-version=1.0.4+9
shorebird patches promote --release-version=1.0.4+9 --patch-number=1
```

Use the Shorebird console to roll back a bad stable patch. Do not use
`--allow-native-diffs` or `--allow-asset-diffs` to ship native SDK, manifest,
plist, CocoaPods, Gradle, or asset changes; publish a new Shorebird release and
store build instead. Release and patch commands must use identical Dart defines.

## Code Generation

Regenerate generated code after changing Riverpod, Freezed, or GoRouter files:

```bash
dart run build_runner build --delete-conflicting-outputs
```
# veil
