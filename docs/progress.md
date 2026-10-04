# Gym Checklist — Progress Checkpoint

## Current state
- The functional MVP baseline remains implemented; paid Apple distribution/release work is still deferred.
- PR #5's completed Phase 5B design prototype, stabilization harness, final correction pass, and Phase 8 freeze documentation are merged into `dev`.
- **Phase 8 Design Freeze is APPROVED/COMPLETE (2026-10-02).** Frozen visual source: `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- The frozen review registry remains exactly 64 entries: 10 canonical surfaces, 26 states, 28 overlays, 0 QA-only. These are review/test states, not 64 production screens.
- The final correction pass resolves compact-overlay scroll locking, Program state symbols and set-row semantics, focused reorder, and auth-field alignment without adding routes.
- **Phase 9 Pass A is complete on PR #6 / `codex/phase-9-swiftui-implementation`.** The branch merged current `dev` through `3f2c28c`, keeps the existing focused native Program reorder flows, applies the frozen completion artwork/copy to Today, and fixes the corresponding accessibility/UI-test coverage.
- `docs/phase9_swiftui_mapping.md` remains the implementation handoff. The frozen review registry remains design evidence only; it does not create 64 production routes.
- Production SwiftUI changed in Phase 9, so the prior authoritative macOS evidence applies only to the pre-redesign source and is not approval for this candidate.

## Latest verification
- Frozen design source `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`: Linux checks run `37013418934` GREEN and Prototype visual regression run `37013419866` GREEN.
- Local Windows/system-Chrome prototype suite: 133 tests GREEN; stabilization contract remains 64 entries (A10/B26/C28/D0).
- Static contracts pass: agentic workflow, iOS CI policy, security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, and release workflow.
- Phase 9 Pass A static evidence on candidate `4526513a8e9fd855cff55cada9c7cbb8ef8fe67a`: `git diff --check`; the eight static contracts above; `node --check functions/index.js`; and completion asset-catalog JSON/path validation are GREEN. Required UX, product, test/CI, and independent code reviews are GREEN after fixes.
- `xcodebuild`, XCTest, and UI tests are unavailable on the Windows host. No macOS smoke/candidate/full workflow was dispatched in this Pass A task.
- Linux checkpoint `33987425470` passed on docs checkpoint `2286b312e8998c8d7c94e9aa3bda64389da4c78c`, including the exact-source candidate workflow contract.
- PR #3 CI optimization: final Linux run `35870202237` passed on final PR head `6efd51d261fed715ccd0fa2fed965e64c77234fa`. iOS-impacting PRs use automatic `smoke`; process-only changes start no macOS run; manual `full` and exact-SHA `candidate` remain authoritative.
- Authoritative macOS candidate run `33991955146` is **GREEN**. Its `build-and-test` job completed successfully on 2026-09-05, including the candidate build, the exact Program navigation regression, and `candidate-full` after checking out and asserting approved source `e17cb8173a6373059729226453c568e976954d33`.

## Remote gate
- `REMOTE_GATE_READY_FOR_FINAL_AUDIT 4526513a8e9fd855cff55cada9c7cbb8ef8fe67a`
- This replaces the pre-redesign candidate's approval for Phase 9. Do not dispatch macOS verification in this task.
- A fresh independent Pass B audit must start from exactly this SHA. It may run local/static checks again; if it changes production/test/project code, it returns to Pass A with a new recorded SHA. Only a clean Pass B may request one justified candidate/full macOS gate.

## Remaining external proof
- The consolidated Spark/device flow remains documented in `docs/mvp_external_acceptance_handoff.md`, but must use the eventual Phase 9 remote-gate-approved source rather than the pre-redesign candidate.
- `.github/workflows/mvp-acceptance-ipa.yml` remains prepared to build an exact approved source into an unsigned Firebase-backed IPA. It requires the repository secret `GOOGLE_SERVICE_INFO_PLIST_B64`; no acceptance IPA has been produced or dispatched in this checkpoint.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Stop at `REMOTE_GATE_READY_FOR_FINAL_AUDIT 4526513a8e9fd855cff55cada9c7cbb8ef8fe67a`.
2. A later independent task performs Pass B from that exact SHA and decides whether the single authoritative macOS candidate/full verification is justified.
3. Do not merge PR #6 during either Pass A or Pass B without the user's explicit approval.
