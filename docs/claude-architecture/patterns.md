# Patterns

The "how": concrete, copy-paste-ready templates for every structural element in this architecture. Claude should treat the snippets in this file as authoritative starting points — modify the domain-specific names, but keep the shape.

---

## 1. Feature scaffold

Every feature lives at `lib/src/features/<feature>/` (or `lib/src/modules/<module>/features/<feature>/` in multi-module projects) with this folder shape:

```
<feature>/
├── models/
│   └── <model_name>/
│       ├── <model_name>.dart          # Freezed data class
│       ├── <model_name>.freezed.dart  # generated
│       └── <model_name>.g.dart        # generated (JSON)
├── repository/
│   ├── <feature>_repository.dart
│   └── <feature>_repository.g.dart    # generated (Riverpod)
├── view/
│   └── <screen>_view.dart
├── view_model/
│   └── <screen>_view_model/
│       ├── <screen>_view_model.dart
│       ├── <screen>_view_model.freezed.dart
│       └── <screen>_view_model.g.dart
└── widgets/                            # optional — feature-private widgets
    └── <widget>.dart
```

**Rules:**
- One screen → one `view_model/` folder → one state class + one `@riverpod class`.
- Nested models live in their own subfolders (`models/profile/profile.dart`) so generated files stay colocated.
- Feature-private widgets go in `widgets/`. If a widget is reused across ≥2 features, promote to `lib/src/shared/components/`.

---

## 2. View Model

Every view model is a Riverpod `@riverpod class` returning a Freezed state. State classes use the `Status` union for async outcomes.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:<app>/src/core/utils/status/status.dart';
import 'package:<app>/src/features/<feature>/repository/<feature>_repository.dart';

part '<screen>_view_model.g.dart';
part '<screen>_view_model.freezed.dart';

// 1. Form class (if the screen has input). One Freezed class per logical form.
@freezed
abstract class <Screen>Form with _$<Screen>Form {
  const <Screen>Form._();
  const factory <Screen>Form({
    @Default('') String fieldA,
    @Default('') String fieldB,
  }) = _<Screen>Form;

  factory <Screen>Form.fromJson(Map<String, dynamic> json) =>
      _$<Screen>FormFromJson(json);
}

// 2. View state. One Status per distinct async action.
@freezed
abstract class <Screen>ViewState with _$<Screen>ViewState {
  const <Screen>ViewState._();
  const factory <Screen>ViewState({
    @Default(<Screen>Form()) <Screen>Form form,
    @Default(Status.initial()) Status submitStatus,
    @Default(Status.initial()) Status loadStatus,
  }) = _<Screen>ViewState;
}

// 3. Notifier — business logic, NO widget references.
@riverpod
class <Screen>ViewModel extends _$<Screen>ViewModel {
  @override
  <Screen>ViewState build() => const <Screen>ViewState();

  // Field updaters — always via copyWith, never via direct assignment.
  void updateFieldA(String v) =>
      state = state.copyWith(form: state.form.copyWith(fieldA: v));

  // Validation — returns the error string (or null) so the view can pass it to FormField validators.
  String? validateFieldA(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationFieldARequired;
    return null;
  }

  // Async action — set loading → call repo → set success/failure.
  Future<void> submit() async {
    try {
      state = state.copyWith(submitStatus: const Status.loading());
      final result = await ref.read(<feature>RepositoryProvider).doThing(state.form);
      state = state.copyWith(submitStatus: Status.success(data: result));
    } catch (e) {
      state = state.copyWith(submitStatus: Status.failure(e.toString()));
    }
  }
}
```

**Conventions:**
- **One view model per screen.** Don't share a view model across two screens — share a repository or a cross-feature provider instead.
- **One Status field per distinct async action.** If a screen has "email login" + "google login" + "apple login", have three separate `Status` fields. Reason: independent loading spinners on the social buttons.
- **View models never touch `BuildContext`.** Validation messages take `AppLocalizations l10n` as a parameter so the view can inject `context.text`.
- **No navigation in view models.** Views react to Status changes via `ref.listenManual` (see View pattern).

---

## 3. Repository

Repositories are Riverpod-exposed classes that wrap `Api` + endpoints + `LocalStorage`. They never import `flutter/material.dart`.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:<app>/app/services/api_services/api_service.dart';
import 'package:<app>/app/services/local_storage_services/local_storage_services.dart';
import 'package:<app>/src/core/constants/endpoints.dart';
import 'package:<app>/src/features/<feature>/models/<model>/<model>.dart';

part '<feature>_repository.g.dart';

@riverpod
<Feature>Repository <feature>Repository(Ref ref) {
  return <Feature>Repository(api: ref.watch(apiProvider));
}

class <Feature>Repository {
  final Api api;
  <Feature>Repository({required this.api});

  Future<<Model>> getThing(int id) async {
    final response = await api.general.get(Endpoints.getThing(id));
    return <Model>.fromJson(response.data['data']);
  }

  Future<<Model>> createThing(<Form> form) async {
    final response = await api.general.post(
      Endpoints.createThing,
      data: form.toJson(),
    );
    return <Model>.fromJson(response.data['data']);
  }
}
```

**Rules:**
- **Pick the right Dio instance.** `api.profile` for authenticated user endpoints, `api.general` for public or generic authenticated endpoints. `api.tokenRefresh` is internal — never call from a repository.
- **Always unwrap `response.data['data']`.** Backend convention: envelope with a `data` key.
- **Repositories return domain models or void.** Never return `Response` or raw JSON.
- **Side-effects on success (e.g., persisting tokens) go here**, not in view models. See `auth_repository.dart:login()` for the canonical example.

---

## 4. View

Views are `ConsumerStatefulWidget` when they need `initState` (for `ref.listenManual` side-effects) or `ConsumerWidget` when they're purely reactive.

```dart
class <Screen>View extends ConsumerStatefulWidget {
  const <Screen>View({super.key});

  @override
  ConsumerState<<Screen>View> createState() => _<Screen>ViewState();
}

class _<Screen>ViewState extends ConsumerState<<Screen>View> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Side-effect subscriptions — one per Status field we care about.
      ref.listenManual(
        <screen>ViewModelProvider.select((s) => s.submitStatus),
        (previous, next) {
          if (previous == next) return;
          next.maybeWhen(
            success: (_) => const NextRoute().replace(context),
            failure: (msg) => PrimaryMessenger.showError(context, msg),
            orElse: () {},
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(<screen>ViewModelProvider);
    final vm = ref.read(<screen>ViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: ColorName.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.dp),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(32.dp),
              Text(context.text.screenTitle, style: TextStyle(fontSize: 30.sp, ...)),
              Gap(16.dp),
              PrimaryTextField(
                initialValue: state.form.fieldA,
                onChanged: vm.updateFieldA,
                validator: (v) => vm.validateFieldA(v, context.text),
              ),
              Gap(16.dp),
              PrimaryButton(
                text: context.text.submit,
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    vm.submit();
                  }
                },
                isLoading: state.submitStatus is StatusLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Rules:**
- **`ref.watch` in `build`, `ref.read(...notifier)` for actions, `ref.listenManual` in `initState` for side-effects.**
- **Wrap `ref.listenManual` calls in `addPostFrameCallback`** so they aren't scheduled before the first frame.
- **Guard every listener with `if (previous == next) return;`** — prevents duplicate fires when unrelated state fields change.
- **Navigation happens in the listener, not in the async action.** The async action sets `Status.success`; the listener navigates.
- **Loading UI is derived from `Status`**: `state.xStatus is StatusLoading`. Never track loading with a separate boolean.
- **Localization via `context.text.key`.** Validators take `context.text` and forward to the view model.

---

## 5. Models

Domain models are Freezed + JsonSerializable. Nested models live in their own folders.

```dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part '<model>.freezed.dart';
part '<model>.g.dart';

@freezed
abstract class <Model> with _$<Model> {
  const <Model>._();

  const factory <Model>({
    @Default(0) int id,
    @JsonKey(name: 'first_name') @Default("") String firstName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default([]) List<int> interests,
  }) = _<Model>;

  // Derived getters live ON the model, not in the view model.
  String get displayName => firstName.isEmpty ? '—' : firstName;

  factory <Model>.fromJson(Map<String, dynamic> json) => _$<Model>FromJson(json);
}
```

**Rules:**
- **snake_case JSON keys** use `@JsonKey(name: 'snake_case')`.
- **Every field has a default.** Non-null ones use `@Default(...)`, nullable ones omit the default and become `Type?`.
- **Derived data (computed getters)** belong on the model, not on the view state.
- **No business logic methods** on models — only derived getters, no `Future<>`.

---

## 6. The `Status` union

Single source of truth for async outcomes. Defined once at `lib/src/core/utils/status/status.dart`:

```dart
@freezed
abstract class Status with _$Status {
  const Status._();

  const factory Status.initial() = StatusInitial;
  const factory Status.loading() = StatusLoading;
  const factory Status.temporary() = StatusTemporary;   // mid-action intermediate state
  const factory Status.success({dynamic data}) = StatusSuccess;
  const factory Status.failure(String errorMessage) = StatusFailure;
  const factory Status.authFailure(String errorMessage) = StatusAuthFailure;

  dynamic get data => maybeWhen(success: (data) => data, orElse: () => null);
  String get errorMessage => maybeWhen(
        failure: (m) => m,
        authFailure: (m) => m,
        orElse: () => '',
      );
}
```

**Usage idioms:**
- Start: `state = state.copyWith(xStatus: const Status.loading());`
- Success (with payload): `Status.success(data: authResponse)`
- Success (no payload): `const Status.success()`
- Failure: `Status.failure(e.toString())`
- Auth failure (for special handling like re-login redirect): `Status.authFailure('...')`
- Pattern-match in views: `next.maybeWhen(success: (d) => ..., failure: (m) => ..., orElse: () {})`
- Loading check: `state.xStatus is StatusLoading`

**Never add new Status variants per-feature.** If a feature needs special states beyond the five, add them on the feature's view state class, not on `Status`.

---

## 7. Routing (typed go_router)

Every route is a `GoRouteData` class with the `@TypedGoRoute<T>` annotation.

### `route_paths.dart`

```dart
abstract class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const memberDetail = '/member-detail';
  // ... group by feature with comments
}
```

### `app_router.dart`

```dart
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
// feature imports ...

part 'app_router.g.dart';

@TypedGoRoute<SplashRoute>(path: RoutePaths.splash)
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashView();
}

// Route with required parameters (goes in the URL)
@TypedGoRoute<MemberDetailRoute>(path: RoutePaths.memberDetail)
class MemberDetailRoute extends GoRouteData with $MemberDetailRoute {
  final String heroTag;
  final int memberId;

  MemberDetailRoute({required this.heroTag, required this.memberId});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MemberDetailView(heroTag: heroTag, memberId: memberId);
}

// Route with an $extra (complex object, not URL-serializable)
@TypedGoRoute<EventManageRoute>(path: RoutePaths.eventManage)
class EventManageRoute extends GoRouteData with $EventManageRoute {
  final Event? $extra;
  const EventManageRoute({this.$extra});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EventManageView(initialEvent: $extra);
}

// Route with a custom transition
@TypedGoRoute<LandingRoute>(path: RoutePaths.landing)
class LandingRoute extends GoRouteData with $LandingRoute {
  const LandingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LandingView();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const LandingView(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 800),
    );
  }
}
```

### `router_provider.dart`

Owns the `GoRouter`, fans route changes out to Clarity + UxCam + Sentry, and defines the error fallback:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    observers: [SentryService.instance.navigatorObserver],
    routes: $appRoutes,
    errorBuilder: (context, state) { /* redirect logic */ },
  );
  // telemetry listener...
  return router;
});
```

### Navigation from views

```dart
const LoginRoute().go(context);                           // replace stack
const LoginRoute().push(context);                         // push on top
const LoginRoute().replace(context);                      // replace current
MemberDetailRoute(heroTag: 'm-1', memberId: 42).go(context);
```

**Never use `context.go('/login')`** — it defeats the type-safety of `go_router_builder`.

---

## 8. Networking (`Api`)

`Api` exposes three Dio instances. Repositories pick one.

```dart
class Api {
  late final Dio tokenRefresh;    // For /refresh/ only — no interceptors that would recurse.
  late final Dio profile;         // Authenticated user endpoints (/users/me/, etc).
  late final Dio general;         // Everything else.

  // Each Dio has: BaseOptions(Enviro.apiUrl, 30s timeout, json headers)
  // + appropriate interceptors:
  //   - profile: ProfileApiInterceptor + ErrorApiInterceptor(refreshDio: tokenRefresh)
  //   - general: GeneralApiInterceptor + ErrorApiInterceptor(refreshDio: tokenRefresh)
  //   - tokenRefresh: no interceptors
}
```

**Interceptor responsibilities:**

- `GeneralApiInterceptor` — logs responses (`ApiLogger`).
- `ProfileApiInterceptor` — attaches `Authorization: Bearer <access_token>` from `LocalStorage`.
- `ErrorApiInterceptor` — the big one:
  - Logs errors
  - On 401 with `Authorization` header: enqueue the request, acquire a refresh lock, POST `/refresh/` with `refresh_token` from `LocalStorage`, on success retry all queued requests, on failure reject all with `UnauthorizedException`.
  - Exponential backoff (200ms × 2^n) up to 3 attempts, with a 15s cooldown.
  - Maps HTTP status codes to typed exceptions (`BadRequestException`, `ForbiddenException`, `NotFoundException`, `ConflictException`, `TooLargeException`, `TooManyRequestException`, `InternalServerErrorException`, `ServiceUnavailableException`, `NoInternetConnectionException`, `DeadlineExceededException`, `RequestCancelledException`, `BadCertificateException`, `UnknownErrorException`, `ResponseFromServerException`).

**When catching errors in view models or repositories**, catch the typed exception (`on ForbiddenException`, `on UnauthorizedException`) for specific handling, then a bare `catch (e)` for everything else.

---

## 9. Endpoints

All URLs live in `lib/src/core/constants/endpoints.dart` as static members on `class Endpoints`. Parameterized endpoints are static methods:

```dart
class Endpoints {
  static String baseUrl = Enviro.apiUrl;

  // Authentication
  static String login = "$baseUrl/users/login/";
  static String signup = "$baseUrl/users/sign_in/";

  // Parameterized
  static String getEventDetail(int id) => "$baseUrl/events/$id/";
  static String getUserDetail(int id) => "$baseUrl/users/$id/";

  // Query-bearing
  static String getMyEvents(String type) => "$baseUrl/participate_event/my_events/?type=$type";
}
```

Group by feature with `///` comments. Never construct URLs inline in repositories.

---

## 10. LocalStorage

Thin static wrapper around `SharedPreferences`, initialized once in `main.dart` via `LocalStorage.init()`.

```dart
await LocalStorage.setString('access_token', token);
final token = LocalStorage.getString('access_token');
await LocalStorage.remove('access_token');
await LocalStorage.clear();   // logout
```

**Storage keys** are string literals; when a key is used in ≥2 places, promote to a `static const String` on `LocalStorage` (see `expiredPlanReminderShownKey`).

For structured data, use `setMap` / `getMap` — NEVER stringify JSON manually.

---

## 11. Localization

### ARB source

`lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, etc. Keys are `camelCase`. Add a placeholder block for parameterized strings:

```json
{
  "greetUser": "Hello, {name}!",
  "@greetUser": {
    "placeholders": {
      "name": { "type": "String" }
    }
  }
}
```

### Usage in widgets

```dart
Text(context.text.greetUser('Alice'))
// or
Text(context.l10n.greetUser('Alice'))   // alias; both work
```

Validators take `AppLocalizations l10n` as a parameter:

```dart
// in view model
String? validateEmail(String? v, AppLocalizations l10n) {
  if (v == null || v.isEmpty) return l10n.validationEmailRequired;
  return null;
}

// in view
validator: (v) => viewModel.validateEmail(v, context.text),
```

**No hardcoded English strings** in any `.dart` file under `lib/src/features/` or `lib/src/shared/`. Extract to ARB.

---

## 12. Shared components

Widgets reused across ≥2 features live in `lib/src/shared/components/`, one widget per file. Conventions:

- **Name the file after the widget** in `snake_case` (`primary_button.dart` → `PrimaryButton`).
- **Take all variables via constructor**, not via inherited widgets.
- **Use `ColorName` for colors, `FontFamily.manrope` for font, `.dp/.sp/.w` for sizing.**
- **Expose an `isLoading` or similar state hook** when the component represents an async affordance.

Example minimal shape:

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  // ...

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    // ...
  });

  @override
  Widget build(BuildContext context) { /* ... */ }
}
```

---

## 13. Observability hooks in view models

Every authenticated side-effect (login, signup, profile change, purchase) follows this sequence in the view model:

```dart
// After successful API call:
ref.read(currentProfileProvider.notifier).setProfile(profile);
await CrashlyticsService.instance.syncUserContext(profile: profile, authSource: 'email');
await SentryService.instance.syncUserContext(profile: profile, authSource: 'email');
await ClarityService.instance.syncUserContext(profile: profile, authSource: 'email');
await UxCamService.instance.syncUserContext(profile: profile, authSource: 'email');
await UxCamService.instance.trackEvent('login_email_success', properties: {...});
await SentryService.instance.addBreadcrumb(category: 'auth', message: 'login_email_success', data: {...});
ClarityService.instance.trackEvent('login_email_success');
await NotificationService().requestPermissionsIfNeeded();
await FcmRegistrationService.instance.registerCurrentToken();
```

On logout, `AuthRepository.logout()` calls the matching `clearUserContext()` on all four telemetry services.

---

## 14. Context extensions

`lib/src/core/extensions/context_extensions.dart` exposes:

- `context.text` / `context.l10n` — `AppLocalizations`
- `context.theme` — `ThemeData`
- `context.colorScheme`, `context.textTheme`
- `context.isRTL`, `context.currentLocale`, `context.currentLanguageCode`
- `context.isDark`, `context.isLight`

Add new context extensions only for cross-cutting accessors (theme, locale, screen size). Feature-specific context helpers are an anti-pattern.

---

## 15. Messaging / toasts

Use `PrimaryMessenger` (in `lib/src/shared/utils/primary_messenger.dart`) for all inline feedback:

```dart
PrimaryMessenger.showError(context, 'Something went wrong');
PrimaryMessenger.showSuccess(context, 'Saved');
```

Do not call `ScaffoldMessenger.of(context).showSnackBar(...)` directly — it bypasses the standard styling.

---

## 16. Responsive sizing

All dimensions, font sizes, and widths come from `the_responsive_builder`:

- `.dp` for logical pixels (widths, heights, padding, radii)
- `.sp` for font sizes
- `.w` for width percentages (e.g., `100.w` = full width)

Baseline is `390×844` (iPhone 13/14/15 portrait). Set once in `main.dart`.

```dart
Padding(padding: EdgeInsets.symmetric(horizontal: 24.dp), ...)
Text('Hi', style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w800))
SizedBox(width: 100.w, ...)
```

---

## 17. Generated assets, colors, fonts

- **Assets**: `Assets.icons.logo`, `Assets.images.placeholder` — auto-generated from `pubspec.yaml` asset entries by `flutter_gen`.
- **Colors**: `ColorName.primary`, `ColorName.background` — auto-generated from `assets/color/colors.xml`.
- **Fonts**: `FontFamily.manrope` — auto-generated from `pubspec.yaml` font entries.

Never hardcode `'assets/icons/logo.svg'` strings or hex colors in widget code. Add to the source then regenerate.
