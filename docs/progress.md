# Gym Checklist — Current State

History lives in `git log` and Linear (team GYM). This file holds only the current state and the next step (≤ 40 lines).

## Current state (2026-11-18)

- MVP flow is implemented on `dev`. Not on TestFlight/App Store; paid Apple distribution and Firebase billing remain deferred until explicitly approved.
- PR #10 (persistence reliability) is merged into `dev` (`f8f3491`). The user ran iPhone review №4 on that build; findings are Linear GYM-21 and its sub-issues.
- Known production blocker: the Firestore rules deployed to the Firebase project lack the `bodyWeightMeasurements` match that `firestore.rules` in the repo has, so body-weight writes are rejected (GYM-22). Deploying rules requires explicit user approval.
- Other work runs as separate PRs into `dev`.

## Gate

Green required CI on the exact PR head SHA + the relevant checklist. No gate-recording docs commits. See `CHATGPT_PROJECT_SOURCE.md`.

## Next step

1. GYM-22 + GYM-9: error diagnostics for rejected writes, validated rules, deploy the repo rules with user approval.
2. GYM-16 / GYM-25 / GYM-26 / GYM-27: UI review and design-consistency fixes from iPhone review №4.
3. Re-run CI on the exact SHA, build a preview IPA, user re-checks against `docs/mvp_acceptance_checklist.md`.

`dev -> main` only with explicit user approval.
