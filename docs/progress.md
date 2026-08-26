# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; autonomous MVP work remains active.
- Current coherent changes preserve completed-set actual values/timestamps across Today skip → restore and correct the corresponding unit/UI regressions.
- Local Firebase configuration is now copied from the ignored `GymChecklist/GoogleService-Info.plist` only for configured app builds; its Google callback URL scheme is derived at build time without tracking or printing configuration.
- Product, UX, architecture, Firebase/persistence, security/privacy, code-quality, and CI reviews completed. The only fixed P1 finding was skip → restore data loss.

## Verification
- Local checks pass: whitespace, Firebase security hygiene, Firestore rules, account-deletion, offline, and Google Sign-In configuration contracts.
- Authoritative macOS full run `32985688991` is queued for pre-fix `3e2e0cd`; it does not verify the current changes. A fresh full run is required after this checkpoint is pushed.

## External/deferred
- Real device validation remains required for Google sign-in/cancel/failure, Firestore owner isolation/offline reconnect, Crashlytics, accessibility, account deletion, and the physical-iPhone MVP pass.
- Paid Apple membership, App Store Connect/TestFlight, release signing/secrets, final icon, and paid-release Apple configuration remain deferred.

## Next action
1. Push the coherent checkpoint and run one macOS `full` verification for it.
2. While it runs, continue any independent active-MVP fixes found by review; otherwise reconcile the result under `AGENTS.md`.
