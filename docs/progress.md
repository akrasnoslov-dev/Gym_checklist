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
- Do not dispatch it after each individual fix. First batch all runnable implementation, regression review, affected-test updates, documentation, and available static/security/offline checks.
- Dispatch macOS only after the repository is locally exhausted: no known issue or independent active-scope work remains that can reasonably be completed by repository inspection in the current environment.
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
1. Read `33913992158` once at the next task start. If green, update the physical-iPhone IPA workflow to source SHA `648757c569536c9967d7577d28fe1c868a44873b` and prepare the free device candidate; if red, inspect its concise failure summary before editing. Do not produce an IPA unless its focused stage and authoritative full suite are green.
