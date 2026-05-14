---
name: flutter-feature-architecture
description: Use for any structural Flutter/Dart work in a project following the Zartek feature-first architecture (Riverpod codegen + Freezed + typed go_router + Dio Api wrapper + Status union). Triggers on tasks like scaffolding a feature, adding a view model, adding a repository, adding a typed route, adding a shared component, adding a module (multi-module variant), refactoring a legacy Flutter project into this architecture, or migrating flat → modular. Always asks "multi-module or flat?" as the second question before generating paths. Do NOT use for: simple syntax questions, package upgrades without structural implications, pure bug fixes, or Flutter work in projects that do not follow this architecture (check for `doc/claude-architecture/` folder or the architecture fingerprint in `CLAUDE.md` before engaging).
---

# flutter-feature-architecture

Structural Flutter development and refactoring following the Zartek feature-first architecture. This skill enforces the patterns in the companion docs — it does not re-describe them.

## Authoritative references

**Before doing anything, load the relevant doc(s) for the task.** These docs are the contract; the skill just executes them:

| Task | Primary doc | Secondary |
|---|---|---|
| Adding a feature / view model / repository / route / shared component / string | `doc/claude-architecture/patterns.md` | `doc/claude-architecture/checklists.md` |
| Adding or introducing modules | `doc/claude-architecture/multi-module.md` | `doc/claude-architecture/checklists.md` |
| Refactoring an existing project into this architecture | `doc/claude-architecture/refactoring-guide.md` | `doc/claude-architecture/architecture.md`, `patterns.md` |
| Onboarding / high-level "what is this?" questions | `doc/claude-architecture/architecture.md` | `patterns.md` |

If `doc/claude-architecture/` is **not** present in the target project, look for it at `~/.claude/skills/flutter-feature-architecture/docs/` (offline bundled copy) or halt and ask the user how to proceed.

---

## The flow

<HARD-GATE>
Do NOT write files, generate code, or edit the project until you have completed steps 1–3 below. Steps 1–3 are mandatory for every invocation of this skill.
</HARD-GATE>

### Step 1 — Context detect (silent)

Before asking anything, verify this project follows the architecture:

1. Check `pubspec.yaml` for: `flutter_riverpod`, `riverpod_annotation`, `freezed`, `go_router_builder`, `dio`.
2. Check `lib/` for: `lib/app/services/api_services/` and `lib/src/{core,features,shared}/` (flat) OR `lib/src/modules/` (multi-module).
3. Check for `doc/claude-architecture/CLAUDE.md`.
4. Check for `doc/claude-architecture/LOCAL.md` (project-specific overrides — **always respect LOCAL.md over this skill**).

If fingerprint matches → proceed to Step 2.

If fingerprint is partial → this is a **refactoring candidate**. Jump straight to Step 4 with task type **C (refactor)**.

If fingerprint doesn't match at all AND user asked for a generic Flutter task → **decline to engage**. Say: "This project doesn't follow the Zartek feature-first architecture. I can help as a general Flutter question, or we can plan a migration using `doc/claude-architecture/refactoring-guide.md`."

### Step 2 — Ask task type (one question)

Ask exactly this question, multiple choice:

> **What do you want to do?**
>
> - **A)** Add a new feature (one or more screens + models + repository)
> - **B)** Add a new module (group of features — multi-module variant only)
> - **C)** Refactor an existing Flutter project into this architecture
> - **D)** Add an endpoint / route / shared component / string to an existing feature
> - **E)** Migrate a flat project to multi-module

### Step 3 — Ask "multi-module or flat?" (only when required)

Ask this question only for **A, C, and E**:

> **Is this project:**
>
> - **F)** Flat — features live directly under `lib/src/features/`
> - **M)** Multi-module — features grouped under `lib/src/modules/<module>/features/`

**How to auto-detect** (skip the question if obvious):
- If `lib/src/modules/` exists → **M**.
- If `lib/src/features/` exists and `lib/src/modules/` does not → **F**.
- If neither → ask.

For **B (add module)** and **E (migrate to modular)**: the project is (or is becoming) multi-module by definition — no ask.

For **D (add to existing)**: inherit whatever structure the existing feature lives under. No ask.

### Step 4 — Gather task-specific inputs

Based on the task type, ask ONLY for the inputs you can't infer:

| Task | Ask |
|---|---|
| **A — new feature** | Feature name (snake_case), screen list, rough data model (fields), feature's URL prefix if multi-module |
| **B — new module** | Module name, URL prefix, initial feature list |
| **C — refactor** | Current state management, current routing, current networking, screen count (rough), multi-module intent |
| **D — small addition** | What exactly (endpoint / route / component / string), which feature it lives in, and inputs specific to that |
| **E — flat → modular** | Proposed module groupings (which features go where) |

Ask grouped — don't go one-by-one for this step; the user has already committed to a task type.

### Step 5 — Execute the matching checklist

Load `doc/claude-architecture/checklists.md` and follow the numbered runbook verbatim:

| Task | Checklist |
|---|---|
| A — new feature | #1 Adding a new feature |
| B — new module | #2 Adding a new module |
| C — refactor | Use `refactoring-guide.md` phases, not a single checklist |
| D — add endpoint | #3 |
| D — add route | #4 |
| D — add component | #5 |
| D — add string | #6 |
| D — add side-effect listener | #7 |
| D — add observability hooks | #8 |
| E — flat → modular | `multi-module.md §Migrating flat → modular` |

**Use `TaskCreate` to turn each checklist step into a trackable task.** Mark `in_progress` before starting a step, `completed` immediately when done — never batch.

Use the templates in `doc/claude-architecture/patterns.md` verbatim. Substitute domain-specific names but do not change the shape.

### Step 6 — Verification gate (pre-report)

Before telling the user "done", run:

1. `dart run build_runner build --delete-conflicting-outputs` — must complete without errors.
2. `flutter analyze` — must report no new warnings.
3. For UI-bearing changes: start the dev server / hot reload and manually verify the flow. If you can't (headless environment), say so explicitly — don't claim success.
4. Confirm every item on `checklists.md §9 Pre-PR verification checklist` that applies.

If any of these fail, do NOT say the task is complete. Report the failure with the exact error and stop.

### Step 7 — Report

Short report. Format:

> **Done — <task type>**
>
> **Files created:**
> - `path/to/file.dart`
> - ...
>
> **Files modified:**
> - `path/to/file.dart` (added: X, Y)
>
> **Verification:**
> - build_runner: ✅
> - flutter analyze: ✅
> - Manual smoke test: ✅ / ⚠ (describe)
>
> **Follow-ups:**
> - Strings added to `app_en.arb` — translations needed for: fr, de, ...
> - Route registered at `/<path>` — navigate to it from ...

---

## Decision table

When the user says something ambiguous, resolve via this table:

| User says | Map to |
|---|---|
| "Add a screen" | A (new feature) IF it has new models/repo, else D (new route + new view file in existing feature) |
| "Add a page" | Same as "screen" |
| "Add this API" | D (new endpoint) |
| "Add a button" / "make a reusable X" | D (new shared component) |
| "Translate this" | D (new i18n string) |
| "Split this app into modules" | E |
| "Restructure this Flutter project" | C (refactor) |
| "Create a payment/shopping/wallet area" | B (new module) — but first confirm the project is multi-module (or should become one) |

---

## Non-negotiable rules (enforced by this skill)

Quote these rules to the user if they're about to violate them. Do not quietly comply.

1. **No `setState` for business state.** Use a Riverpod `@riverpod class` view model.
2. **No direct Dio calls from views or view models.** Views → view models → repositories → `apiProvider`.
3. **All async outcomes use the `Status` union.** No `bool isLoading` fields.
4. **Typed routes only.** `RouteName().go(context)`, never `context.go('/string')`.
5. **All user-facing strings in ARB.** Validators take `AppLocalizations l10n` as a parameter.
6. **Responsive sizing via `.dp/.sp/.w`.** No raw pixels in UI.
7. **No inline endpoints.** All URLs in `endpoints.dart` (or `<module>_endpoints.dart`).
8. **Code gen is part of the task.** Never mark a task done without running `build_runner`.
9. **No reaching into module internals across modules.** Cross-module imports go through `<module>_module.dart` only.
10. **LOCAL.md overrides this skill.** If a project documents a deviation, follow the deviation.

---

## Anti-patterns the skill will refuse to produce

- A view that imports `package:dio/dio.dart`.
- A view model that imports `package:flutter/material.dart` except for the minimal types (e.g., `Color`). **Never** `BuildContext`.
- A repository that imports any widget.
- A state class with a `bool isLoading` field.
- A `Navigator.pushNamed(context, '...')` call in a view.
- An inlined endpoint string like `dio.get('https://api.x.com/...')`.
- A hardcoded English string in a widget (e.g., `Text('Submit')`).
- A cross-module import of `package:<app>/src/modules/X/features/...`.

If the user explicitly asks for one of these, push back once with the reason. If they insist, do it but add a `// LOCAL.md: documented deviation required` comment and mention in the report that `LOCAL.md` should record the deviation.

---

## Red flags (stop and re-verify)

| Thought | Reality |
|---|---|
| "This is just a small tweak, skip Step 1" | Step 1 is silent and cheap — always run it. |
| "I remember the pattern, no need to reopen patterns.md" | Docs evolve. Reload. |
| "The user said 'add a screen', just do it" | Step 2 still required — "screen" might mean A or D. |
| "`build_runner` is slow, skip it" | Generated files drift silently. Never skip. |
| "multi-module looks more professional, suggest it" | Only when the three criteria in `multi-module.md` apply. Flat is the default. |
| "The legacy project mostly matches, just add to it" | Audit first — partial match = refactor candidate, not a green light. |

---

## Platform notes

- **Claude Code** — this skill auto-triggers when the user mentions structural Flutter tasks in a repo matching the fingerprint. `/flutter-feature-architecture` invokes it explicitly.
- **Copilot CLI / Gemini CLI** — same flow, use platform-native tool names (see `references/` in superpowers for mappings).
- **Codex** — same flow.

---

## When to decline

Decline to use this skill (and say so to the user) when:

- The project clearly follows a different architecture (BLoC, GetX, MobX) and the user isn't asking to refactor.
- The task is a generic Flutter question with no structural implications ("how does FutureBuilder work?").
- The user is working in a non-Flutter Dart project (CLI tool, package).

In those cases, defer to the general `flutter-dart-mobile-app-development` skill or just answer directly.
