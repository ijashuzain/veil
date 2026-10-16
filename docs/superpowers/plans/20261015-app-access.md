# App Access Implementation Plan

**Goal:** Dashboard-managed maintenance and minimum-build gates.

**Architecture:** A public-read, admin-write singleton config row feeds a cached
repository. A root gate above the router checks on launch/resume and renders
maintenance before update. Package metadata supplies the installed build.

**Constraints:** Default maintenance off and minimum builds zero. Read-only RLS
for anon/authenticated clients. Six-hour cache on network failure; no cache means
allow. Store URLs restricted to platform store hosts. Web gets maintenance only.
No automatic app version bump or activation of blocking settings.

## Tasks
- Add `app_access_config.dart` for validated config and platform decisions.
- Add `app_access_repository.dart` for five-second remote timeout and cached JSON.
- Add `app_access_gate.dart` above the router; remove underlying app while blocked,
  retry every minute while blocked, and expose Retry and Update actions.
- Move initial ad consent initialization behind successful access check.
- Add singleton SQL migration with safe defaults and public SELECT only.
- Test precedence, platform builds, malformed/expired cache, recovery, store
  launch failure, non-dismissible UI, and launch/resume behavior.
- Run focused Flutter tests and analysis, inspect database push dry-run, then
  apply only the new migration and document dashboard operations.
