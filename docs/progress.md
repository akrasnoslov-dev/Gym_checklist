# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; latest app-code checkpoint `09b1053` (`Keep valid Firestore workouts on malformed snapshots`); autonomous MVP work remains active.
- Current coherent changes preserve completed-set actual values/timestamps across Today skip → restore and correct the corresponding unit/UI regressions.
- Local Firebase configuration is now copied from the ignored `GymChecklist/GoogleService-Info.plist` only for configured app builds; its Google callback URL scheme is derived at build time without tracking or printing configuration.
- Firestore snapshot handling now retains valid workouts when a sibling document is malformed, while an entirely invalid non-empty snapshot remains unavailable.
- Product, UX, architecture, Firebase/persistence, security/privacy, code-quality, and CI reviews completed. The only fixed P1 finding was skip → restore data loss.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- Authoritative macOS full run `32986107333` is queued for app checkpoint `09b1053`; prior queued run `32985688991` targets pre-fix `3e2e0cd` and is not current evidence.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Reconcile macOS `full` run `32986107333` for `09b1053` under `AGENTS.md`.
2. If it passes, continue only the remaining external/device validation; if it fails, diagnose its narrow failing surface before a new `full` run.
