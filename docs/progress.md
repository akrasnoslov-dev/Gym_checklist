# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current code checkpoint `64db123` (`Refresh Program list after date navigation`).
- Apple/Google deletion reauthentication dismisses its sheet before routing to auth; failure/cancellation retain the sheet/session.
- Program week navigation now recreates only its dynamic calendar/content subtrees after a selected-date change, resolving stale `List` rendering/accessibility state.
- A malformed Firestore workout document now retains any cached workout for that same date and presents non-blocking unavailable state instead of erasing Today into a false rest day.

## Verification
- Local checks pass: whitespace plus Firebase security hygiene, Firestore rules, account-deletion, and offline cache/reconnect contracts.
- Added regression coverage for populated Program week navigation and malformed Firestore snapshot cache preservation.
- Full macOS verification `33054548821` compiled and ran 42 UI tests for `bd2274e`, with one Program navigation failure. The focused UI rerun `33056401754` confirmed the selected-date content itself stayed stale after changing weeks. `64db123` now recreates the full Program `List` for date changes; the regression test covers populated -> empty week -> populated navigation and reacquires recreated controls.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Push `64db123` and rerun the focused macOS UI diagnostic `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`.
2. If it passes, run one current-head macOS `full` verification; otherwise fix only the reported narrow surface. Treat pure simulator/Xcode launch failures as infrastructure evidence, not product regressions.
