# Gym Checklist — Progress Checkpoint

## Current state
- The functional MVP baseline remains implemented; paid Apple distribution/release work is still deferred.
- Phase 8 Design Freeze is APPROVED/COMPLETE. Frozen visual source: `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- PR #5 design/prototype work is merged into `dev`.
- PR #6 remains the active SwiftUI implementation PR and must stay unmerged until explicit user approval.
- The earlier Phase 9 completion claim was incorrect: installed IPA evidence showed that only a small subset of the frozen redesign had reached production SwiftUI.
- Corrective Phase 9 Pass A reopened the implementation and now covers the user-visible canonical hierarchy across app navigation, shared theme, Today, Program, exercise/custom-exercise flows, Settings/Profile/Body weight, authentication, and supporting copy/repeat presentation while preserving existing product/data behavior.
- `ProgramCalendarState.swift` already matched the frozen semantic state vocabulary and required no corrective production change.

## Corrective candidate
- Corrective production implementation commit: `ff551d68cce8569529796b1255ffb04965fd0b34`.
- Exact corrective candidate after the UI-test compile repair: `7e21450918134393d27dbf61737240d63bf75fa9`.
- Changed production areas:
  - `GymChecklist/App/ContentView.swift`
  - `GymChecklist/Core/UI/GymTheme.swift`
  - `GymChecklist/Features/Auth/RegistrationView.swift`
  - `GymChecklist/Features/Exercises/ExercisePickerView.swift`
  - `GymChecklist/Features/Program/ProgramView.swift`
  - `GymChecklist/Features/Settings/SettingsView.swift`
  - `GymChecklist/Features/Today/TodayView.swift`
- Focused UI-test expectations were updated only where the frozen design intentionally removed old visible Settings summary text while preserving the same profile/BMI/body-weight behavior through accessibility values. The follow-up `7e214509...` fixes three Settings assertions to use the helper available in the owning XCTestCase; production SwiftUI is unchanged by that repair.

## Latest verification
- Frozen prototype source and snapshots remain the visual reference.
- Windows static verification is GREEN on the corrective working tree:
  - `git diff --check`
  - agentic workflow contract
  - security hygiene
  - account deletion contract
  - Firestore owner-isolation contract
  - offline cache/reconnect contract
  - Google Sign-In configuration contract
  - release workflow contract
  - iOS CI contract
  - `node --check functions/index.js`
- Automatic PR macOS smoke run `37331193427` is GREEN on exact candidate `7e21450918134393d27dbf61737240d63bf75fa9`, providing fresh SwiftUI compile/runtime and smoke-test evidence.
- The previously built Phase 9 acceptance IPA from `4c655201...` is rejected as visual acceptance evidence and must not be reused as the final redesign build.

## Remote gate (2026-10-13)
- The latest tested corrective source `f1e2e8605501351d2ad077eeb693cbbcd1d9ae7c` has GREEN PR Linux and macOS smoke checks (runs `37336705611`, `37336705972`).
- Exact-source candidate run `37336763051` checked out `f1e2e860...`, passed `candidate-build`, but failed `candidate-focused` before `candidate-full`. At `GymChecklistUITests.swift:120`, the Today date accessibility element was not found after switching back from Program. The failure revokes all prior `REMOTE_GATE_APPROVED` claims for this acceptance candidate.
- New IPA build `37337156863` succeeded from exact source `f1e2e860...`, but was built before the full gate passed. Its seven-day GitHub artifact retention expired on 2026-10-12. The older 7e21450 IPA is not final acceptance evidence.
- A minimal accessibility/test hardening patch is being verified: contain Today header accessibility children explicitly, wait for `todayScreen` after tab switch, and inspect `todayDate` with diagnostic output. A full exact-SHA candidate gate and fresh IPA remain required.
- PR #6 must stay unmerged until explicit user approval.

## Remaining external proof
- After a GREEN exact-SHA candidate/full gate, build a new unsigned Firebase-backed physical-iPhone acceptance IPA from the same approved corrective source.
- Install that new IPA on the physical iPhone and compare the main user-visible surfaces with the frozen Phase 8 design.
- Paid Apple distribution, live paid Apple capabilities, Firebase billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Finish focused static review and create the minimal new PR #6 corrective commit. Record its exact source SHA.
2. Perform a fresh independent review of that exact SHA, then rerun one authoritative macOS `candidate` gate (focused regression followed by full suite).
3. Only after GREEN, rebuild a new Firebase-backed unsigned IPA from that exact SHA, transfer to Windows Downloads, verify SHA256, and test on the physical iPhone. Do not merge PR #6 without user approval.
