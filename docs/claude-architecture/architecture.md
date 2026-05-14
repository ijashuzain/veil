# Architecture

The "what": layers, folder layout, boot sequence, and the tech stack that makes the patterns in `patterns.md` possible.

---

## Layering model

Four concentric layers. Dependencies point inward only.

```
┌─────────────────────────────────────────────────────┐
│  Views (lib/src/features/*/view, widgets/)          │   ← UI, no business logic
├─────────────────────────────────────────────────────┤
│  View Models (lib/src/features/*/view_model/)       │   ← Riverpod notifiers + Freezed state
├─────────────────────────────────────────────────────┤
│  Repositories (lib/src/features/*/repository/)      │   ← Transport-agnostic data access
├─────────────────────────────────────────────────────┤
│  Infrastructure (lib/app/services/, lib/src/core/)  │   ← Dio, LocalStorage, Firebase, 3rd party SDKs
└─────────────────────────────────────────────────────┘
```

- A **view** knows only its view model.
- A **view model** knows its repository and possibly other providers — never Dio, never SharedPreferences directly.
- A **repository** knows `api` + `LocalStorage` + endpoints — never a widget, never navigation.
- **Core services** (Crashlytics, Sentry, UxCam, Clarity, Notifications, Deep links) are singletons initialized in `main.dart` and called from view models for side effects.

---

## Folder layout

```
<project>/
├── lib/
│   ├── main.dart                      # App entry + service bootstrapping
│   ├── firebase_options.dart          # FlutterFire generated
│   ├── app/
│   │   └── services/
│   │       ├── api_services/          # Dio wrapper, interceptors, exceptions
│   │       │   ├── api_service.dart
│   │       │   ├── config/
│   │       │   ├── exceptions/        # Typed DioException subclasses
│   │       │   ├── interceptors/      # error, general, profile, auth-refresh
│   │       │   └── utils/             # logger
│   │       └── local_storage_services/
│   │           └── local_storage_services.dart   # SharedPreferences wrapper
│   ├── gen/                            # Generated code: assets, colors, env, fonts
│   │   ├── assets.gen.dart
│   │   ├── colors.gen.dart
│   │   ├── enviro.gen.dart
│   │   └── fonts.gen.dart
│   ├── l10n/                           # ARB source files (app_en.arb, app_fr.arb, ...)
│   └── src/
│       ├── core/
│       │   ├── config/                 # app_environment.dart
│       │   ├── constants/              # endpoints.dart, other app constants
│       │   ├── extensions/             # context_extensions.dart (.text, .theme)
│       │   ├── firebase/               # firebase_auth_service.dart
│       │   ├── providers/              # router_provider, locale_provider
│       │   ├── router/                 # app_router.dart, route_paths.dart
│       │   ├── services/               # Crashlytics, Sentry, UxCam, Clarity,
│       │   │                           #   Notifications, Deep links, RevenueCat,
│       │   │                           #   Locale, FCM, ImagePicker, Place
│       │   └── utils/
│       │       ├── cache/              # CustomCacheManager
│       │       └── status/             # Status union (Freezed)
│       ├── features/                   # Feature-first modules (flat variant)
│       │   └── <feature>/
│       │       ├── models/
│       │       ├── repository/
│       │       ├── view/
│       │       ├── view_model/
│       │       └── widgets/            # optional
│       ├── shared/
│       │   ├── components/             # Reusable widgets (buttons, textfields, app bars)
│       │   ├── enums/
│       │   ├── models/                 # Cross-feature models (pagination, filters)
│       │   └── utils/                  # PrimaryMessenger, etc.
│       └── l10n/                       # Generated localization dart
│           └── app_localizations.dart
├── assets/
│   ├── color/colors.xml                # Source for flutter_gen colors
│   ├── fonts/
│   ├── icons/
│   └── images/
├── test/
├── analysis_options.yaml
├── l10n.yaml                           # ARB → dart generation config
├── pubspec.yaml
├── .env, .env-development              # Loaded by enviro / flutter_dotenv
└── firebase.json
```

For the **multi-module variant**, see `multi-module.md`. The short version: replace `lib/src/features/` with `lib/src/modules/<module>/features/` and move module-specific `core/` + `shared/` inside each module.

---

## Boot sequence (`main.dart`)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([...]);

  // 1. Storage + environment
  await LocalStorage.init();
  await Enviro.setEnvironment(appEnvironment);

  // 2. Firebase + crash reporting
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashlyticsService.instance.initialize();

  // 3. Notifications / platform services
  await NotificationService().initialize();
  await RevenueCatService().initRevenueCat();
  await DeepLinkService.instance.initialize();

  // 4. Analytics / session recording
  await ClarityService.instance.initialize();
  await UxCamService.instance.initialize();
  await SentryService.instance.initialize();

  // 5. Run inside Sentry + Clarity + ProviderScope
  await SentryService.instance.start(
    app: ClarityService.instance.wrapApp(
      app: SafeArea(
        child: const ProviderScope(
          observers: [CrashlyticsProviderObserver(), SentryProviderObserver()],
          child: MyApp(),
        ),
      ),
    ),
  );
}
```

The **order is load-bearing**: storage before env, Firebase before crash reporting, notifications/analytics before the app runs. When adding a new global service, add it to the correct phase.

---

## `MyApp` widget

`MyApp` is a `ConsumerWidget` (not stateful). It only reads three providers:

1. `routerProvider` → `GoRouter` (owns app navigation)
2. `localeProvider` → active `Locale`
3. `supportedLocalesProvider` → list of locales

It wraps `MaterialApp.router` in `TheResponsiveBuilder` with a fixed baseline (390×844). Localization delegates include `AppLocalizations.delegate` + `CroppyLocalizations.delegate` + the three Flutter globals.

---

## Tech stack (authoritative)

| Concern | Package(s) | Notes |
|---|---|---|
| State management | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint` | Code generation **required**. `@riverpod` class pattern only. |
| Data classes | `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable` | For models AND view-model states. |
| Routing | `go_router`, `go_router_builder` | Typed routes via `@TypedGoRoute`. |
| HTTP | `dio`, `http` (limited use) | Multi-Dio wrapper in `app/services/api_services/`. |
| Storage | `shared_preferences` | Via `LocalStorage` static wrapper. |
| Localization | `flutter_localizations`, ARB | `context.text.key` accessor. |
| Responsive UI | `the_responsive_builder` | `.dp`, `.sp`, `.w` units. |
| Asset codegen | `flutter_gen_runner` | `Assets.`, `ColorName.`, `FontFamily.`. |
| Environment | `enviro`, `flutter_dotenv` | `.env` bundled as asset. |
| Firebase | `firebase_core`, `firebase_auth`, `firebase_messaging`, `firebase_crashlytics` | |
| Social auth | `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth` | Routed through `FirebaseAuthService`. |
| Analytics / RUM | `sentry_flutter`, `clarity_flutter`, `flutter_uxcam` | All four get `syncUserContext` calls on login/logout. |
| Monetization | `purchases_flutter` | RevenueCat. |
| Deep links | `flutter_ulink_sdk` | ULink. |
| Notifications | `awesome_notifications`, `firebase_messaging` | FCM token registered after login. |
| Media | `image_picker`, `croppy`, `video_player`, `just_audio`, `audio_waveforms`, `cached_network_image`, `flutter_svg` | |

When adding a package: pick from this list if it solves the problem. Only introduce new packages when nothing here fits.

---

## Code generation

Every change to annotated files requires:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generates:
- `*.freezed.dart` — Freezed unions and data classes
- `*.g.dart` — Riverpod providers, JSON ser/de, typed routes

For assets/colors/env/fonts re-gen:
```bash
dart run build_runner build
# or: flutter pub run flutter_gen
```

CI should run `build_runner` in check mode (`--delete-conflicting-outputs` + diff) to catch missing regen.

---

## Environment & config

- `lib/src/core/config/app_environment.dart` exposes `appEnvironment` (const `EnviroEnvironment`).
- `.env` / `.env-development` / `.env-staging` are shipped as **assets** and loaded by `enviro`.
- `Enviro.apiUrl` (and other env keys) come from the generated `enviro.gen.dart`.
- **Never** hardcode base URLs or keys. Always go through `Enviro.x`.

---

## Observability contract

Every authenticated flow (login, signup, profile updates, important actions) must:

1. Call `CrashlyticsService.instance.syncUserContext(profile: ..., authSource: ...)`
2. Call `SentryService.instance.syncUserContext(...)`
3. Call `ClarityService.instance.syncUserContext(...)`
4. Call `UxCamService.instance.syncUserContext(...)`
5. Emit a tracked event (`UxCamService.instance.trackEvent`, `ClarityService.instance.trackEvent`, Sentry breadcrumb)

On logout, the matching `clearUserContext()` on each service is called from the repository's `logout()`.

Route changes are automatically tracked via the `router_provider` listener that fans out to Clarity + UxCam + Sentry.
