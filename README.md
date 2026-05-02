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

## Development

Regenerate generated code after changing Riverpod, Freezed, or GoRouter files:

```bash
dart run build_runner build --delete-conflicting-outputs
```
# veil
