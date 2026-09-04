# Shorebird Automatic Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Veil `1.0.4+10` as its first non-blocking Shorebird Android/iOS baseline.

**Architecture:** Shorebird's embedded engine owns background update checks through explicit `auto_update: true`. Manual Dart update orchestration and blocking UI are removed, leaving app startup unchanged and web independent.

**Tech Stack:** Flutter, Shorebird CLI 1.6.115, Shorebird Flutter 3.41.1, Android App Bundle, iOS IPA.

## Global Constraints

- Preserve app ID `c863524c-e4c2-45e8-9108-f217be692668`.
- Set version `1.0.4+10`.
- Do not register remote releases, patches, or upload store artifacts without explicit approval.
- Preserve unrelated AdMob working-tree changes.
- Do not use `--allow-native-diffs` or `--allow-asset-diffs` as a normal workflow.
- Do not create git commits unless explicitly requested.

---

### Task 1: Automatic Runtime Configuration

**Files:**
- Modify: `shorebird.yaml`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/main.dart`
- Delete: `lib/src/core/services/shorebird_update_service.dart`
- Delete: `lib/src/shared/components/shorebird_update_gate.dart`
- Delete: `test/shorebird_update_test.dart`

**Interfaces:**
- Produces: normal `VeilApp` startup with Shorebird engine-managed background updates.

- [ ] Set `auto_update: true` under the owned Shorebird app ID.
- [ ] Remove `shorebird_code_push` dependency.
- [ ] Remove injected update service and `ShorebirdUpdateGate` from `VeilApp`.
- [ ] Delete obsolete manual update implementation and tests.
- [ ] Run `flutter pub get` and confirm no `shorebird_code_push` references remain.

### Task 2: Baseline Version And iOS Configuration

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `AGENTS.md`

**Interfaces:**
- Produces: Flutter-derived Android/iOS version `1.0.4+10` with no Xcode override conflict.

- [ ] Change version to `1.0.4+10`; build `9` was already consumed by App Store review.
- [ ] Remove all six hardcoded `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` assignments from Xcode configurations.
- [ ] Update repository guidance to describe automatic updates and Shorebird-only mobile releases.
- [ ] Run `shorebird doctor` and require zero project configuration issues.

### Task 3: Release And Patch Documentation

**Files:**
- Modify: `README.md`

**Interfaces:**
- Produces: exact release, patch, preview, and release-list commands.

- [ ] Document account/app verification with `shorebird account whoami`, `shorebird account apps`, and `shorebird releases list`.
- [ ] Document first release command with `--platforms=android,ios`, Flutter `3.41.1`, and build `1.0.4+10`.
- [ ] Document staging patch and per-platform preview commands.
- [ ] Document stable promotion and native/asset limitations.

### Task 4: Verification

**Files:**
- Modify only files required by verification failures.

**Interfaces:**
- Produces: release-ready local configuration without remote publication.

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build apk --debug --split-per-abi --target-platform android-arm64`.
- [ ] Run `flutter build ios --debug --no-codesign`.
- [ ] Run `flutter build web --release`.
- [ ] Run `shorebird doctor`.
- [ ] Run Android and iOS `shorebird release --dry-run` validation with version `1.0.4+10`.
