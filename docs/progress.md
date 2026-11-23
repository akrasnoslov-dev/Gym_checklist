# Gym Checklist — Current State

History lives in `git log` and Linear (team GYM). This file holds only the current state and the next step (≤ 40 lines).

## Current state (2026-11-23)

- **MVP stage complete.** The user accepted the functional MVP on 2026-11-23 after iPhone check №6 (GYM-46) on the preview IPA built from `dev` `cd0beed` (run 44751569183).
- All MVP and audit issues in Linear (team GYM) are Done or Canceled; nothing in the MVP backlog stays open.
- Live Firestore rules match `dev` (daily drift check `firestore-rules-drift.yml` is green).
- `main` still holds only the init commit; the accepted MVP lives on `dev`.
- Deferred to the next stage (each needs an explicit user decision): Apple Developer Program, TestFlight/App Store, paid signing, Blaze billing, `functions:deleteAccount` deployment, live Sign in with Apple.

## Gate

Green required CI on the exact PR head SHA + the relevant checklist. No gate-recording docs commits. See `CHATGPT_PROJECT_SOURCE.md`.

## Next step

1. GYM-50: full iOS CI on the `dev` head, then `dev -> main` (explicit user approval required) and tag `mvp-1.0`.
2. GYM-51: delete merged branches, settle dependabot branches, archive stale MVP-acceptance docs.
3. Plan the next stage (distribution or new features) with the user.

`dev -> main` only with explicit user approval.
