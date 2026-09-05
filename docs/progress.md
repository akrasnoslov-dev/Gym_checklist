# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Candidate source: `306d36a120894065e2ffa7ea4eef6a10513aaac2` fixes preflight findings: the stale Repeat segmented-control UI assertion, Firestore persistence when cleared profile fields are merged, Today execution-type preservation, zero-weight display, Copy/Repeat action sizing, dark-mode semantic contrast, and numeric display overflow. Deterministic regression coverage was added for the affected behavior.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`. Xcode scheme XML, source membership, conflict-marker, whitespace, and contrast checks also pass.
- Windows has no Swift/Xcode toolchain, so simulator/unit/UI execution remains macOS-authoritative.
- Obsolete macOS candidate `33913992158` failed only because the Repeat segmented pickers were queried as buttons in `testAppLaunchesOnTodayAndNavigatesAllTabs`; its source `648757c569536c9967d7577d28fe1c868a44873b` cannot validate the current candidate. The assertion is corrected and regression-expanded here.

## Remote gate
- `REMOTE_GATE_READY_FOR_AUDIT 306d36a120894065e2ffa7ea4eef6a10513aaac2`
- This task changed production Swift and tests, so it must not dispatch macOS CI. A separate fresh Pass B task must audit this exact source, make no production/test/project changes, record approval, and only then dispatch one authoritative candidate/full gate.

## Remaining external proof
- After a green exact-SHA gate: Spark email/password and Google auth, Firestore persistence/two-user isolation, offline/reconnect, Analytics, Crashlytics, accessibility/appearance, and physical-iPhone review of every ACC finding.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Start a separate fresh preflight audit on `306d36a120894065e2ffa7ea4eef6a10513aaac2`.
2. If it requires no production/test/project changes, record `REMOTE_GATE_APPROVED` and dispatch exactly one macOS candidate/full gate. Otherwise batch fixes, commit/push a new ready-for-audit SHA, and stop again without macOS.
