# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Candidate source: `e17cb8173a6373059729226453c568e976954d33` makes the authoritative candidate gate check out and assert its exact immutable source SHA, with a Linux-enforced workflow contract. This preserves valid proof for the prior Firebase/profile fixes.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`. Xcode scheme XML, source membership, conflict-marker, whitespace, and contrast checks also pass.
- Windows has no Swift/Xcode toolchain, so simulator/unit/UI execution remains macOS-authoritative.
- Obsolete macOS candidate `33913992158` failed only because the Repeat segmented pickers were queried as buttons in `testAppLaunchesOnTodayAndNavigatesAllTabs`; its source `648757c569536c9967d7577d28fe1c868a44873b` cannot validate the current candidate. The assertion is corrected and regression-expanded here.

## Remote gate
- `REMOTE_GATE_READY_FOR_FINAL_AUDIT e17cb8173a6373059729226453c568e976954d33`
- A separate fresh Pass B task must audit this exact source, make no production/test/project changes, record approval, and only then dispatch one authoritative candidate/full gate. If it finds a fix, it continues as Pass A until locally exhausted before recording the next final-audit SHA.

## Remaining external proof
- After a green exact-SHA gate: Spark email/password and Google auth, Firestore persistence/two-user isolation, offline/reconnect, Analytics, Crashlytics, accessibility/appearance, and physical-iPhone review of every ACC finding.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Start a separate fresh final audit on `e17cb8173a6373059729226453c568e976954d33`.
2. If it requires no production/test/project changes, record `REMOTE_GATE_APPROVED` and dispatch exactly one macOS candidate/full gate. Otherwise continue Pass A local hardening through exhaustion, then commit/push a new final-audit SHA without macOS.
