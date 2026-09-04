# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; the user approved the 2026-09-04 post-acceptance scope expansion (profile/body weight/BMI, set types, repeat cadence, Month view, and the listed visual hierarchy work). It supersedes the former scope freeze for those items.
- Working checkpoint fixes the red candidate’s real defects: legacy mixed rep/weight/time documents retain raw plan and actual values through Firestore decode/re-save, current body weight is selected by applicable local date, and Program Week/Month is deterministically Monday-first. It also replaces generic Copy/Repeat forms and the top-level Settings list with the approved card hierarchy.
- Current phase remains **pre-payment functional MVP acceptance**: no billing, paid Apple, TestFlight, App Store, or Blaze work.

## Latest verification
- Previous-scope evidence only: IPA run `33262381993` is green; it built source `ee579d0`. That workflow currently hard-codes this old source and must be updated only after the new final candidate SHA exists.
- Current static checks: Firestore owner-rule and offline cache/reconnect contracts pass. Windows has no local Swift/Xcode toolchain.
- `33885092391` is terminal red on `756b75568cd7e015a52d0159e0b5087f28b1ffe9`. It failed during `candidate-build` before tests because the legacy-migration tuple branches in `DomainModels.swift` produced an unnamed `(Int, Double, Int)` tuple that was later accessed as `.reps/.weight/.timeSeconds`.
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
1. Resume from the live `dev` head and fix the `756b755` compile errors in the legacy-set migration without weakening the intended backward compatibility.
2. Before any new macOS dispatch, finish the whole remaining expanded-acceptance batch: audit ACC-01 through ACC-09, verify explicit Copy/Repeat labels and visual requirements, review legacy-set migration/body-weight/calendar changes for related defects, update stale tests, and run every available static/security/offline check.
3. Only when that checkpoint is locally exhausted, commit/push it and dispatch one justified `candidate` run using the legacy migration regression filter; record its exact SHA/run ID.
