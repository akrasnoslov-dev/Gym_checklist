# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; implementation/hardening is complete for the approved ACC-01 through ACC-09 physical-iPhone expansion.
- Candidate source: `60c73c3c05e72b29439577a12221af55ae5324b3` hardens local-date BMI refresh, malformed body-weight snapshot preservation, native destructive confirmations, and accessible mint/green contrast. It also expands deterministic migration, Month, Program deletion, and profile/body-weight UI coverage.
- The app remains in **pre-payment functional MVP acceptance**. No billing, paid Apple, TestFlight, App Store, or Blaze work was activated.

## Latest verification
- Static contracts pass: security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and `node --check functions/index.js`.
- `git diff --check` is clean. Windows has no Swift/Xcode toolchain, so simulator/unit/UI execution remains macOS-authoritative.
- `33913992158` was still in progress when inspected once at task start, on obsolete source `648757c569536c9967d7577d28fe1c868a44873b`. Its result cannot validate the newer candidate and is not being polled.

## Remote gate
- `REMOTE_GATE_READY_FOR_AUDIT 60c73c3c05e72b29439577a12221af55ae5324b3`
- This task changed production Swift and tests, so it must not dispatch macOS CI. A separate fresh Pass B task must audit this exact source, make no production/test/project changes, record approval, and only then dispatch one authoritative candidate/full gate.

## Remaining external proof
- After a green exact-SHA gate: Spark email/password and Google auth, Firestore persistence/two-user isolation, offline/reconnect, Analytics, Crashlytics, accessibility/appearance, and physical-iPhone review of every ACC finding.
- Paid-only Apple distribution, live paid Apple capabilities, Blaze/billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Start a separate fresh preflight audit on `60c73c3c05e72b29439577a12221af55ae5324b3`.
2. If it requires no production/test/project changes, record `REMOTE_GATE_APPROVED` and dispatch exactly one macOS candidate/full gate. Otherwise batch fixes, commit/push a new ready-for-audit SHA, and stop again without macOS.
