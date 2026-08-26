# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current uncommitted checkpoint stabilizes the remaining macOS UI assertions without changing app behavior.
- Program history/weight tests now wait for the Program screen, use existing accessibility identifiers/values, and reveal lazily-instantiated list content before asserting it. Authentication tests now assert their labeled feedback elements rather than unavailable nested text nodes.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- Latest macOS UI diagnostic `32987228619` failed at `22c79ad` after build/unit coverage, in Program list/accessibility assertions and labeled authentication feedback assertions. The current fix targets those reported UI-test surfaces.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Commit the UI-test stabilization checkpoint and run one macOS `ui` diagnostic.
2. If it passes, run one current-head macOS `full` verification; otherwise fix only the reported UI surface.
