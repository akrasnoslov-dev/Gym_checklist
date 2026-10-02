# Gym Checklist — Progress Checkpoint

## Current state
- The functional MVP baseline remains implemented; paid Apple distribution/release work is still deferred.
- PR #5 contains the completed Phase 5B design prototype, stabilization harness, final user correction pass, and Phase 8 freeze documentation. It remains open and unmerged.
- **Phase 8 Design Freeze is APPROVED/COMPLETE (2026-10-02).** Frozen visual source: `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- The frozen review registry remains exactly 64 entries: 10 canonical surfaces, 26 states, 28 overlays, 0 QA-only. These are review/test states, not 64 production screens.
- The final correction pass resolves compact-overlay scroll locking, Program state symbols and set-row semantics, focused reorder, and auth-field alignment without adding routes.
- Phase 9 SwiftUI implementation is authorized on a separate implementation branch/PR. `docs/phase9_swiftui_mapping.md` is the implementation handoff.
- Production SwiftUI has not yet been changed by PR #5; its existing authoritative macOS evidence therefore still describes the pre-redesign app only and will be invalidated once Phase 9 production changes begin.

## Latest verification
- Frozen design source `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`: Linux checks run `37013418934` GREEN and Prototype visual regression run `37013419866` GREEN.
- Local Windows/system-Chrome prototype suite: 133 tests GREEN; stabilization contract remains 64 entries (A10/B26/C28/D0).
- Static contracts pass: agentic workflow, iOS CI policy, security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, and release workflow.
- Linux checkpoint `33987425470` passed on docs checkpoint `2286b312e8998c8d7c94e9aa3bda64389da4c78c`, including the exact-source candidate workflow contract.
- PR #3 CI optimization: final Linux run `35870202237` passed on final PR head `6efd51d261fed715ccd0fa2fed965e64c77234fa`. iOS-impacting PRs use automatic `smoke`; process-only changes start no macOS run; manual `full` and exact-SHA `candidate` remain authoritative.
- Authoritative macOS candidate run `33991955146` is **GREEN**. Its `build-and-test` job completed successfully on 2026-09-05, including the candidate build, the exact Program navigation regression, and `candidate-full` after checking out and asserting approved source `e17cb8173a6373059729226453c568e976954d33`.

## Remote gate
- `REMOTE_GATE_APPROVED e17cb8173a6373059729226453c568e976954d33`
- Exact candidate/full verification is complete: macOS run `33991955146` used scope `candidate`, `candidate_source_sha=e17cb8173a6373059729226453c568e976954d33`, and focused filter `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`, followed by the complete suite on that same asserted source.
- No further macOS build/unit/UI/smoke/full verification is required for this candidate. Any future production, test, or project change invalidates this evidence and must follow the two-pass gate policy.

## Remaining external proof
- The one consolidated Spark/device flow is documented in `docs/mvp_external_acceptance_handoff.md`: email/password and Google auth; persistence and two-user isolation; cached offline execution and reconnect; Analytics and Crashlytics where available; accessibility/appearance; and ACC-01 through ACC-09 on the physical iPhone.
- `.github/workflows/mvp-acceptance-ipa.yml` is prepared to build the exact approved source into an unsigned Firebase-backed IPA. It requires the repository secret `GOOGLE_SERVICE_INFO_PLIST_B64`; no acceptance IPA has been produced or dispatched in this checkpoint.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Implement the frozen Phase 8 design in SwiftUI on the separate Phase 9 branch/PR.
2. Complete Pass A implementation/hardening and record `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>`.
3. Stop before Pass B; a later independent task will audit that exact SHA and decide whether to dispatch the single authoritative macOS candidate/full verification.
