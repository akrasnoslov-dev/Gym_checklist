# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current checkpoint `f31046f` (`Requery Program date after subtree refresh`).
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week navigation now recreates only its dynamic calendar/content subtrees after a selected-date change, resolving stale `List` rendering/accessibility state.

## Verification
- Local checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- UI diagnostics `33048456261`, `33050237018`, and `33051751121` each completed with 41/42 tests passing. The original stale Program `List` issue is corrected at `4a3eafd`; the final run exposed a stale UI-test element reference after that intentional subtree recreation, corrected at `f31046f`.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Reconcile focused macOS `ui` diagnostic `33053780714` for `f31046f`.
2. If it passes, run one current-head macOS `full` verification; if it reports an app/test failure, fix only that narrow surface first. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
