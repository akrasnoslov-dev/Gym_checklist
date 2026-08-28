# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current head includes the user-approved Gym Checklist branding/app-icon integration. The latest Program behavior candidate remains `672fc66` (`Render Program calendar in dynamic scroll view`); branding does not close the Program blocker.
- Current phase: **pre-payment functional MVP acceptance**. Use only zero-cost development/validation.
- Program week/date navigation remains the active acceptance blocker until a final candidate CI gate is green and the behavior is confirmed on the physical iPhone.
- The previous in-memory `MVP_DEMO` is still only an intermediate preview.

## Latest verification
- On app candidate `672fc66`, Linux passed.
- Several macOS checks on that SHA produced mixed results; the latest standalone final run `33181272919` concluded failure, so `672fc66` is not accepted.
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
1. On the next Codex coding turn, inspect the concise failure from run `33181272919` and fix the actual remaining failure.
2. Dispatch exactly one `candidate` run with blocker filter `GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs`.
3. Record run ID/SHA and stop instead of waiting if no independent work remains.
4. Resume after CI is terminal: fix if red; if green, proceed directly to free Firebase Spark/device acceptance work.
