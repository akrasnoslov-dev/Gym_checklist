# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current code checkpoint `ae7a64c` (`Stabilize Program navigation date query`).
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week navigation now recreates only its dynamic calendar/content subtrees after a selected-date change, resolving stale `List` rendering/accessibility state.
- A malformed Firestore workout document now retains any cached workout for that same date and presents non-blocking unavailable state instead of erasing Today into a false rest day.

## Verification
- Local checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, and offline cache/reconnect contracts.
- Added regression coverage for populated Program week navigation and malformed Firestore snapshot cache preservation.
- Full macOS verification `33054548821` compiled and ran 42 UI tests for `bd2274e`, with one failure in `GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`: the recreated Program date accessibility element no longer matched the `StaticText` query. `ae7a64c` now requeries it as an unconstrained accessibility descendant.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Push `ae7a64c` and run the focused macOS UI diagnostic `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`.
2. If it passes, run one current-head macOS `full` verification; otherwise fix only the reported narrow surface. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
