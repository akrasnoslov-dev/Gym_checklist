# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; latest app-code checkpoint `cd900ed` (`Dismiss reauthentication sheet after account deletion`); current repository head also includes CI-policy/documentation cleanup.
- Successful Apple/Google deletion reauthentication now dismisses its sheet before routing to the auth screen; failure/cancellation retain the sheet/session.
- Authoritative macOS CI no longer triggers on ordinary pushes. Pushes keep the lightweight Linux checks; macOS verification is explicit via `workflow_dispatch` at justified checkpoints or via pull requests, avoiding misleading skipped macOS workflow records.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- UI diagnostic `33017028444` reached the current app checkpoint `cd900ed`: 40/42 tests passed. The two failures are test-fixture/accessibility-selector defects, corrected locally by fixing the Program initial date and querying the account-deletion error by its actual accessibility element.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Run one macOS `ui` diagnostic for the current test correction.
2. If it passes, run one current-head macOS `full` verification; if it reports an app/test failure, fix only that narrow surface first. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
