# Checklists — Copy-Paste Runbooks

Opinionated, step-by-step runbooks for the five most common structural tasks. Every step is concrete. The skill executes these verbatim; humans can follow them manually.

Paths below assume the **flat (single-module) variant**. For multi-module, substitute:
`lib/src/features/<feature>/` → `lib/src/modules/<module>/features/<feature>/`.

---

## 1. Adding a new feature

**Inputs needed:** feature name in snake_case (e.g., `bookmark`), screen list (e.g., `list`, `detail`), data model shape.

### Steps

1. **Create folder structure:**
   ```
   lib/src/features/<feature>/
   ├── models/
   │   └── <model>/<model>.dart
   ├── repository/
   │   └── <feature>_repository.dart
   ├── view/
   │   ├── <screen1>_view.dart
   │   └── <screen2>_view.dart
   ├── view_model/
   │   ├── <screen1>_view_model/<screen1>_view_model.dart
   │   └── <screen2>_view_model/<screen2>_view_model.dart
   └── widgets/              # only if feature-private widgets exist
   ```

2. **Write each model** using the Freezed template in `patterns.md §Models`.

3. **Write the repository** using the template in `patterns.md §Repository`. Add needed endpoints to `lib/src/core/constants/endpoints.dart` under a feature-group comment.

4. **Write each view model** using the template in `patterns.md §View Model`. One `@riverpod class` per screen. One `Status` field per distinct async action.

5. **Write each view** using the template in `patterns.md §View`. Use `ref.listenManual` for side effects.

6. **Add routes** — one `@TypedGoRoute` class per view in `lib/src/core/router/app_router.dart`. Add paths to `route_paths.dart`.

7. **Add user-facing strings** to `lib/l10n/app_en.arb` (and other locales). Keys: `<feature>_<purpose>` (e.g., `bookmark_listTitle`).

8. **Run code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

9. **Verify:**
   - `flutter analyze` passes.
   - Feature compiles.
   - Routes navigate correctly.
   - Loading/error/success transitions render.

10. **(Optional) Navigate to the feature** from an existing screen using `<FeatureScreen>Route().go(context)`.

---

## 2. Adding a new module (multi-module variant only)

**Inputs needed:** module name in snake_case, URL prefix (e.g., `/shop`, `/pay`), list of features the module will contain.

### Steps

1. **Create folder structure:**
   ```
   lib/src/modules/<module>/
   ├── core/
   │   └── constants/
   │       └── <module>_endpoints.dart
   ├── features/             # empty; features added individually via checklist #1
   ├── shared/
   │   ├── components/
   │   ├── enums/
   │   └── models/
   ├── router/
   │   ├── <module>_routes.dart
   │   └── <module>_route_paths.dart
   └── <module>_module.dart
   ```

2. **Define URL prefix** in `<module>_route_paths.dart`:
   ```dart
   abstract class <Module>RoutePaths {
     static const _prefix = '/<prefix>';
     // paths go here as they're added
   }
   ```

3. **Define module endpoints** in `<module>/core/constants/<module>_endpoints.dart`:
   ```dart
   class <Module>Endpoints {
     static String baseUrl = Enviro.apiUrl;
     // endpoints go here as they're added
   }
   ```

4. **Write the public surface file** `<module>_module.dart`:
   ```dart
   library <module>_module;

   export 'router/<module>_routes.dart';
   export 'router/<module>_route_paths.dart';
   // Add exports only as other modules genuinely need them.
   ```

5. **Import the module** from `lib/src/core/router/app_router.dart`:
   ```dart
   import 'package:<app>/src/modules/<module>/<module>_module.dart';
   ```
   (This ensures `go_router_builder` discovers the module's routes.)

6. **Decide what moves into the module** vs. stays app-level:
   - Feature-specific widgets → `<module>/shared/components/`
   - Cross-module widgets → keep in `lib/src/shared/components/`
   - Auth/profile flows → typically app-level (`lib/src/features/` or an `account` module)

7. **Run code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

8. **Add module to `LOCAL.md`** — document owner, scope, and any deviations.

9. **Add features** to the module using checklist #1 (substituting `lib/src/modules/<module>/features/` for `lib/src/features/`).

---

## 3. Adding a new endpoint to an existing repository

1. **Add the URL** to `lib/src/core/constants/endpoints.dart` (or `<module>/core/constants/<module>_endpoints.dart`). Parameterize with a static method if the URL has path segments:
   ```dart
   static String getThing(int id) => "$baseUrl/things/$id/";
   ```

2. **Add the method** to the repository class. Pick the right Dio instance (`api.profile` for authenticated, `api.general` otherwise). Unwrap `response.data['data']`. Return a domain model.

3. **If the response adds a new field**, update the relevant Freezed model:
   - Add `@JsonKey(name: 'snake_case') @Default(...)` field.
   - Run `dart run build_runner build --delete-conflicting-outputs`.

4. **If the method can fail with a specific status code**, catch the typed exception in the view model (e.g., `on ForbiddenException`, `on UnauthorizedException`).

5. **Run `flutter analyze`** and verify compilation.

---

## 4. Adding a new route to an existing feature

1. **Add the path constant** to `lib/src/core/router/route_paths.dart` (or `<module>_route_paths.dart`):
   ```dart
   static const bookmarkDetail = '/bookmark-detail';
   ```

2. **Add the `@TypedGoRoute` class** to `lib/src/core/router/app_router.dart` (or `<module>_routes.dart`):
   ```dart
   @TypedGoRoute<BookmarkDetailRoute>(path: RoutePaths.bookmarkDetail)
   class BookmarkDetailRoute extends GoRouteData with $BookmarkDetailRoute {
     final int bookmarkId;
     const BookmarkDetailRoute({required this.bookmarkId});

     @override
     Widget build(BuildContext context, GoRouterState state) =>
         BookmarkDetailView(bookmarkId: bookmarkId);
   }
   ```

3. **For a custom transition**, override `buildPage`:
   ```dart
   @override
   Page<void> buildPage(BuildContext context, GoRouterState state) {
     return CustomTransitionPage<void>(
       key: state.pageKey,
       child: BookmarkDetailView(bookmarkId: bookmarkId),
       transitionsBuilder: (_, animation, __, child) =>
           FadeTransition(opacity: animation, child: child),
       transitionDuration: const Duration(milliseconds: 300),
     );
   }
   ```

4. **For route params that can't go in the URL** (complex objects), use `$extra`:
   ```dart
   final Bookmark $extra;
   ```
   Then navigate with `BookmarkDetailRoute($extra: bookmark).go(context)`.

5. **Run code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Navigate from wherever** using `const BookmarkDetailRoute(bookmarkId: 42).go(context)` (or `.push`, `.replace`).

---

## 5. Adding a new shared component

1. **Decide the scope:**
   - Used by ≥2 modules → `lib/src/shared/components/<component>.dart`
   - Used by ≥2 features within one module → `lib/src/modules/<module>/shared/components/<component>.dart`
   - Used by one feature only → keep it feature-private at `lib/src/features/<feature>/widgets/<component>.dart`

2. **Name the file in snake_case** matching the widget class in `PascalCase` (e.g., `primary_button.dart` → `PrimaryButton`).

3. **Use the style contract:**
   - Colors from `ColorName.*` (never raw hex)
   - Fonts from `FontFamily.manrope` (or the project's standard family)
   - Sizes via `.dp` / `.sp` / `.w`
   - Take every variable via constructor

4. **Expose state hooks** where appropriate:
   - `isLoading` for async affordances
   - `onPressed` returning `void` or `Future<void>`
   - Optional style overrides (`backgroundColor`, `foregroundColor`, `border`, `borderRadius`)

5. **If it consumes user-facing strings** (like a button label), accept them as a `String text` parameter — never hardcode.

6. **If it uses icons**, accept a `Widget? icon` parameter; don't hardcode an SVG path.

7. **Don't reach into providers** from a shared component. Shared components are dumb presenters. State comes from the caller.

8. **Write a dartdoc comment** if non-obvious:
   ```dart
   /// Primary CTA button. Honors `isLoading` by replacing the label with a spinner
   /// and disabling the tap. Use for the most prominent action per screen.
   ```

---

## 6. Adding a user-facing string

1. **Open `lib/l10n/app_en.arb`**. Add the key:
   ```json
   "bookmark_emptyState": "You haven't saved anything yet"
   ```

2. **If the string has parameters**, add a placeholder block:
   ```json
   "bookmark_greeting": "Hello, {name}!",
   "@bookmark_greeting": {
     "placeholders": {
       "name": { "type": "String" }
     }
   }
   ```

3. **Add translations** for every other ARB file (e.g., `app_fr.arb`). Never leave a key only in `app_en.arb` — it breaks runtime locales.

4. **Regenerate localization:**
   ```bash
   flutter gen-l10n
   ```
   (Also runs automatically when `flutter pub get` runs, but explicit is safer.)

5. **Use via `context.text.key`** in the widget:
   ```dart
   Text(context.text.bookmark_emptyState)
   Text(context.text.bookmark_greeting('Alice'))
   ```

6. **For validators**, pass `AppLocalizations` as a parameter to the view model:
   ```dart
   // view model
   String? validateEmail(String? v, AppLocalizations l10n) { ... }

   // view
   validator: (v) => vm.validateEmail(v, context.text),
   ```

---

## 7. Adding a side-effect in a view after async completes

Use this pattern when a successful API call should navigate, show a toast, or invalidate another provider.

1. **Inside `_ViewState.initState`**, after `super.initState()`:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     ref.listenManual(
       <screen>ViewModelProvider.select((s) => s.<action>Status),
       (previous, next) {
         if (previous == next) return;
         next.maybeWhen(
           success: (data) {
             // navigate / toast / invalidate
             const NextRoute().replace(context);
           },
           failure: (msg) {
             PrimaryMessenger.showError(context, msg);
           },
           authFailure: (_) {
             const LoginRoute().replace(context);
           },
           orElse: () {},
         );
       },
     );
   });
   ```

2. **Never navigate inside the view model.** The view model emits Status; the view reacts.

3. **One listener per Status field you care about.** Don't collapse multiple actions into one listener — keep them isolated so adding a fourth doesn't destabilize the first three.

4. **The `if (previous == next) return;` guard is mandatory** — without it, every unrelated state field change retriggers the side effect.

---

## 8. Observability for a new authenticated action

Every authenticated action (login success, signup success, subscribe success, profile update) follows this ritual in the view model after the API call succeeds:

```dart
// 1. Update in-memory profile (if the action changes the user profile)
ref.read(currentProfileProvider.notifier).setProfile(newProfile);

// 2. Sync telemetry user context (all four services)
await CrashlyticsService.instance.syncUserContext(
  profile: profile, authSource: '<action>',
);
await SentryService.instance.syncUserContext(
  profile: profile, authSource: '<action>',
);
await ClarityService.instance.syncUserContext(
  profile: profile, authSource: '<action>',
);
await UxCamService.instance.syncUserContext(
  profile: profile, authSource: '<action>',
);

// 3. Emit a tracked event + breadcrumb
await UxCamService.instance.trackEvent(
  '<action>_success',
  properties: {'flow': '<flow>', 'provider': '<provider>'},
);
await SentryService.instance.addBreadcrumb(
  category: '<flow>',
  message: '<action>_success',
  data: {'flow': '<flow>', 'provider': '<provider>'},
);
ClarityService.instance.trackEvent('<action>_success');

// 4. Request permissions / register tokens (for login-like actions only)
await NotificationService().requestPermissionsIfNeeded();
await FcmRegistrationService.instance.registerCurrentToken();
```

For logout, call `clearUserContext()` on all four services + `LocalStorage.clear()` in the repository's `logout()` method — not in the view model.

---

## 9. Pre-PR verification checklist

Before opening a PR:

- [ ] `dart run build_runner build --delete-conflicting-outputs` ran cleanly (no pending codegen).
- [ ] `flutter analyze` passes with no new warnings.
- [ ] Tests pass: `flutter test`.
- [ ] Manual smoke test of the changed feature.
- [ ] All new user-facing strings are in `app_en.arb` and every other supported locale.
- [ ] All new paths added to `route_paths.dart`, not inlined.
- [ ] All new endpoints added to `endpoints.dart` (or module endpoints), not inlined.
- [ ] New shared widgets placed at correct scope (app-wide vs. module vs. feature).
- [ ] No raw pixel sizes in new UI code — all through `.dp` / `.sp` / `.w`.
- [ ] No hardcoded colors — all through `ColorName.*`.
- [ ] No direct Dio or SharedPreferences calls from view models or views.
- [ ] Every async action uses the `Status` union (not raw booleans).
- [ ] Authenticated actions include the full observability sequence (checklist #8).
