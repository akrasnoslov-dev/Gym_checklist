# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; latest app-code checkpoint `cd900ed` (`Dismiss reauthentication sheet after account deletion`); current repository head also includes CI-policy/documentation cleanup.
- Successful Apple/Google deletion reauthentication now dismisses its sheet before routing to the auth screen; failure/cancellation retain the sheet/session.
- Authoritative macOS CI no longer triggers on ordinary pushes. Pushes keep the lightweight Linux checks; macOS verification is explicit via `workflow_dispatch` at justified checkpoints or via pull requests, avoiding misleading skipped macOS workflow records.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- UI diagnostics have been iteratively narrowed around simulator timing/accessibility and account-deletion behavior. macOS UI run `33017028444` targets app checkpoint `cd900ed`; reconcile its final result before further UI/full verification.
- The earlier `40c1c24` UI diagnostic exposed two simulator/Xcode launch failures plus the account-deletion sheet bug fixed by `cd900ed`; launch failures are not treated as app evidence.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Reconcile macOS UI run `33017028444` for `cd900ed`.
2. If it passes, run one current-head macOS `full` verification; if it reports an app/test failure, fix only that narrow surface first. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
