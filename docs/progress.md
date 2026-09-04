# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; the user approved the 2026-09-04 post-acceptance scope expansion (profile/body weight/BMI, set types, repeat cadence, Month view, and the listed visual hierarchy work). It supersedes the former scope freeze for those items.
- The locally reviewed checkpoint classifies legacy timed placeholders (`reps <= 1`, `weight = 0`, `time > 0`) as timed while preserving meaningful mixed records, including plan/actual decode-re-save and copy/repeat/add-set. Legacy mixed editors expose their meaningful fields without exposing legacy mixed as a selectable new-set type. Week/Month is deterministically Monday-first; Copy/Repeat primary labels are exactly `Copy` and `Create`.
- Current phase remains **pre-payment functional MVP acceptance**: no billing, paid Apple, TestFlight, App Store, or Blaze work.

## Latest verification
- Previous-scope evidence only: IPA run `33262381993` is green; it built source `ee579d0`. That workflow currently hard-codes this old source and must be updated only after the new final candidate SHA exists.
- Current static checks: whitespace, Google Sign-In configuration, account deletion, Firestore owner rules, offline cache/reconnect, release workflow, and security hygiene all pass. Windows has no local Swift/Xcode toolchain.
- `33907241126` is terminal red on `4de834602968e4d2658799e4047c3ae3565a9257`: candidate build and the focused legacy migration test passed, but full suite found two regressions. `SetDisplayFormatterTests.testCompactDisplayRules` exposed the legacy timed `1 rep/0 kg/time` placeholder misclassification; `GymChecklistUITests.testAppLaunchesOnTodayAndNavigatesAllTabs` retained Sunday-first headers despite correct Monday-first production behavior. Both are corrected with explicit regression coverage, alongside the related legacy editor audit.
- `CI_PENDING 33913992158`: `candidate` scope on exact source SHA `648757c569536c9967d7577d28fe1c868a44873b`, using `GymChecklistTests/ExpandedFeatureTests/testLegacyTimedPlaceholdersInferTimedWhileMeaningfulRepTimeValuesRemainMixed`. It builds once, runs that focused compatibility regression, then runs the full suite on the same SHA. Do not poll from this task.
- No new physical-iPhone IPA should be produced until the expanded checkpoint is implementation-complete and a green authoritative candidate/full result exists on its exact SHA.

## CI operating rule
- macOS/Xcode CI is a final/expensive remote gate, not the normal development loop.
- A task that changes production/test/project code must **not** dispatch macOS in that task. It must finish the batch, commit/push, record `REMOTE_GATE_READY_FOR_AUDIT <SHA>`, and stop.
- A separate fresh task must audit that exact SHA. If it finds anything requiring production/test/project code changes, it fixes/batches them, records a new ready-for-audit SHA, and stops again without macOS.
- Only a clean fresh audit with no production/test/project code changes may record `REMOTE_GATE_APPROVED <SHA>` and dispatch one candidate/full gate.
- Any red candidate revokes approval and forces the two-pass process again.
- Do not dispatch it after each individual fix. First batch all runnable implementation, regression review, affected-test updates, documentation, and available static/security/offline checks.
- Local exhaustion is required but is not sufficient without the clean fresh audit pass.
- Use focused `unit`/`ui` only when one isolated compiler/runtime/test behavior is genuinely the remaining blocker.
- Use `candidate` only for an implementation-complete checkpoint intended to become the next physical-acceptance candidate.
- After a red run, inspect once, batch all related fixes and review the same defect class across the repository, then return to local development; do not immediately launch a replacement candidate after one small edit.
- Do not separately run smoke before a justified final candidate/full gate.
- After dispatch, record run ID/scope/SHA and never poll merely to keep Codex alive.

## Free live-validation scope
Live Spark/device proof remains: email/password auth/reset/logout, Google Sign-In, Firestore persistence and two-user isolation, relaunch, offline cache/reconnect, Analytics, Crashlytics, accessibility, and free personal-device installation. This Windows workspace has neither an authenticated Firebase CLI nor Xcode; do not infer live proof from static contracts. The single prepared handoff is `docs/mvp_external_acceptance_handoff.md`.

## Paid/deferred
Apple Developer Program, TestFlight/App Store, paid release signing/secrets, Firebase Blaze/billing, live Cloud Function deployment if Blaze is required, paid-only Apple configuration, final release work, and `dev -> main`.

## Next action
1. Let current run `33913992158` finish; do not dispatch any additional macOS run from the current implementation task.
2. If it is red, inspect it once, batch all fixes and all remaining runnable acceptance work, commit/push, record `REMOTE_GATE_READY_FOR_AUDIT <SHA>`, and stop without macOS.
3. Start a separate fresh preflight-audit task on that SHA. Only if the audit requires no production/test/project changes may it record `REMOTE_GATE_APPROVED <SHA>` and dispatch one candidate/full gate.
4. If `33913992158` is green, it remains valid evidence for its exact SHA; proceed toward the physical-iPhone candidate without another redundant macOS run.
