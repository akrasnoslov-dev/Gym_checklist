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
- Production/test candidate: `ff551d68cce8569529796b1255ffb04965fd0b34`.
- Changed production areas:
  - `GymChecklist/App/ContentView.swift`
  - `GymChecklist/Core/UI/GymTheme.swift`
  - `GymChecklist/Features/Auth/RegistrationView.swift`
  - `GymChecklist/Features/Exercises/ExercisePickerView.swift`
  - `GymChecklist/Features/Program/ProgramView.swift`
  - `GymChecklist/Features/Settings/SettingsView.swift`
  - `GymChecklist/Features/Today/TodayView.swift`
- Focused UI-test expectations were updated only where the frozen design intentionally removed old visible Settings summary text while preserving the same profile/BMI/body-weight behavior through accessibility values.

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
- Windows does not provide Xcode/SwiftUI compilation. The next automatic PR macOS smoke run is compile/runtime evidence, not final approval.
- The previously built Phase 9 acceptance IPA from `4c655201...` is rejected as visual acceptance evidence and must not be reused as the final redesign build.

## Remote gate
- `REMOTE_GATE_READY_FOR_FINAL_AUDIT ff551d68cce8569529796b1255ffb04965fd0b34`
- Prior approvals for `4526513...` / `4c655201...` are superseded by the corrective production changes.
- A fresh Pass B must audit exactly `ff551d68cce8569529796b1255ffb04965fd0b34`.
- If Pass B changes production/test/project code, return to Pass A with a new SHA.
- Only a clean Pass B may approve and dispatch the exact-SHA macOS candidate/full gate.

## Remaining external proof
- After a GREEN exact-SHA candidate/full gate, build a new unsigned Firebase-backed physical-iPhone acceptance IPA from the same approved corrective source.
- Install that new IPA on the physical iPhone and compare the main user-visible surfaces with the frozen Phase 8 design.
- Paid Apple distribution, live paid Apple capabilities, Firebase billing, paid deletion-function deployment if required, and `dev -> main` remain deferred.

## Next action
1. Push the corrective Pass A commits to existing PR #6.
2. Confirm automatic PR checks and independently audit exact candidate `ff551d68cce8569529796b1255ffb04965fd0b34`.
3. If Pass B is clean, dispatch one exact-SHA macOS candidate/full gate.
4. If GREEN, build and return a fresh acceptance IPA from that exact approved corrective source.
