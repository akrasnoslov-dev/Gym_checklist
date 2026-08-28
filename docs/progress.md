# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; app-code checkpoint is `eeb0346` (`Keep Firebase out of test processes`). XCTest/UI-test and demo processes now bypass Firebase/Crashlytics initialization even when a local plist is installed.
- Current goal: complete the entire originally approved MVP before the next product review. The prior physical-iPhone preview was intermediate only; do not stop or solicit acceptance until the final MVP candidate is ready.
- The app contains the planned Program, Today, Settings, Firebase/auth, offline, Analytics, and Crashlytics paths. Remaining work is to reconcile their real implementation and verification against the approved MVP, fix confirmed gaps, and complete one final broad verification.
- Program week navigation rebuilds only dynamic calendar/content after date changes. Malformed Firestore workout snapshots preserve any cached workout and show a non-blocking unavailable state rather than a false rest day.
- Firestore workout listeners now receive metadata-only updates, so a recovered connection clears the stale sync-unavailable state. A successful cached snapshot, including an empty collection, is usable offline; malformed entries remain non-blocking unavailable state.
- The existing ignored Firebase plist is installed at the app's expected local path. It remains untracked and enables non-test Firebase/Auth/Google composition on a configured device build.
- The previous sideloadable in-memory `MVP_DEMO` artifact is an intermediate preview only and is not the final MVP candidate.

## Verification
- Local whitespace, Firebase-security-hygiene, Firestore-rules, account-deletion, and offline cache/reconnect contracts pass.
- Added focused unit coverage for successful cached snapshot availability and malformed-snapshot fallback.
- Local whitespace, Firebase-security-hygiene, Firestore-rules, account-deletion, Google Sign-In, and release-workflow contracts pass.
- Focused historical-editor rerun `33098518317` and current-head smoke `33151441904` both passed. Security re-review approved the Firebase test-isolation fix.
- Final current-head full `33151994017` failed only at `testAppLaunchesOnTodayAndNavigatesAllTabs` after Next week, the established Program date-selector `KNOWN_UI_TEST_HARNESS_FLAKE`. Do not rerun or alter production behavior without independent product evidence.

## External/deferred
- Real Firebase console setup remains required: create/select a non-production project, deploy `firestore.rules` and `functions:deleteAccount`, enable email/password and Google providers, and validate with non-production accounts. The Firebase CLI is not installed on this host. Real-device validation remains required for cache/reconnect, Google/Apple sign-in, account deletion, Crashlytics, and accessibility.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, paid-release Apple configuration, and `dev -> main` remain deferred.

## Next action
1. User-controlled Firebase/device work: deploy the rules and callable to a non-production project; enable and configure providers; complete the documented two-user isolation, cache→airplane→reconnect, auth/deletion, Crashlytics, and manual accessibility checks on a physical iPhone.
2. Once those validations succeed, produce the completed physical-iPhone candidate for product acceptance. Paid Apple/TestFlight/release work remains deferred.
