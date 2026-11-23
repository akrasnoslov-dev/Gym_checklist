# Gym Checklist — Current State

History lives in `git log` and Linear (team GYM). This file holds only the current state and the next step (≤ 40 lines).

## Current state (2026-11-23)

- **MVP stage complete and released to `main`.** The user accepted the functional MVP on 2026-11-23 after iPhone check №6 (GYM-46).
- `main` = `51dcdaf`, tag [`mvp-1.0`](https://github.com/akrasnoslov-dev/Gym_checklist/releases/tag/mvp-1.0). Full iOS CI (unit + full UI suite) passed on the exact source `94e1780` (run 45171342638) (GYM-50).
- After acceptance, the release review fixed: Gregorian dates under any iOS system calendar, sign-out after account deletion, and the native set-reorder UI test.
- Repository cleaned up (GYM-51): only `main` and `dev` on the remote; stale MVP-acceptance docs in `docs/archive/`.
- Live Firestore rules match `dev` (daily drift check `firestore-rules-drift.yml` is green).
- All Linear issues (team GYM) are Done or Canceled.
- Deferred to the next stage (each needs an explicit user decision): Apple Developer Program, TestFlight/App Store, paid signing, Blaze billing, `functions:deleteAccount` deployment, live Sign in with Apple.

## Gate

Green required CI on the exact PR head SHA + the relevant checklist. No gate-recording docs commits. See `CHATGPT_PROJECT_SOURCE.md`.

## Next step

1. Plan the next stage with the user (distribution or new features); work continues on `dev`.

`dev -> main` only with explicit user approval.
