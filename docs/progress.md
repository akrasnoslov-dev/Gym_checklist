# Gym Checklist — Progress Checkpoint


## 2026-10-18 — Persistence reliability H2/M2 Pass A
- Status: `REMOTE_GATE_READY_FOR_FINAL_AUDIT aa74c55ddff9cc4ccf4c3ff860abd70bf60c2eea`
- Base: latest `dev` after merged PR #9 (`6919872ca14f48f5ecabf14d3f95477f1832326c`).
- Replaced the global write generation with per-document mutation tracking and protected, durable pending-mutation journals for workouts, preferences, custom exercises, and body weight.
- Preserved optimistic/offline behavior while surfacing permanent rejection and post-restart unconfirmed state through retryable, nonmodal UI that keeps valid input available.
- Added deterministic regression coverage for concurrent documents, same-document sequencing, restart reconciliation, permission-style rejection, unrelated successful writes, retry, and confirmed workout visuals.
- Windows Pass A evidence: all repository contract scripts and `git diff --check` pass. The first automatic PR smoke exposed and prompted repair of three Swift name-shadowing compile errors; XCTest and live Firebase reconnect/permission scenarios still require the fresh macOS Pass B exact-SHA gate.
- Next: run a fresh Pass B audit and the required macOS verification against exact source SHA `aa74c55ddff9cc4ccf4c3ff860abd70bf60c2eea`. Do not merge, release, deploy, or generate an acceptance IPA before that gate is green.


## 2026-10-16 Phase 9 acceptance follow-up — PASS A COMPLETE
- `REMOTE_GATE_READY_FOR_FINAL_AUDIT e3b2b76ea661cedf60e40a4a7ed32bd859d5c412`
- Branch `codex/phase-9-acceptance` starts from the post-PR #6 `dev` baseline `5b589e5594831a7726584671ce21d01ea7005f40`. This is a focused acceptance follow-up, not a redesign rewrite and not authorization to merge, deploy, or promote `dev -> main`.
- Investigated failed macOS run `38932126631`: all 122 unit tests passed; the failing UI test timed out while Xcode launched the app after `DebuggerLLDB.DebuggerVersionStore.StoreError` / “no debugger version”; the immediately following UI test launched and passed. Evidence supports a runner/Xcode launch flake, not an app or assertion regression, so no test was weakened.
- Corrected one evidenced Copy defect: placeholder workouts whose exercises have zero sets are no longer offered as sources, and the domain layer rejects such a source before any destination mutation. Regression coverage verifies a rejected Replace leaves an existing populated destination and selection unchanged. Independent re-review reports no Critical, Important, or Minor findings.
- Made the frozen prototype contract platform-stable by normalizing CRLF/LF before exact generated-matrix comparisons; the 64-entry prototype and stabilization contracts now pass on Windows without changing product output.
- Local/static verification is GREEN: `git diff --check`, agentic workflow, security hygiene, offline/reconnect, Firestore owner isolation, Google Sign-In, account deletion, release/acceptance-IPA exact-source, iOS CI, and prototype/stabilization matrix contracts. Swift/Xcode is unavailable on this Windows host, so no local XCTest result is claimed.
- Code/static evidence already covers stable Program chrome and route ownership, plan-only Copy semantics with fresh IDs, persistent set labels, centralized appearance ownership, and owner/offline contract wiring. Physical iPhone verification is still required for swipe reveal and drag cancellation/gesture quality; header scrolling/ghosting; System/Light/Dark transitions and TabBar/sheet flicker; Copy detents, keyboard, and dirty dismissal; and live Firebase owner isolation, persistence, offline/reconnect, and rejected-write rollback.
- Per the two-pass gate, the next action is a fresh Pass B audit of exact source SHA `e3b2b76e...`. Only a clean audit may dispatch one exact-SHA candidate/full macOS run; only GREEN may produce a fresh unsigned Firebase IPA for Sideloadly and physical-iPhone acceptance. No older IPA is valid evidence for this source.


## 2026-10-16 PR #6 handoff — MERGE BASELINE, REDESIGN NOT ACCEPTED
- Owner explicitly authorized merging the oversized Phase 9/PR #6 implementation into `dev` now, to end the iterative PR and continue in a **separate new task and new focused PR**. This supersedes the older “keep PR #6 Draft / do not merge” instructions below for PR #6 only; it does NOT authorize `dev -> main`, release, deployment, or claiming product acceptance.
- Last observed implementation SHA before this handoff documentation: `825352b9e0a9361ee47795175ba31158fe15396d`. The Linux checks run `38930300623` and automatic macOS smoke run `38930300556` were GREEN for that exact SHA. These are not an authoritative exact-SHA candidate/full test gate, and no recent iPhone IPA/physical acceptance from this tree was verified.
- Implemented in the current code (not physical-device-accepted): fixed inline Program header/calendar, screen-owned delete confirmation/sheet route, set swipe via native List action and scoped drag reorder, compact detented set editors with persistent labels, exercise-level set types, calendar indicators for Copy source, and copying into an existing empty workout; populated destinations offer Add or confirmed Replace with new plan-only IDs.
- **Remaining verification / possible UX corrections for new PR (do not mark DONE before testing):**
  1. Run full authoritative iOS candidate/full suite at one exact follow-up SHA, investigate failures without papering over them; ensure additional unit/UI regressions are meaningful and stable.
  2. Install a fresh unsigned Release Firebase-backed IPA from the tested SHA using Sideloadly and validate on a physical iPhone against approved Phase 8 freeze/mockups; document screen captures and exact remaining differences.
  3. Explicitly verify Program set swipe-left visibly exposes a working Delete, delete confirms once, handle-drag reorders smoothly (including cancellation) without gesture conflicts or stuck overlays.
  4. Explicitly verify Program inline `Program` + `⋯` header, no ghost button or large empty navigation band, stable date/Week/Month switching, no clipped header or jumpy scrolling.
  5. Explicitly verify Light/Dark changes across Today/Program/Settings and open sheets, especially bottom TabBar background/icon flicker.
  6. Explicitly verify empty-workout -> Copy from populated past day -> destination fills, Copy calendar marks only usable source dates, Add vs confirmed Replace are correct and do not lose actual/completion data or create duplicate workouts.
  7. Compare Edit plan, Edit actual, Create and Copy modal size/scroll/dismiss behavior with frozen mockups: compact bottom sheets, persistent Reps/Weight/Time labels, no redundant notices; in particular evaluate Copy’s `.medium/.large` detents and swipe-to-dismiss behavior and avoid unintended loss of user input.
  8. Perform Firebase Spark/non-production real-device smoke as available: owner isolation, persistence, offline/reconnect and failure handling; preserve existing security and zero-cost constraints. Live rejected-write rollback remains an unresolved verification caveat.
- **Execution rules for follow-up:** branch from updated `dev`, open a **new narrowly-scoped Draft PR**; treat this merge as a checkpoint, not redesign acceptance. Preserve the current data model and all behavior that already works, avoid a whole-app rewrite and unbounded refactoring, group fixes by root cause, run visual/interaction regression checks, full CI and new IPA before requesting iPhone acceptance. Defer expanded exercise catalog/filtering/illustrations and paid distribution to separate tasks.
- The dated notes below preserve historical context and should not be interpreted as current PR #6 merge blockers.


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
