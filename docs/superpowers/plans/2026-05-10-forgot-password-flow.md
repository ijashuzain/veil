# Forgot Password Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Supabase-backed forgot-password and reset-password flow.

**Architecture:** Keep sign in, sign up, forgot-password, and sent-confirmation states inside the existing onboarding auth card. Add a dedicated `/reset-password` route for links from Supabase recovery emails. `AuthRepository` owns Supabase calls, `AuthViewModel` owns validation/status, and views stay thin.

**Tech Stack:** Flutter, Riverpod, Supabase Flutter, GoRouter, Flutter widget tests.

---

### Task 1: Repository and View Model

**Files:**
- Modify: `lib/src/features/auth/repository/auth_repository.dart`
- Modify: `lib/src/features/auth/view_model/auth_view_model/auth_view_model.dart`
- Test: `test/auth_password_reset_test.dart`

- [ ] Write failing tests for reset email and password update methods.
- [ ] Add `requestPasswordReset(email, redirectTo)` and `updatePassword(password)` repository methods.
- [ ] Add `sendPasswordReset` and `updatePassword` view-model methods with email/password validation.

### Task 2: Onboarding Forgot Password UI

**Files:**
- Modify: `lib/src/features/onboarding/view/onboarding_view.dart`
- Test: `test/auth_password_reset_test.dart`

- [ ] Add a `Forgot password?` action on sign-in mode.
- [ ] Add email-only forgot-password mode.
- [ ] Add reset-link-sent mode with a `Back to login` button.

### Task 3: Reset Password Route

**Files:**
- Modify: `lib/src/core/router/route_paths.dart`
- Modify: `lib/src/core/router/app_router.dart`
- Create: `lib/src/features/auth/view/reset_password_view.dart`
- Test: `test/auth_password_reset_test.dart`

- [ ] Add `/reset-password` route without regenerating typed routes.
- [ ] Add new password and confirm password fields.
- [ ] Call `AuthViewModel.updatePassword`, show success, and navigate back to login.

### Task 4: Verification and Deploy

**Files:**
- Build output: `build/web`

- [ ] Run `rtk dart format` on touched Dart files.
- [ ] Run focused password reset tests.
- [ ] Run `rtk flutter analyze`.
- [ ] Run `rtk flutter test`.
- [ ] Run `rtk flutter build web --release`.
- [ ] Deploy with `rtk firebase deploy --only hosting --project veil-12353`.
