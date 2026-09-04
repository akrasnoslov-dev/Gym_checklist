# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; the user approved the 2026-09-04 post-acceptance scope expansion (profile/body weight/BMI, set types, repeat cadence, Month view, and the listed visual hierarchy work). It supersedes the former scope freeze for those items.
- The locally reviewed checkpoint fixes the `756b755` compiler error with named value tuples. Legacy mixed rep/weight/time documents retain raw plan and actual values through Codable and Firestore decode/re-save, copy/repeat/add-set, and until an explicit editable type is selected. Current body weight is selected by applicable local date with deterministic same-day ordering, while Week/Month is deterministically Monday-first. Copy/Repeat retain cards but their primary labels are exactly `Copy` and `Create`.
- Current phase remains **pre-payment functional MVP acceptance**: no billing, paid Apple, TestFlight, App Store, or Blaze work.

## Latest verification
- Previous-scope evidence only: IPA run `33262381993` is green; it built source `ee579d0`. That workflow currently hard-codes this old source and must be updated only after the new final candidate SHA exists.
- Current static checks: whitespace, Google Sign-In configuration, account deletion, Firestore owner rules, offline cache/reconnect, release workflow, and security hygiene all pass. Windows has no local Swift/Xcode toolchain.
- `33905390516` is terminal red on `5f27622282cea2127637f294dcd82584bfbd4d40`. Production code compiled far enough to reach the test target, but `candidate-build` failed compiling `GymChecklistTests/ExpandedFeatureTests.swift`: the new legacy copy/repeat/add-set regression test called `@MainActor` repositories/view-model APIs from a synchronous nonisolated XCTest method. The focused test and full suite never ran. The test is now annotated `@MainActor`; every expanded-scope model/repository/view-model test was audited for the same boundary and the other production API call sites are already isolated.
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
1. Push the locally exhausted actor-isolation correction plus this checkpoint, then dispatch one replacement `candidate` scope on its exact SHA using the legacy migration test filter. Do not produce an IPA unless that candidate's focused test and authoritative full suite are green.
