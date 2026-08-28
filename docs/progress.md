# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; current app-code checkpoint is `2c35373` (`Fix Program calendar navigation refresh`). It moves the week controls/date strip out of the dynamic `List` subtree and gives selected-day sections an explicit dynamic diff boundary. This replaces the ineffective whole-`List` identity reset that broke next-week navigation.
- Current phase: **pre-payment functional MVP acceptance**. Use only zero-cost development/validation. Do not buy Apple Developer membership, enable Firebase/Google Cloud billing, or activate paid distribution until the user has accepted the functional MVP.
- The app contains the planned Program, Today, Settings, Firebase/auth, offline, Analytics, and Crashlytics paths, but acceptance is not complete.
- Program week/date navigation is regression-covered for next/previous week, individual date selection, and selected content after create/navigation. It still needs focused CI, final CI, and physical-iPhone proof before the defect is considered closed.
- The previous sideloadable in-memory `MVP_DEMO` remains an intermediate preview only. Final pre-payment acceptance should use the real MVP architecture and every no-cost live path that can be validated.

## Verification
- Static checks on `2c35373` passed: Firestore owner-isolation rules, security hygiene, offline cache/reconnect, Google Sign-In configuration, account-deletion contract, and release-workflow contract.
- The former full `33151994017` failed at `GymChecklistUITests.testAppLaunchesOnTodayAndNavigatesAllTabs` immediately after `programNextWeek` accepted a tap but did not expose `programDate-2026-08-21`; that is confirmed product-surface evidence, not a waived flake.
- Focused macOS UI run `33156079150` is in progress on exact SHA `2c35373`. After it succeeds, dispatch `smoke`, then authoritative `full`, on the same unchanged SHA.

## Free live-validation scope
Use a non-production Firebase **Spark** project and keep billing disabled. Validate every no-cost path available on Spark:
- email/password registration, login, reset, and logout;
- Google Sign-In;
- Firestore workout/custom-exercise/settings persistence and two-user owner isolation;
- app relaunch persistence;
- cached workout execution in airplane mode and automatic reconnect/sync;
- Analytics and Crashlytics;
- manual VoiceOver, Dynamic Type, and light/dark contrast checks;
- installation/use on the user's physical iPhone through a free personal-device path.

The local untracked Firebase plist is present and ignored. This host has neither Xcode/device tooling nor the Firebase CLI, so Spark-console deployment and physical-device live proof require the user's Apple/Firebase access; no billing action is needed for the listed Spark checks.

## Paid/deferred
- Apple Developer Program membership, App Store Connect, TestFlight, paid/release signing and secrets, final App Store release work, and `dev -> main`.
- Live Sign in with Apple configuration where paid Apple capabilities are required.
- Any Firebase/Google Cloud operation that requires attaching billing or upgrading from Spark to Blaze. In particular, keep the `functions:deleteAccount` implementation and tests, but defer live Cloud Function deployment if it requires Blaze.

## Next action
1. Process focused run `33156079150`; on success, run current-head `smoke`, then authoritative `full`, all on unchanged `2c35373`.
2. If all required CI is green, complete Spark live validation and physical-iPhone acceptance using the local plist, owner-scoped rules, and free personal-device route; batch only the exact console/device actions that this host cannot perform.
