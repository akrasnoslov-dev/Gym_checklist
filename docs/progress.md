# Gym Checklist — Current State

History lives in `git log` and Linear (team GYM). This file holds only the current state and the next step (≤ 40 lines).

## Current state (2026-11-18)

- MVP flow is implemented on `dev`. Not on TestFlight/App Store; paid Apple distribution and Firebase billing remain deferred until explicitly approved.
- PR #10 (persistence reliability) is frozen: it waits for a single manual pass by the user on a physical iPhone, following the "Final iPhone review script" in `docs/mvp_acceptance_checklist.md` (lands in `dev` with PR #10).
- Other work runs as separate draft PRs into `dev`; nothing merges until that review is done.

## Gate

Green required CI on the exact PR head SHA + the relevant checklist. No gate-recording docs commits. See `CHATGPT_PROJECT_SOURCE.md`.

## Next step

1. User runs the Final iPhone review script once on the PR #10 build.
2. Every finding becomes an issue in Linear team GYM.
3. Fix the findings in one batch, re-run CI on the exact SHA, re-check against the checklist.

`dev -> main` only with explicit user approval.
