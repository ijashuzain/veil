# Playback interstitial ads

Player 1 and Player 2 share a device-local, persisted 30-minute frequency cap.
The common native playback launcher also applies this cap to Continue Watching.
In-player episode switches do not trigger ads.

After existing consent initialization permits ads, preload an interstitial. At
playback entry, show only an already loaded, unexpired ad. Wait for dismissal
before opening playback. Failed presentation or missing inventory allows playback
immediately. Only successful presentation records the cooldown timestamp.
Concurrent native launch attempts are rejected while the first launch is pending.

Release defaults:
- Android: `ca-app-pub-9567183629579117/7093007985`
- iOS: `ca-app-pub-9567183629579117/4878917348`

Overrides: `ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID` and
`ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID`. Non-release builds use Google's test units.
Existing platform app IDs already match the supplied app IDs.

Verification: cooldown boundary, persistence, clock rollback, disabled behavior,
unit selection, and existing native selection/navigation tests. Real-device ad
presentation still requires an online device with eligible consent.
