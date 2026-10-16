# Force update and maintenance controls

## Dashboard location

Open https://supabase.com/dashboard/project/verlsbmdqggejpfmvzue/editor and select
the **public.app_config** table. Edit its single row (`id = true`) and save.
The table and default row have been deployed. Public app clients can only read
the row; writes are restricted to database administrators/service role.

| Field | Usage |
| --- | --- |
| `maintenance_enabled` | Set `true` to block access, `false` to reopen the app. |
| `maintenance_message` | Message displayed on the maintenance screen. |
| `android_min_build` | Lowest Android build allowed; `0` disables force update. |
| `ios_min_build` | Lowest iOS build allowed; `0` disables force update. |
| `android_store_url` | HTTPS Google Play listing URL. |
| `ios_store_url` | HTTPS App Store listing URL; fill this before enabling iOS force update. |

Current safe defaults: maintenance disabled and both minimum builds `0`.
Android URL uses `com.vexellab.veil`. Confirm the listing is available before
raising the minimum. iOS URL is intentionally empty because the App Store
numeric app ID has not been supplied. SQL constraints require a store URL when
its minimum build is greater than zero.

## Build numbers

Compare build numbers, not marketing versions. For `version: 1.1.0+12`, installed
build is **12** unless overridden by the build command. A minimum of **13** blocks
12 and allows 13 or later. Android and iOS have independent settings. Keep build
numbers integer and monotonically increasing. Shorebird patches do not change
the installed store build number.

Publish the replacement build and confirm store availability before raising the
minimum. To roll back a forced update, set its minimum to `0` or a lower build.

## Runtime behavior

- Check at startup before mounting app routes or starting ad consent/loading.
- Check again on app resume; no continuous polling while ordinary app content
  is active. While blocked and foregrounded, retry automatically every minute.
- Maintenance has priority over force update, including on web/desktop.
- Force update applies only to Android/iOS; web/desktop use their normal update
  process.
- Blocking screens have Retry, no dismiss action, and Update when appropriate.
  The app/router subtree is removed while blocked, disposing active players.
- Update opens the platform store externally; returning to Veil rechecks config.
- Network failure uses the last successful configuration for up to six hours.
  Expired/malformed cache or offline first launch permits access. This is a UI
  availability gate, not server-side authorization or an offline-proof lock.
- Invalid store URLs or unavailable build metadata do not trap users behind an
  unusable update screen. Metadata is retried on the next access check.

## Rollout and verification

Rebuild the app after adding `package_info_plus`; hot reload alone cannot register
the new native plugin. These controls affect only app versions containing this
integration. Previously shipped versions without the gate cannot be blocked by
this table.

Tests: `flutter test test/app_access_test.dart` (11 passing checks covering
platform decisions, cache expiry, recovery, blocking, store errors and resume).
Startup/login smoke checks also pass. Existing signup tests hit the previously
observed Flutter ListTile/DecoratedBox assertion. Project analysis retains its
three existing `unawaited_return_in_try_block` warnings.

Live database verification confirmed anonymous reads return the disabled default
row. Maintenance and force update have not been enabled against production users.
