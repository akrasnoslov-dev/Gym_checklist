# Gym Checklist — Current State

History lives in `git log` and Linear (team GYM). This file holds only the current state and the next step (≤ 40 lines).

## Current state (2026-11-19)

- MVP flow is implemented on `dev`. Not on TestFlight/App Store; paid Apple distribution and Firebase billing remain deferred until explicitly approved.
- PR #10 (persistence reliability) is merged into `dev` (`f8f3491`). The user ran iPhone review №4 on that build; findings are Linear GYM-21 and its sub-issues.
- Known production blocker: the Firestore rules deployed to "GymChecklist Dev" lack the `bodyWeightMeasurements` match, so body-weight writes are rejected (GYM-22).
- PR #26 (GYM-22 + GYM-9 + GYM-12, in review): Firestore failure diagnostics (os_log + Crashlytics), validated rules tested on the emulator with the client's exact payloads, body-weight listener errors surfaced, rules deploy/drift procedure in `docs/firestore_security.md`.
- Data-layer audit follow-ups: GYM-13, GYM-37, GYM-38, GYM-39, GYM-40.
- Other work runs as separate PRs into `dev`.

## Gate

Green required CI on the exact PR head SHA + the relevant checklist. No gate-recording docs commits. See `CHATGPT_PROJECT_SOURCE.md`.

## Next step

1. Merge PR #26 into `dev` (user approval), then deploy `firestore.rules` from `dev` with explicit user approval and run `scripts/check_deployed_firestore_rules.ps1`.
2. Preview IPA from `dev`; user checks on iPhone that body weight saves and survives a restart.
3. GYM-25 / GYM-26 / GYM-27: design-consistency fixes from iPhone review №4.

`dev -> main` only with explicit user approval.
