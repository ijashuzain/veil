# Multi-Module Variant

Same architecture, but features are grouped into **modules** — coarse-grained domain areas (e.g., `shopping`, `payment`, `delivery`, `wallet`). Use this variant when the app has multiple distinct product surfaces that would otherwise make `lib/src/features/` unwieldy.

This is a **single-project** pattern. No Melos, no separate Dart packages. Just deeper folder nesting with clear boundary rules.

---

## When to go multi-module

Introduce modules when **all three** apply:

1. You have **≥2 coherent domain groupings** that own ≥3 features each. Examples: `shopping` (product, cart, checkout, orders) and `payment` (wallet, methods, transactions).
2. The groupings have **independent lifecycles** — shopping can ship a feature without touching payment code.
3. There is a **clear ownership boundary** — one team or squad owns each module, or they map to distinct product verticals.

**Do NOT go multi-module** when:

- You just have lots of features in one domain (50 features, all "social app stuff" → stay flat).
- Your features share tight domain models (e.g., every feature touches `Post` — modules would cause cross-module coupling everywhere).
- You're just trying to "organize better". Grouping features alphabetically or by UI section isn't a module — it's bikeshedding.

**Conversion isn't free.** Refactoring flat → modular touches every import, every route, and shared components. Only do it when the three criteria above are firmly met.

---

## Folder layout

```
lib/
├── main.dart
├── firebase_options.dart
├── app/                            # Global infrastructure — UNCHANGED from flat variant
│   └── services/
│       ├── api_services/
│       └── local_storage_services/
├── gen/                            # UNCHANGED
├── l10n/                           # UNCHANGED — ARB files are app-level (one translation pool)
└── src/
    ├── core/                       # App-wide core — UNCHANGED from flat variant
    │   ├── config/
    │   ├── constants/
    │   ├── extensions/
    │   ├── firebase/
    │   ├── providers/
    │   │   ├── router_provider.dart    # Owns the root router
    │   │   └── locale_provider.dart
    │   ├── router/
    │   │   ├── app_router.dart         # Composes module routers
    │   │   └── route_paths.dart        # App-wide paths (splash, landing, shell)
    │   ├── services/
    │   └── utils/
    ├── modules/                    # ← NEW: module root
    │   ├── shopping/
    │   │   ├── core/                       # Module-local core (optional)
    │   │   │   ├── constants/
    │   │   │   │   └── shopping_endpoints.dart
    │   │   │   └── providers/              # Module-scoped cross-feature providers
    │   │   ├── features/
    │   │   │   ├── product/
    │   │   │   │   ├── models/
    │   │   │   │   ├── repository/
    │   │   │   │   ├── view/
    │   │   │   │   └── view_model/
    │   │   │   ├── cart/
    │   │   │   ├── checkout/
    │   │   │   └── orders/
    │   │   ├── shared/                     # Module-local shared widgets/models
    │   │   │   ├── components/
    │   │   │   ├── enums/
    │   │   │   └── models/
    │   │   ├── router/
    │   │   │   ├── shopping_routes.dart    # Module's @TypedGoRoute classes
    │   │   │   └── shopping_route_paths.dart
    │   │   └── shopping_module.dart        # Module entry — exports routes, public surface
    │   ├── payment/
    │   │   ├── core/
    │   │   │   └── constants/
    │   │   │       └── payment_endpoints.dart
    │   │   ├── features/
    │   │   │   ├── wallet/
    │   │   │   ├── methods/
    │   │   │   └── transactions/
    │   │   ├── shared/
    │   │   ├── router/
    │   │   │   ├── payment_routes.dart
    │   │   │   └── payment_route_paths.dart
    │   │   └── payment_module.dart
    │   └── account/                        # "Always-there" module for profile, settings, auth
    │       └── ...
    ├── shared/                     # App-wide shared components — used by ≥2 modules
    │   ├── components/
    │   ├── enums/
    │   ├── models/
    │   └── utils/
    └── l10n/                       # Generated localization — UNCHANGED
```

**What stays at app level** (`lib/src/`):

- `core/` — app-wide router, config, env, core services (Crashlytics, Sentry, etc.), typed extensions.
- `shared/` — truly cross-module widgets (`PrimaryButton`, `PrimaryTextField`, `PrimaryMessenger`).
- `l10n/` — one ARB pool for the whole app. Module-specific strings use a `<module>_` prefix in keys (e.g., `shopping_addToCart`).

**What moves into each module:**

- Features (obvious).
- Module-local shared widgets (used by ≥2 features within the module but not by other modules).
- Module-local endpoints (in `<module>/core/constants/<module>_endpoints.dart`).
- Module router file (the module's typed routes).

---

## Module boundaries (the important rules)

### ✅ Allowed imports

- **Any module → app-level** (`lib/src/core/`, `lib/src/shared/`, `lib/app/services/`, `lib/gen/`, `lib/src/l10n/`). Modules depend on the app, not the other way around.
- **Within a module** — `features/*` can import from the module's `core/`, `shared/`, and sibling `features/*`.
- **Module-to-module via the public surface file** (`<module>_module.dart`). Module A imports `<module-b>_module.dart` if it needs something public from Module B.

### ❌ Forbidden imports

- **`lib/src/modules/X/features/...` imported from outside Module X.** Never reach into another module's internals. Only `<module-x>_module.dart` (the public surface) is importable from outside.
- **`lib/src/core/` importing from any module.** Core never depends on modules.
- **Circular module dependencies.** If A needs B and B needs A, either merge them or extract the shared bit to `lib/src/shared/` (or a new module).

Enforce with a simple lint override (optional but recommended):

```yaml
# analysis_options.yaml
analyzer:
  errors:
    # Flag imports that cross module internals — review manually.
    # (Dart doesn't enforce this by default; rely on PR review + a custom lint if needed.)
```

---

## Module public surface (`<module>_module.dart`)

Each module has one top-level file that exports:

1. Module routes (for merging into the root router)
2. Any providers other modules legitimately need
3. Any models other modules need to reference

```dart
// lib/src/modules/shopping/shopping_module.dart

/// Public surface of the shopping module. This file is the ONLY entry point
/// other modules and app-level code may import from shopping/.
library shopping_module;

// Routes — exported so router/app_router.dart can register them.
export 'router/shopping_routes.dart';
export 'router/shopping_route_paths.dart';

// Cross-module providers (e.g., current cart count badge)
export 'core/providers/cart_badge_provider.dart';

// Models that other modules legitimately reference (e.g., payment needs Order)
export 'features/orders/models/order/order.dart';
```

Cross-module code imports:

```dart
// in payment module
import 'package:<app>/src/modules/shopping/shopping_module.dart';
// gives access to Order, cartBadgeProvider, and shopping routes — nothing else.
```

---

## Router composition

Each module owns its routes. `lib/src/core/router/app_router.dart` merges them.

### Module route file

```dart
// lib/src/modules/shopping/router/shopping_routes.dart

import 'package:go_router/go_router.dart';
import '../features/product/view/product_list_view.dart';
import '../features/product/view/product_detail_view.dart';
import 'shopping_route_paths.dart';

part 'shopping_routes.g.dart';

@TypedGoRoute<ProductListRoute>(path: ShoppingRoutePaths.productList)
class ProductListRoute extends GoRouteData with $ProductListRoute {
  const ProductListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const ProductListView();
}

@TypedGoRoute<ProductDetailRoute>(path: ShoppingRoutePaths.productDetail)
class ProductDetailRoute extends GoRouteData with $ProductDetailRoute {
  final int productId;
  const ProductDetailRoute({required this.productId});
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProductDetailView(productId: productId);
}
```

```dart
// lib/src/modules/shopping/router/shopping_route_paths.dart

abstract class ShoppingRoutePaths {
  static const _prefix = '/shop';

  static const productList = '$_prefix/products';
  static const productDetail = '$_prefix/products/:productId';
  static const cart = '$_prefix/cart';
  static const checkout = '$_prefix/checkout';
}
```

**Convention:** each module reserves a URL prefix (`/shop`, `/pay`, `/account`) to prevent path collisions.

### Root app router composition

`go_router_builder` generates a top-level `$appRoutes` list. When using the annotation pattern across files, each `@TypedGoRoute` contributes. If you want a unified root, collect module routes in `app_router.dart`:

```dart
// lib/src/core/router/app_router.dart
import 'package:<app>/src/modules/shopping/shopping_module.dart';
import 'package:<app>/src/modules/payment/payment_module.dart';
import 'package:<app>/src/modules/account/account_module.dart';

// App-level routes (splash, landing, shell, error)
@TypedGoRoute<SplashRoute>(path: RoutePaths.splash)
class SplashRoute extends GoRouteData with $SplashRoute { ... }

// Module routes come in transitively via the exports. The generator picks
// them up from the whole compilation unit.
```

`go_router_builder` discovers all `@TypedGoRoute`-annotated classes in the compilation graph, so as long as the module route files are reachable from `app_router.dart` (via any import chain), their routes register automatically.

---

## Module entry for cross-module providers

If other modules legitimately need a provider (e.g., payment needs the current cart total for a "Pay $X" button), expose it via `<module>_module.dart`:

```dart
// lib/src/modules/shopping/core/providers/cart_badge_provider.dart
@riverpod
int cartBadge(Ref ref) {
  final cart = ref.watch(cartStateProvider);
  return cart.itemCount;
}
```

```dart
// Then export from shopping_module.dart:
export 'core/providers/cart_badge_provider.dart';
```

Keep the public surface **narrow**. If everything is exported, there's no module.

---

## Module-local endpoints

Instead of one giant `Endpoints` class, each module has its own:

```dart
// lib/src/modules/shopping/core/constants/shopping_endpoints.dart

import 'package:<app>/gen/enviro.gen.dart';

class ShoppingEndpoints {
  static String baseUrl = Enviro.apiUrl;

  static String products = "$baseUrl/shop/products/";
  static String productDetail(int id) => "$baseUrl/shop/products/$id/";
  static String cart = "$baseUrl/shop/cart/";
  static String checkout = "$baseUrl/shop/checkout/";
}
```

App-wide endpoints (auth, user profile) stay in `lib/src/core/constants/endpoints.dart`.

---

## Module-local shared widgets

If `ProductCard` is used by `product/`, `cart/`, and `orders/` inside the shopping module — but **nowhere else** — put it at:

```
lib/src/modules/shopping/shared/components/product_card.dart
```

Only promote to app-wide `lib/src/shared/components/` when a **second module** needs it.

---

## Localization in multi-module

ARB files stay at `lib/l10n/`. One translation pool for the whole app. Convention to keep keys organized:

- `shopping_addToCart`
- `shopping_checkout_title`
- `payment_confirmFailed`
- `account_settings_title`

App-wide strings stay unprefixed: `save`, `cancel`, `errorGeneric`.

When a module grows past ~100 keys, consider splitting ARB via `flutter_gen_runner`'s multi-file support — but this is rarely necessary.

---

## Services in multi-module

App-wide services (Crashlytics, Sentry, UxCam, Clarity, NotificationService) stay in `lib/src/core/services/`. All modules call them directly.

**Module-local services are an anti-pattern** unless the service is genuinely module-private (e.g., a payment SDK wrapper that no other module uses). If in doubt, start at app level and demote to a module later if truly scoped.

---

## Adding a new module (checklist)

1. Create `lib/src/modules/<module>/` with `core/`, `features/`, `shared/`, `router/` folders.
2. Reserve a URL prefix in `<module>_route_paths.dart`.
3. Create `<module>_module.dart` as the public surface file with a `library <module>_module;` directive.
4. Move or create module-scoped endpoints to `<module>/core/constants/<module>_endpoints.dart`.
5. Add the module's import to `lib/src/core/router/app_router.dart` so route discovery picks it up.
6. Run `dart run build_runner build --delete-conflicting-outputs`.
7. Update `doc/claude-architecture/LOCAL.md` with module ownership + any deviations.

See `checklists.md` for the full runbook.

---

## Migrating flat → modular

Only do this when the three criteria at the top of this doc are met. If yes:

1. **Identify modules.** Group existing features by domain. Write the groupings down first; don't move code yet.
2. **Per module, create `lib/src/modules/<module>/` with empty subfolders.**
3. **Move features one at a time**, running tests after each move.
4. **Extract module endpoints** from the monolithic `Endpoints` class into `<module>_endpoints.dart`.
5. **Extract module-local shared widgets** from `lib/src/shared/` if they're used by only one module.
6. **Write `<module>_module.dart`** for each module; lock down the public surface.
7. **Audit imports** — every cross-module import must go through `<module>_module.dart`. Fix violations.
8. **Update router** — move routes to `<module>_routes.dart`, re-run codegen.
9. **Commit per module**, not all at once. Migration should be incremental.

The `refactoring-guide.md` doc covers the broader legacy-to-architecture migration; this section is just the flat-to-modular delta.
