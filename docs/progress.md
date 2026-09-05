# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Candidate source: `e17cb8173a6373059729226453c568e976954d33` makes the authoritative candidate gate check out and assert its exact immutable source SHA, with a Linux-enforced workflow contract. This preserves valid proof for the prior Firebase/profile fixes.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`. Xcode scheme XML, source membership, conflict-marker, whitespace, and contrast checks also pass.
- Linux checkpoint `33987425470` passed on docs checkpoint `2286b312e8998c8d7c94e9aa3bda64389da4c78c`, including the exact-source candidate workflow contract.
- Windows has no Swift/Xcode toolchain, so simulator/unit/UI execution remains macOS-authoritative.
- Obsolete macOS candidate `33913992158` failed only because the Repeat segmented pickers were queried as buttons in `testAppLaunchesOnTodayAndNavigatesAllTabs`; its source `648757c569536c9967d7577d28fe1c868a44873b` cannot validate the current candidate. The assertion is corrected and regression-expanded here.

## Remote gate
- `REMOTE_GATE_APPROVED e17cb8173a6373059729226453c568e976954d33`
- macOS run `33991955146` is dispatched with scope `candidate`, `candidate_source_sha=e17cb8173a6373059729226453c568e976954d33`, and focused filter `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`; the workflow checks out and asserts that source before its focused and full suite.

## Remaining external proof
- After a green exact-SHA gate: Spark email/password and Google auth, Firestore persistence/two-user isolation, offline/reconnect, Analytics, Crashlytics, accessibility/appearance, and physical-iPhone review of every ACC finding.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Do not poll `33991955146`; at the next task, read its result once.
2. A green candidate result is the required exact-source full evidence; a red result restarts Pass A.
