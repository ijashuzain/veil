# Shorebird Automatic Updates Design

**Date:** 2026-08-29
**Status:** Approved

## Goal

Make `1.0.4+10` the first Shorebird-enabled Veil store baseline on Android and iOS, using non-blocking automatic background patch downloads.

## Identity And Baseline

- Shorebird app ID: `c863524c-e4c2-45e8-9108-f217be692668`.
- Current Shorebird account owns this app and has no releases.
- Old app ID `943315bc-081a-40bb-81a3-ede72d8a7d83` is inaccessible and must not be restored.
- Use `1.0.4+10` because build `9` was consumed by App Store review and was built without the Shorebird engine.
- Native AdMob changes also require a new store baseline rather than a patch.

## Runtime Strategy

- Set `auto_update: true` explicitly in `shorebird.yaml`.
- Rely on Shorebird engine background checks and downloads.
- Apply downloaded patches on next process restart.
- Remove `shorebird_code_push` and all manual update-check UI/service code.
- Never block startup, routing, auth restoration, or web rendering on update checks.
- Web remains outside Shorebird and continues through normal Firebase deployment.

## Build Configuration

- Keep `shorebird.yaml` bundled as a Flutter asset.
- Remove hardcoded `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` values from the Xcode project; Flutter/Shorebird supplies them.
- Keep package/bundle ID `com.vexellab.veil`.
- Use Shorebird Flutter `3.41.1`, matching the project's validated Flutter SDK, for the first release command.
- Do not create or upload a remote Shorebird release during integration verification.

## Workflow

- Validate locally with analyzer, tests, normal Android/iOS/web builds, `shorebird doctor`, and Shorebird release dry runs.
- Create Android/iOS release artifacts with `shorebird release --platforms=android,ios --flutter-version=3.41.1 --build-name=1.0.4 --build-number=10` only after explicit approval.
- Upload the resulting AAB and IPA to Google Play and App Store Connect. Patches work only after those Shorebird-built binaries reach users.
- Publish Dart-only patches with matching build defines and `shorebird patch --platforms=android,ios --release-version=1.0.4+10`.
- Test patches on `staging`, preview them, then promote to stable.
- Never bypass native or asset diff detection for changes users do not already have.

## Verification

- `shorebird doctor` reports no project configuration issues.
- `flutter analyze` and full tests pass.
- Android debug, unsigned iOS debug, and web release builds pass.
- Shorebird release dry run validates Android and iOS without registering a release.
