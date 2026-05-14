# Veil Architecture Migration

## Inventory

- Screen count: 8 navigable surfaces (`onboarding`, `home`, `detail`, `player`, `search`, `alerts`, `profile`, bottom-tab shell).
- Current state management: local widget state only for tab/category/search field state; no API business state yet.
- Current networking: no live networking yet; TMDB endpoint constants and Dio service scaffold added for the next phase.
- Current routing: migrated from in-memory app state to typed `go_router` routes.
- Current localization: ARB scaffold added; full string extraction is still pending.
- Current folder structure: migrated to flat feature-first `lib/src/features/*/view` plus `lib/src/shared` and `lib/app/services`.
- Module decision: flat. The app has one product area and does not meet the multi-module threshold.

## Phase Status

- Phase 0 inventory: complete.
- Phase 1 dependency alignment: mostly complete. `riverpod_lint` and `custom_lint` currently conflict with the resolved Riverpod/Freezed/cache package set and are deferred.
- Phase 2 folder restructure: complete for the design MVP.
- Phase 3 networking: service and endpoint scaffolds are present; TMDB repositories are next.
- Phase 4 Riverpod/Freezed states: `Status` union is present; feature view models are next when TMDB data becomes asynchronous.
- Phase 5 typed routing: complete for the current flow.
- Phase 6 i18n/responsive: responsive app wrapper and ARB scaffold are present; full hardcoded string extraction and `.dp/.sp` conversion are next.
