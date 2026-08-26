# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; latest checkpoint `1766819` (`Stabilize accessibility-based UI assertions`); a follow-up UI-test stabilization is uncommitted.
- The follow-up makes history fixtures deterministic with a DEBUG-only test selected date, separately verifies week navigation with fresh date-button queries, scopes SwiftUI error assertions to their unique `StaticText` nodes, and waits for appearance state propagation.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- Latest macOS UI diagnostic `33012722131` failed at `4f4338b`: all prior reported assertions passed; its sole failure was a cached SwiftUI week-header label predicate after a verified week-control tap. The current test-only change replaces that fragile predicate with fresh date-button queries.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Commit the UI-test follow-up and run one macOS `ui` diagnostic.
2. If it passes, run one current-head macOS `full` verification; otherwise fix only the reported UI surface.
