# Gym Checklist — Progress Checkpoint

## 2026-10-15 Program architecture hardening — PASS A COMPLETE
- `REMOTE_GATE_READY_FOR_FINAL_AUDIT 80f30e6a296fc470ba399ed65d3c80d9dc1e6172`
- PR #6 now has one Program selected-date authority, fixed header/calendar chrome above dynamic workout content, centralized sheet/deletion routing, native swipe deletion, and handle-scoped reorder with measured row targeting and cancellation restoration.
- Copy now fills an existing empty workout while preserving its identity; populated destinations explicitly offer Add or confirmed Replace; copied plans receive fresh IDs and never copy completion, actual, or skipped state. Missing-destination copy publishes one completed aggregate rather than an intermediate empty workout.
- Set editors use compact detented sheets, persistent Reps/Weight/Time labels, dirty-dismiss protection, and exercise-level set type changes that preserve completed actuals. The authenticated root remains the sole appearance authority and no longer forces a separate tab-bar background transition.
- Regression coverage now includes empty/populated copy journeys, Add/Replace data protection, single-shot deletion, reorder reflow/cancellation state and navigation persistence, stable Week/Month chrome, dirty sheet dismissal, persistent labels, and theme changes across tabs with a sheet presented.
- Local/static verification is GREEN: agentic workflow, security hygiene, offline, Firestore owner isolation, Google Sign-In configuration, account deletion, release/acceptance-IPA exact-source, iOS CI contracts, Cloud Functions JavaScript syntax, and `git diff --check`.
- Independent architecture, product/UX, code-quality, test/CI, and security/Firebase reviews completed. The final code-quality re-review found no remaining Critical/Important issue. Security review confirms owner-scoped rules and plan-only copy IDs; live Firestore rejected-write rollback/reconnect behavior remains a physical/live verification caveat of the existing optimistic offline architecture.
- This is not a GREEN Xcode gate or physical-iPhone acceptance. Per the two-pass rule, a fresh Pass B must audit exact SHA `80f30e6a...` without production/test/project changes, then dispatch one exact-SHA candidate/full run. Only after GREEN may the repaired IPA workflow build from that same SHA and produce a verified Sideloadly artifact. PR #6 remains Draft and unmerged.

## 2026-10-14 physical iPhone video review corrections (PENDING CI)
- Three user-confirmed defects in PR #6 preview: set drag visually overlaps rows and reveals delete controls; workout deletion presents confirmation again after first successful deletion; Create workout duplicates Copy already present in the existing-workout overflow menu.
- Corrective code: replace manually offset set-drag with native item drag and per-row drop delegate plus animated provisional reflow; keep horizontal swipe independent; move workout delete confirmation out of the conditional menu to a persistent Program alert and clear pending deletion before model mutation; make Create workout perform one direct empty-workout creation and keep Copy only in the existing-workout actions menu.
- Updated UX canonical owner and targeted XCTest expectations for direct creation and single-shot delete. Previous physical IPA `9af8499` does not include these fixes and must not be reused as completion evidence.
- State: code change pending CI, full suite and fresh physical-iPhone validation. PR #6 stays Draft; no merge, no paid services.

## 2026-10-13 PR #6 corrective feedback batch (UNVERIFIED)
- User supplied five further physical-iPhone findings in `design comments5.docx`: date-switch layout movement, mismatched source/destination date pickers, redundant separate create/copy actions, broken inline set reorder/swipe delete, and whole-number weight appearing as `55.0`.
- Current PR #6 corrective batch: stable toolbar slot and no forced selected-date subtree recreation; Create workout now offers Start blank/Copy existing; source and destination both use compact calendar pickers with valid-source checks; set rows use independent drag handles and a live animated horizontal delete reveal; weight inputs use up-to-two-decimal formatting in Today, Program plan, and past actual editor.
- Focused iOS UI regressions added for create/copy, Program swipe-to-delete, and decimal-free weight entry.
- This is an implementation checkpoint only, NOT a GREEN Xcode gate or physical-iPhone acceptance. PR #6 remains Draft/unmerged. Inspect automatic PR smoke, then a separate final audit and exact-SHA candidate/full gate before a new physical-iPhone IPA.

## 2026-10-13 physical-device feedback (IN PROGRESS)
- User reviewed the PR #6 corrective design on iPhone and approved fixes covering Program statuses, old-workout copying, calmer date hierarchy, contextual delete presentation, custom exercise rename/delete, blank numeric inputs, inline drag/swipe set actions, visible local-save feedback, exercise-wide set type, and varied new completion art.
- Existing PR #6 remains Draft and unmerged; all these changes belong in the same PR. Expanded exercise catalog/filtering/illustrations is deferred to a separate PR after PR #6 is accepted.
- Current source changes are a new corrective candidate, NOT yet a passed gate or accepted iPhone build. Do not reuse older green evidence or IPA as acceptance of this new tree.
- Next gate sequence: validate current diff and relevant tests, push exact commit, inspect macOS smoke, perform independent Pass B, then one exact-SHA candidate/full run. After GREEN only, rebuild Firebase unsigned IPA from the same exact SHA, download to Windows, verify SHA256, and compare on iPhone.
- The underlying repo `dev` documentation can be stale because active PR #6 remains unmerged; source of truth for current corrective changes is PR #6 head and its actual code/test diff.

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
