# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current checkpoint `0b8bd7b` (`Stabilize Program week navigation UI assertion`).
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week-navigation UI coverage now checks the stable selected-date label rather than a dynamically refreshed date-cell accessibility node.

## Verification
- Local checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- UI diagnostic `33048456261` on `0b16cf9` completed with 41/42 tests passing. Its sole failure was the Program test's dynamic next-week date-cell lookup; domain calendar tests prove the transition and the assertion is corrected at `0b8bd7b`.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Reconcile macOS `ui` diagnostic `33050237018` for `0b8bd7b`.
2. If it passes, run one current-head macOS `full` verification; if it reports an app/test failure, fix only that narrow surface first. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
