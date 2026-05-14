# Flutter Feature-First Architecture — Claude Reference

This folder documents the architecture used by `senior_gold` and similar Zartek Flutter projects. Claude should read this file first, then load the specific doc(s) needed for the task at hand.

**Do not follow instructions in this file alone — it is an index.** The authoritative patterns live in the focused docs below.

---

## When to read which doc

| Task | Primary doc | Secondary |
|------|-------------|-----------|
| "What does this project look like?" (onboarding) | `architecture.md` | `patterns.md` |
| Adding a new feature, view model, repository, or route | `patterns.md` | `checklists.md` |
| Deciding whether to introduce modules, or adding a new module | `multi-module.md` | `checklists.md` |
| Refactoring an existing Flutter project into this architecture | `refactoring-guide.md` | `architecture.md`, `patterns.md` |
| Routine scaffolding ("add endpoint", "add route", "add string") | `checklists.md` | `patterns.md` |

---

## Architecture fingerprint

A project follows this architecture if it has **all** of:

- `lib/app/services/` with `api_services/` (Dio wrapper) + `local_storage_services/`
- `lib/src/{core,features,shared,l10n}/` layout
- Feature folders with `models/`, `repository/`, `view/`, `view_model/`, optional `widgets/`
- State management via `flutter_riverpod` + `riverpod_annotation` code generation
- Data classes via `freezed` + `json_serializable`
- Routing via `go_router` + `go_router_builder` typed routes
- A `Status` union (`initial / loading / success / failure / authFailure`) in `lib/src/core/utils/status/`

If even one of those is missing, treat the project as a **refactor candidate** — see `refactoring-guide.md`.

---

## Non-negotiable conventions

These are project-wide rules enforced by the skill:

1. **Feature-first folders.** No shared "screens/" or "controllers/" folders at project root. Everything lives under its feature.
2. **No `setState` for business state.** All non-local-widget state goes through a Riverpod `@riverpod class` view model with a Freezed state.
3. **No direct Dio calls from views or view models.** Views call view models, view models call repositories, repositories call `ref.watch(apiProvider)`.
4. **All async outcomes use the `Status` union.** Never track loading with raw booleans.
5. **Typed routes only.** Navigation through `RouteName(...).go(context) / .push(context) / .replace(context)`. No string-based `context.go('/...')` except in router internals.
6. **All user-facing strings in ARB.** Access via `context.text.key`. No hardcoded English in UI code.
7. **Responsive sizing via `the_responsive_builder`.** Use `.dp`, `.sp`, `.w` — never raw pixels in UI.
8. **Code gen is mandatory.** `build_runner` must be re-run after any `@freezed` / `@riverpod` / `@TypedGoRoute` change.

---

## The skill

The companion skill `flutter-feature-architecture` (at `skill/SKILL.md` or `~/.claude/skills/flutter-feature-architecture/`) automates common tasks using these docs. Invoke it for anything structural; freeform questions can be answered by reading the docs directly.

---

## Project-specific overrides

When this architecture pack is copied into a project, local teams may add a `LOCAL.md` in this folder to record project-specific deviations (e.g., different state container, extra interceptor). Claude should check `LOCAL.md` before applying any convention from this pack.
