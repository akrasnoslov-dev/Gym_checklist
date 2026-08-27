# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current code checkpoint `2fd5fc1` (`Preserve cached workouts on malformed snapshots`).
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week navigation now recreates only its dynamic calendar/content subtrees after a selected-date change, resolving stale `List` rendering/accessibility state.
- A malformed Firestore workout document now retains any cached workout for that same date and presents non-blocking unavailable state instead of erasing Today into a false rest day.

## Verification
- Local checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, and offline cache/reconnect contracts.
- Added regression coverage for populated Program week navigation and malformed Firestore snapshot cache preservation.
- Focused macOS UI diagnostic `33053780714` remains in progress for predecessor `f31046f`; it does not cover `2fd5fc1`.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Push `2fd5fc1` and dispatch one current-head macOS `full` verification after the focused predecessor diagnostic completes or is superseded.
2. If the full run reports an app/test failure, fix only that narrow surface first. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
