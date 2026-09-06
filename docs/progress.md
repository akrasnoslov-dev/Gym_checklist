# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Approved candidate source: `e17cb8173a6373059729226453c568e976954d33`. The candidate workflow checked out and asserted this immutable SHA before its focused regression and full suite.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`. Xcode scheme XML, source membership, conflict-marker, whitespace, and contrast checks also pass.
- Linux checkpoint `33987425470` passed on docs checkpoint `2286b312e8998c8d7c94e9aa3bda64389da4c78c`, including the exact-source candidate workflow contract.
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
