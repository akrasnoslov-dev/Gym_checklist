# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Approved candidate source: `e17cb8173a6373059729226453c568e976954d33`. The candidate workflow checked out and asserted this immutable SHA before its focused regression and full suite.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.
- UI/UX redesign now proceeds separately from production implementation: use the current-app audit plus `docs/ui_research_phase4.md` to create the Phase 5 final candidate. Historical reconstruction and reconciliation phases are cancelled. Do not change SwiftUI until the design is approved and frozen.
- Phase 5B Minimal Grouped full-candidate prototype is prepared for Phase 6 user review in `design/prototype/`; it has not been approved/frozen and does not change production SwiftUI.
- Phase 5B’s Phase 6 feedback correction pass is in review on PR #5: prototype/docs only, preserving the SwiftUI/Xcode/iOS-test surface. It adds reachable Today/Program editing, semantic calendars, Gallery review mode, and Light/Dark browser QA; no macOS CI is applicable or dispatched.
- Phase 7 correction work remains in PR #5: it adds scalable multi-skipped Today state, clear calendar/tab intent, three bundled completion-card variants, contextual Program paths, copied-value Add set, weighted/reps-only/timed sets, expanded Copy/Repeat DatePicker intent, and inline Settings preferences.
- The candidate’s Phase 7 contract is GREEN at 66 routes. Browser QA covered normal interaction plus every then-existing 390 × 844 Gallery frame in Light/Dark, exercise-picker search/scroll, one-tap completion and editor routing, expanded date-picker states, and automated overflow/metadata placement assertions. The final Week/Month-selected and reorder additions reuse those components and passed all three specialist reviews; a fresh computer-use browser session could not reopen the local preview because the client returned `ERR_BLOCKED_BY_CLIENT`, while the local server returned HTTP 200. The candidate remains unapproved until final user review / Phase 8 Design Freeze.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`. Xcode scheme XML, source membership, conflict-marker, whitespace, and contrast checks also pass.
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
1. Complete the single Spark + physical-iPhone acceptance flow using the exact candidate source and return one sanitized result. If the repository secret is confirmed available, dispatch the prepared acceptance-IPA workflow once; otherwise use the documented Xcode Personal Team path.
