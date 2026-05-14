# Refactoring an Existing Flutter Project Into This Architecture

This guide is for taking a legacy Flutter project — any state management, any folder layout, any networking approach — and migrating it to the feature-first architecture described in `architecture.md` and `patterns.md`.

**The golden rule: migrate in phases, ship each phase, never do a big-bang rewrite.** Every phase below leaves the app in a working, shippable state.

Expect 2–6 weeks for a medium-sized app (20–50 screens), depending on team size and feature velocity during the migration.

---

## Phase 0 — Inventory and decisions (1 day)

Before any code changes, produce a written inventory.

### Inventory checklist

1. **Count screens.** Rough number of navigable screens (not widgets). This calibrates effort.
2. **List dependencies** from `pubspec.yaml`. Mark each:
   - ✅ Already in the target stack (keep)
   - ⚠️ Equivalent in target stack (plan to replace)
   - ❓ Unique to this project (keep or replace?)
3. **Identify the existing state management.** Is it setState, Provider, Bloc, GetX, plain ChangeNotifier, or a mix? Note per-feature.
4. **Identify the existing networking.** Raw http, Dio, some client library? One file or scattered?
5. **Identify the existing routing.** `Navigator.push` by name, `Navigator.pushNamed`, existing `go_router` without typed routes? Note.
6. **Identify the existing localization.** ARB? Hardcoded? Missing entirely?
7. **Identify the existing folder structure.** Is it feature-first, layer-first (models/views/controllers at root), or mixed?

### Decisions to make upfront

- **Multi-module or flat?** If the app has clear product verticals with ≥3 features each AND separate ownership, plan multi-module from the start. Otherwise flat. See `multi-module.md`.
- **Do auth and API refresh already work?** If yes, plan to preserve the current backend contract during migration. If no, plan auth rework in Phase 3 alongside networking.
- **Backwards compat window?** How long do you need to support the legacy patterns in parallel? Answer informs how aggressively you delete old code.

### Output of Phase 0

A short markdown doc (`MIGRATION.md` in the repo) listing:
- Screen count
- Dependencies to add/remove/replace
- Current-state fingerprint per concern (state, net, routing, i18n)
- Flat vs. multi-module decision
- Phase sequencing (usually 1→7 below, but you may skip/reorder)

---

## Phase 1 — Dependency alignment (0.5 day)

Bring `pubspec.yaml` to parity with the target stack. This doesn't require any behavior changes yet — just making the tools available.

### Add

Add every package listed in `architecture.md §Tech stack` that you don't already have:

```yaml
dependencies:
  flutter_riverpod: ^3.0.0        # or latest compatible
  riverpod_annotation: ^3.0.0
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  go_router: ^16.0.0
  dio: ^5.9.0
  shared_preferences: ^2.3.0
  the_responsive_builder: ^1.0.0
  cached_network_image: ^3.4.0
  flutter_svg: ^2.0.0
  gap: ^3.0.0
  # ... plus Firebase, Sentry, etc. as needed

dev_dependencies:
  build_runner: ^2.7.0
  riverpod_generator: ^3.0.0
  riverpod_lint: ^3.0.0
  custom_lint: ^0.8.0
  freezed: ^3.0.0
  json_serializable: ^6.9.0
  go_router_builder: ^4.0.0
  flutter_gen_runner: ^5.0.0
  flutter_lints: ^5.0.0
```

### Configure

- Copy `analysis_options.yaml` to include `package:flutter_lints/flutter.yaml`.
- Add `flutter_gen` block for colors (`assets/color/colors.xml`).
- Add `assets/images/`, `assets/icons/`, `.env`, `.env-development` entries under `flutter.assets` if you'll use them.
- Add `l10n.yaml` pointing `arb-dir: lib/l10n` → `output-dir: lib/src/l10n`.

### Verify

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run   # should still boot the existing app
```

**Gate:** old app still builds and runs. Ship Phase 1.

---

## Phase 2 — Folder restructure (1–2 days)

Move existing files into the target skeleton. **Do not rewrite logic yet** — only move files and fix imports.

### Target skeleton

Create empty folders:

```
lib/
├── app/services/              # for later phases
├── gen/                       # for later phases (will be generated)
├── l10n/                      # ARB source
└── src/
    ├── core/
    │   ├── config/
    │   ├── constants/
    │   ├── extensions/
    │   ├── providers/
    │   ├── router/
    │   ├── services/
    │   └── utils/
    ├── features/
    ├── shared/
    │   ├── components/
    │   ├── enums/
    │   ├── models/
    │   └── utils/
    └── l10n/
```

### Move pattern

For each existing screen/feature:

1. Create `lib/src/features/<feature>/` with `models/`, `view/`, `view_model/`, `repository/` subfolders.
2. Move the existing screen file → `view/<screen>_view.dart`. If it's named `LoginScreen`, either rename class to `LoginView` now or plan a rename pass at the end.
3. Move its models → `models/<model>/<model>.dart`. Do NOT convert to Freezed yet (Phase 4).
4. Move any "controller" / "bloc" / "provider" logic → `view_model/<screen>_view_model/<screen>_view_model.dart`. Keep current state management in place.
5. Move any networking code for this feature → `repository/<feature>_repository.dart`. Keep current transport in place.

**Use IDE's "move file" operation** so imports update automatically. Commit after each feature moves cleanly.

### Reusable widgets

Anything reused across ≥2 features → `lib/src/shared/components/`.

### Verify

`flutter run` after each feature moves. Tests still pass. No behavior change is expected in this phase — only file locations.

**Gate:** app runs identically to before, but files are in the target skeleton. Ship Phase 2.

---

## Phase 3 — Networking (`Api` wrapper + interceptors) (2–3 days)

Replace whatever networking currently exists with the standard `Api` wrapper.

### Steps

1. Copy `lib/app/services/api_services/` from a reference project (or scaffold from `patterns.md §Networking`):
   - `api_service.dart`
   - `exceptions/dio_exceptions.dart`
   - `interceptors/error_api_interceptor.dart`
   - `interceptors/general_api_interceptor.dart`
   - `interceptors/profile_api_interceptor.dart`
   - `utils/api_logger.dart`
2. Copy `lib/app/services/local_storage_services/local_storage_services.dart`.
3. In `main.dart`, add `await LocalStorage.init();` before any code that reads tokens.
4. Create `lib/src/core/constants/endpoints.dart` and migrate every API URL in the codebase to a named endpoint. Do this with a find-all pass.
5. For each existing repository:
   - Replace the transport line (was: `http.get(...)` or `dio.get(...)` with bare config) with `api.general.get(Endpoints.x)` or `api.profile.get(...)`.
   - Keep the method signatures identical so view models don't change yet.

### Token refresh migration

If the legacy app already has a token refresh mechanism, retire it in favor of `ErrorApiInterceptor`. Map existing 401 handling to the interceptor's queue-and-retry model. See `error_api_interceptor.dart:_handleTokenRefresh` for the contract.

### Verify

- Network requests work identically.
- 401 responses trigger one refresh request (not a storm).
- Queued 401s retry correctly after refresh.
- All typed exceptions (`BadRequestException`, `NotFoundException`, etc.) surface where expected.

**Gate:** Ship Phase 3.

---

## Phase 4 — Models + `Status` union + Riverpod codegen (3–5 days)

Introduce Freezed, json_serializable, and Riverpod code generation. Biggest behavioral phase — do it incrementally feature-by-feature.

### Status union (app-wide, first)

Create `lib/src/core/utils/status/status.dart` exactly as in `patterns.md §The Status union`. Run `build_runner build`. Commit.

### Per-feature migration

Pick one small feature (ideally a read-only list screen) as pilot. Migrate:

1. **Models to Freezed + JsonSerializable.**
   - Add `@freezed abstract class ... with _$...` skeleton.
   - Add `@JsonKey(name: 'snake_case')` where needed.
   - Run `build_runner`.
   - Replace manual `fromJson` / `copyWith` callers with the generated versions. Delete old model fields.
2. **View model to `@riverpod class`.**
   - Define a Freezed view state class holding form + `Status` fields.
   - Convert the old controller/bloc into the `@riverpod class` pattern from `patterns.md §View Model`.
   - Wrap every async call in `try/catch` + `state.copyWith(xStatus: Status...)`.
   - Run `build_runner`.
3. **View updates.**
   - Swap the old widget base (e.g., `StatefulWidget` + `Provider.of`) for `ConsumerStatefulWidget` + `ref.watch` / `ref.read` / `ref.listenManual`.
   - Move side effects (navigation, toasts) into `ref.listenManual` blocks.
   - Replace loading booleans with `state.xStatus is StatusLoading`.

### Order of feature migration

- Start with feature that has **no dependencies on other feature state** (e.g., a news list, a static settings page).
- Migrate **auth last** — it has the most side effects (telemetry, token storage, navigation chain).

### Verify per feature

- Screen renders.
- Loading/error/success states transition correctly.
- Form validation fires in both directions.

**Gate:** All features migrated. The old state management library can be removed from `pubspec.yaml`. Ship Phase 4.

---

## Phase 5 — Routing (typed go_router) (2 days)

Replace whatever navigation exists with `go_router` + typed routes.

### Steps

1. Create `lib/src/core/router/route_paths.dart` listing every path.
2. Create `lib/src/core/router/app_router.dart` with `@TypedGoRoute` class per route (see `patterns.md §Routing`).
3. Create `lib/src/core/providers/router_provider.dart` owning the `GoRouter` instance.
4. Swap `MaterialApp` → `MaterialApp.router` in `MyApp`. Wire `routerConfig: ref.watch(routerProvider)`.
5. Run `build_runner` to generate `$appRoutes` and per-route `$Route` mixins.
6. In each view, replace navigation calls:
   - `Navigator.pushNamed(context, '/login')` → `const LoginRoute().go(context)` (or `.push`, `.replace`)
   - `Navigator.push(context, MaterialPageRoute(builder: (_) => FooView()))` → `const FooRoute().push(context)`
7. Wire telemetry observers (`SentryService.instance.navigatorObserver`) on the `GoRouter`.

### Error fallback

The `errorBuilder` should redirect to splash for unrecognized routes while logged in, and log to Sentry. See `router_provider.dart` in the reference project for the canonical snippet.

### Verify

- Deep links resolve.
- Back button behaves correctly across the flow.
- Route-change telemetry fires (Clarity + UxCam + Sentry).

**Gate:** Ship Phase 5. The old routing scheme (if different) can be removed.

---

## Phase 6 — i18n + shared components + responsive sizing (2–3 days)

Polish the UI layer.

### Localization

1. Create `lib/l10n/app_en.arb` with every user-facing string in the app. Use grep/find to identify candidates (`Text('...')`, snackbar messages, validators).
2. Run `flutter gen-l10n` — produces `lib/src/l10n/app_localizations.dart`.
3. Add `context_extensions.dart` with `context.text` and `context.l10n` accessors.
4. Replace every hardcoded string with `context.text.key`. Validators receive `AppLocalizations l10n` as a parameter.
5. Update `MaterialApp.router` with `localizationsDelegates` and `supportedLocales`.

### Shared components

Refactor inline custom widgets into `lib/src/shared/components/`:

- `PrimaryButton` — with `isLoading`, variants
- `PrimaryTextField` + `EmailTextfield` + `PasswordTextfield`
- `MainAppBar` / `PrimaryAppBar`
- Any custom picker/sheet/modal used in ≥2 places

### Responsive sizing

1. Add `the_responsive_builder` wrapper in `MyApp` with baseline `390×844`.
2. Find-and-replace:
   - Raw pixel padding/margin → `.dp`
   - `TextStyle(fontSize: 14)` → `TextStyle(fontSize: 14.sp)`
   - Raw width/height that should scale with screen → `.w` / `.h`

Don't convert every number blindly. Tiny decorative values (1, 2, 4) that don't need to scale can stay raw.

### Generated assets and colors

1. Move asset PNGs/SVGs to `assets/images/`, `assets/icons/`. Add to `pubspec.yaml`.
2. Move colors to `assets/color/colors.xml`. Configure `flutter_gen` in `pubspec.yaml`.
3. Run `dart run build_runner build`. Use `Assets.icons.x`, `ColorName.y`, `FontFamily.z` in code.

**Gate:** Ship Phase 6.

---

## Phase 7 — Observability (1 day)

Add Crashlytics, Sentry, UxCam, Clarity. Wire them into auth flows.

### Steps

1. Copy `lib/src/core/services/crashlytics_service.dart`, `sentry_service.dart`, `clarity_service.dart`, `uxcam_service.dart` from reference project.
2. Initialize each in `main.dart` in the order shown in `architecture.md §Boot sequence`.
3. Wrap the app in `ClarityService.instance.wrapApp(app: ...)` and `SentryService.instance.start(app: ...)`.
4. Add `CrashlyticsProviderObserver` and `SentryProviderObserver` to `ProviderScope`.
5. Add navigation observers to the router.
6. In every auth view model, add the `syncUserContext` / `trackEvent` / `addBreadcrumb` sequence after each successful action. See `patterns.md §Observability hooks`.
7. In `AuthRepository.logout()`, call `clearUserContext()` on all four services before clearing local storage.

**Gate:** Ship Phase 7.

---

## Phase 8 — (Optional) Multi-module split

Only run this phase if Phase 0 decided multi-module. Follow `multi-module.md §Migrating flat → modular`.

---

## Cleanup pass (0.5 day)

After Phase 7 (or 8):

- Delete old state management package from `pubspec.yaml`.
- Delete any legacy routing/navigation helpers.
- Delete any legacy networking code paths.
- Delete any unused shared utilities.
- Run `flutter analyze` and fix all lints.
- Run full test suite.
- Update `README.md` to describe the new architecture.
- Add/update `doc/claude-architecture/LOCAL.md` with project-specific notes.

---

## Common pitfalls

- **Trying to go Freezed + Riverpod + go_router in one phase.** Too many moving parts. Sequence them.
- **Migrating auth first.** Auth has the most side effects and is where token handling meets observability meets navigation. Do it last.
- **Skipping codegen step in `pubspec.lock`.** If `build_runner` doesn't run in CI, generated files will drift. Add a CI check.
- **Keeping dual state management "temporarily".** It never becomes temporary. Migrate fully per feature before moving to the next.
- **Shared components explosion.** If `shared/components/` grows to 100+ widgets, some belong in `shared/components/<category>/` subfolders or should be demoted to feature-private.
- **Endpoint drift.** If devs keep adding URLs inline in repositories, the `Endpoints` file rots. PR review must block this.
