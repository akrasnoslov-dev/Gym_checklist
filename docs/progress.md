# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current blocker fix removes an iOS 18-only Exercise Picker focus modifier while preserving iOS 17 search interaction.
- Current phase: **pre-payment functional MVP acceptance**. Use only zero-cost development/validation.
- Program week/date navigation remains the active acceptance blocker until a final candidate CI gate is green and the behavior is confirmed on the physical iPhone.
- The previous in-memory `MVP_DEMO` is still only an intermediate preview.

## Latest verification
- On app candidate `672fc66`, Linux passed.
- Run `33210615203` failed before tests: `.searchFocused` is iOS 18-only but every app target supports iOS 17. The picker’s search field is already explicitly tapped by the blocker test, so the unsupported autofocus code was removed.
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
After the Program blocker is green, continue the previously documented Firebase Spark and physical-device validation: email/password auth/reset/logout, Google Sign-In, Firestore persistence and two-user isolation, relaunch persistence, offline cache/reconnect, Analytics, Crashlytics, accessibility, and free personal-device installation.

## Paid/deferred
Apple Developer Program, TestFlight/App Store, paid release signing/secrets, Firebase Blaze/billing, live Cloud Function deployment if Blaze is required, paid-only Apple configuration, final release work, and `dev -> main`.

## Next action
1. Commit/push the iOS 17 availability fix, dispatch one `candidate` run with `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`, record its run ID/SHA, then stop without polling.
