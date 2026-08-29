# Gym Checklist — Progress Checkpoint

## Current state
- Workflow/docs HEAD: `dev` (after the physical-iPhone acceptance IPA workflow commit); accepted app source remains `ee579d0`, intentionally checked out by the workflow.
- Physical-device IPA: run `33261038190` showed that removing `-disableAutomaticPackageResolution` did not solve the Xcode 26.6 Release device build failure. The observed cause is the global empty `SWIFT_ACTIVE_COMPILATION_CONDITIONS`, which stripped SwiftPM's GTMAppAuth package conditions including `SWIFT_PACKAGE` and `SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE`. Replacement run `33261496979` has been dispatched from workflow/docs SHA `9d2810f`, which removes only that global override and checks out accepted app source `ee579d0`. Do not poll it from this task.
- Candidate app source: `ee579d0`; the Program blocker CI gate is green. The consolidated no-cost external handoff is prepared; its live evidence remains.
- Current phase: **pre-payment functional MVP acceptance**. Use only zero-cost development/validation.
- Program week/date navigation has passed its final candidate CI gate; physical-iPhone confirmation remains part of acceptance.
- The previous in-memory `MVP_DEMO` is still only an intermediate preview.

## Latest verification
- On app candidate `672fc66`, Linux passed.
- Run `33210615203` failed before tests: `.searchFocused` is iOS 18-only but every app target supports iOS 17. The picker’s search field is already explicitly tapped by the blocker test, so the unsupported autofocus code was removed.
- `CI_GREEN 33211219461`: `candidate` scope passed its blocker test and full suite on exact SHA `ee579d0`.
- Static free-validation contracts pass: Firestore owner rules, offline/reconnect, Google callback configuration, security hygiene, and account-deletion behavior. The local Firebase plist is present and ignored; no configuration values were read or recorded.
- The prior process wasted substantial Codex runtime by polling separate focused/smoke/full runs. The CI workflow now has a `candidate` scope that builds once, runs one exact blocker test, and if it passes automatically runs the full suite on the same runner/build/SHA.
- CI now emits compact failure output and retains detailed diagnostics as a short-lived artifact. Swift package sources are cached.
- The approved lime/green Gym Checklist mark is now wired as the iOS `AppIcon`; the same master/vector assets are stored under `docs/brand/`. This branding change should ride the next justified candidate gate rather than consuming a separate macOS run.

## CI operating rule
- During diagnosis: one focused `unit`/`ui` run per code change when needed.
- For the proposed fix: dispatch one `candidate` run with the exact blocker test filter.
- Do not separately run smoke before full.
- After dispatch, record run ID/scope/SHA and do not keep Codex alive polling. If no useful non-invalidating work remains, end the task immediately and resume after CI is terminal.
- A green `candidate` run is both focused blocker evidence and required full-suite evidence for that exact SHA.

## Free live-validation scope
Live Spark/device proof remains: email/password auth/reset/logout, Google Sign-In, Firestore persistence and two-user isolation, relaunch, offline cache/reconnect, Analytics, Crashlytics, accessibility, and free personal-device installation. This Windows workspace has neither an authenticated Firebase CLI nor Xcode; do not infer live proof from static contracts. The single prepared handoff is `docs/mvp_external_acceptance_handoff.md`.

## Paid/deferred
Apple Developer Program, TestFlight/App Store, paid release signing/secrets, Firebase Blaze/billing, live Cloud Function deployment if Blaze is required, paid-only Apple configuration, final release work, and `dev -> main`.

## Next action
1. On the next task, inspect the terminal result of IPA run `33261496979` once. If green, download `GymChecklist-MVP-ee579d0` and complete the one external handoff in `docs/mvp_external_acceptance_handoff.md` against `ee579d0`.
