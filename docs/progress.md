# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`; app-code checkpoint remains `eeb0346` (`Keep Firebase out of test processes`); `524c4c4` only recorded the previous verification state.
- Current phase: **pre-payment functional MVP acceptance**. Use only zero-cost development/validation. Do not buy Apple Developer membership, enable Firebase/Google Cloud billing, or activate paid distribution until the user has accepted the functional MVP.
- The app contains the planned Program, Today, Settings, Firebase/auth, offline, Analytics, and Crashlytics paths, but acceptance is not complete.
- The Program week/date selector is now a **confirmed product bug**, not a test-only flake: the user reports that date switching did not work on the previously installed physical-iPhone build. The previous `KNOWN_UI_TEST_HARNESS_FLAKE` classification is revoked.
- The previous sideloadable in-memory `MVP_DEMO` remains an intermediate preview only. Final pre-payment acceptance should use the real MVP architecture and every no-cost live path that can be validated.

## Verification
- Local whitespace, Firebase-security-hygiene, Firestore-rules, account-deletion contract, offline cache/reconnect contract, Google Sign-In configuration contract, and release-workflow contract checks previously passed.
- Focused historical-editor rerun `33098518317` and current-head smoke `33151441904` passed on the preceding app checkpoint.
- Final current-head full `33151994017` failed at `testAppLaunchesOnTodayAndNavigatesAllTabs` on Program navigation after moving to the next week. Because the user independently reproduced the date-selector failure on iPhone, this failure is a current acceptance blocker.
- Required acceptance state is now explicit: the final candidate SHA must have green required CI, including a green authoritative macOS `full` run. A red final run is not acceptable.

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

## Paid/deferred
- Apple Developer Program membership, App Store Connect, TestFlight, paid/release signing and secrets, final App Store release work, and `dev -> main`.
- Live Sign in with Apple configuration where paid Apple capabilities are required.
- Any Firebase/Google Cloud operation that requires attaching billing or upgrading from Spark to Blaze. In particular, keep the `functions:deleteAccount` implementation and tests, but defer live Cloud Function deployment if it requires Blaze.

## Next action
1. Reproduce and fix the Program week/date-selector product defect. Add/adjust regression coverage for the real failure mode.
2. Run focused verification, then current-head smoke, then authoritative `full`; continue fixing/rerunning until the final exact candidate SHA is green.
3. Complete every technically achievable zero-cost Firebase Spark integration/setup check. If console/device action is required from the user, batch the exact free actions into one concise handoff and continue all independent work first.
4. Produce the free physical-iPhone candidate for the user's functional product acceptance and clearly list the paid-only functionality that remains unverified.
