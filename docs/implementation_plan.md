# Gym Checklist — Autonomous Implementation Plan

This is the execution backlog for Codex. It is intentionally detailed enough to support long autonomous runs with minimal user interaction.

Codex must not implement tasks from titles alone. For every task, read the full task body and all referenced sections of `docs/product_spec.md`, `docs/ux_spec.md`, and `docs/architecture.md` before editing code.

Status legend: `TODO`, `IN PROGRESS`, `DONE`, `BLOCKED`. Pending qualifiers such as `IN PROGRESS (PENDING CI)`, `IN PROGRESS (PENDING LIVE)`, and `IN PROGRESS (PENDING EXTERNAL)` are allowed and are not equivalent to `DONE`.

Task completion rule: a task may be marked `DONE` only when all listed acceptance criteria and verification steps pass, or when an explicitly documented environment limitation prevents only non-authoritative local verification and authoritative CI passes instead.

Continuity rule: after each meaningful checkpoint, update `docs/progress.md` with verification, relevant review notes, blockers/deferred external actions, and the exact next safe action. Runtime status in `docs/progress.md` plus actual Git/code state is authoritative if a task header in this plan is stale.

---

## Milestone 0 — Repository and iOS bootstrap

### M0.1 `DONE` Create the native iOS project
**Goal**
Create an Xcode project named `GymChecklist` using Swift and SwiftUI, with unit test and UI test targets.

**Requirements**
- iPhone-first native iOS application.
- App target: `GymChecklist`.
- Unit tests target and UI tests target must exist.
- Do not add product functionality yet.
- Do not add Firebase yet.
- Choose a sensible minimum iOS version supported by the CI runner and record it in `docs/architecture.md`.

**Acceptance criteria**
- Repository contains a valid `.xcodeproj`.
- App launches to a placeholder root view.
- Unit test target runs at least one smoke test.
- UI test target can launch the app.

**Verification**
- macOS CI build passes.
- macOS CI tests pass.

**Spec references**
- Product Spec: Technical Architecture, Definition of Done.
- Architecture: platform and stack sections.

---

### M0.2 `DONE` Establish feature-oriented MVVM structure
**Goal**
Create the project structure required for autonomous implementation without over-engineering.

**Requirements**
- Feature folders/modules for: `Auth`, `Today`, `Program`, `Exercises`, `Settings`.
- Shared areas for: `Core`, `Data`, `Services`.
- Separate Views, ViewModels, repositories/services, and models where justified.
- No dependency injection framework.
- No speculative abstractions.

**Acceptance criteria**
- Folder/group layout matches `docs/architecture.md`.
- App still builds.
- Placeholder files compile without dead architecture scaffolding.

**Verification**
- Build + unit tests.

**Dependencies**
- M0.1

---

### M0.3 `DONE` Build the application shell
**Goal**
Create the base app navigation with the three approved top-level tabs.

**Requirements**
- Tabs: `Today`, `Program`, `Settings`.
- Today is selected by default.
- Use placeholders only; no product logic yet.
- Keep labels in English.

**Acceptance criteria**
- App launches on Today.
- All three tabs are reachable.
- Returning to app preserves a sensible tab state unless auth routing later overrides it.

**Verification**
- UI smoke test for tab navigation.

**Spec references**
- Product Spec: Information Architecture, Navigation Model.

**Dependencies**
- M0.2

---

### M0.4 `DONE` Make GitHub Actions authoritative for iOS build/test
**Goal**
Turn the macOS CI workflow into the authoritative build/test path for a Windows-based developer.

**Requirements**
- CI triggers on PRs to `dev` and relevant pushes.
- Use a current macOS runner and available Xcode.
- Build the app for an iOS Simulator.
- Run unit tests.
- Run UI tests when stable enough; if deferred, document why and add them by M3 checkpoint.
- Fail on build/test errors.

**Acceptance criteria**
- Workflow runs against the real scheme/project.
- Successful run proves the app compiles on macOS.
- No signing secrets required for simulator builds.

**Verification**
- One green CI run.

**Dependencies**
- M0.1

---

### M0.5 `DONE` Add lightweight code quality conventions
**Goal**
Define low-friction Swift quality rules without creating maintenance overhead.

**Requirements**
- Prefer native compiler warnings and project conventions.
- Add formatter/linter only if setup is stable on local/CI environments.
- Document exact commands.
- No tool should block development because it cannot run on Windows unless CI covers it.

**Acceptance criteria**
- `docs/codex_instructions.md` contains the final verification commands.
- CI remains green.

**Dependencies**
- M0.4

---

### M0.6 `DONE` Bootstrap checkpoint
**Goal**
Review the repository foundation before product implementation.

**Required reviews**
- `architecture_guardian`
- `code_quality_agent`
- `test_ci_agent`

**Acceptance criteria**
- No blocking architecture or CI findings remain.
- `docs/progress.md` identifies M1.1 as next task.

---

## Milestone 1 — Core domain model and business rules

### M1.1 `DONE` Implement core domain entities
**Goal**
Implement model types needed by the approved MVP.

**Required entities**
- `UserSettings`
- `Exercise`
- `Workout`
- `WorkoutExercise`
- `WorkoutSet`

**Requirements**
- Strongly typed identifiers where practical.
- Workout belongs to one concrete local calendar date.
- One workout maximum per date must be enforceable by repository/business logic.
- Exercise order and set order are explicit.
- Workout exercise supports skipped state.
- Workout set supports reps, weight, time, completion, actual values, timestamps as needed.

**Acceptance criteria**
- Models encode the approved MVP without storing exercise media, analytics, PRs, timers, social data, or unrelated future features.
- Models are testable independently from Firebase.

**Verification**
- Model construction/encoding tests.

**Spec references**
- Product Spec: Data Model, Exercise Structure, Date Rules.

**Dependencies**
- M0.6

---

### M1.2 `DONE` Implement local calendar date semantics
**Goal**
Prevent UTC/day-boundary bugs in Today and Program.

**Requirements**
- Introduce a local calendar date value/utility separate from absolute timestamps.
- Today workout selection uses the user's local calendar date.
- Date navigation supports previous/future weeks.
- Timezone changes must not reinterpret stored workout dates as UTC instants.

**Acceptance criteria**
- Tests cover day boundaries and at least two time zones.
- A Copenhagen Friday workout remains Friday regardless of UTC offset representation.

**Spec references**
- Product Spec: Program Calendar Model, Date and Time Rules.

**Dependencies**
- M1.1

---

### M1.3 `DONE` Implement set display rules
**Goal**
Generate the exact compact set text used by Today and history.

**Requirements**
- Weight > 0 + reps => `8 reps × 60 kg` (or lb).
- Weight = 0 and time = 0 => hide weight and show reps only.
- Time-based technical placeholder reps must not appear when they add no value.
- Example time-only output: `45 sec`.
- Unit preference is respected.
- Do not display `0 kg` to the user.

**Acceptance criteria**
- Unit tests cover weighted, bodyweight/no-weight, time-only, and kg/lb cases.
- Formatting logic is reusable by Today and history.

**Spec references**
- Product Spec: Display Rules 16.x.

**Dependencies**
- M1.1

---

### M1.4 `DONE` Implement completion and actual-value semantics
**Goal**
Implement the agreed simplified planned/current vs actual behavior.

**Requirements**
- Before completion, set values are current planned values.
- Completing a set copies current reps/weight/time into actual values and sets completion true.
- Tapping a completed set again undoes completion.
- Completed actual values can be edited later.
- No historical planned snapshot model.
- Program edits update not-yet-completed set values immediately.
- Program edits must not silently overwrite completed actual values.

**Acceptance criteria**
- Complete -> actual values created.
- Undo -> set becomes incomplete and behavior is deterministic/documented.
- Completed actual can be edited without changing completion state.
- Incomplete Program edit changes what Today displays.

**Verification**
- Unit tests for all transitions above.

**Spec references**
- Product Spec: Planned / Actual Model, Actual Storage Rule, Delete/Edit Behaviour.

**Dependencies**
- M1.1

---

### M1.5 `DONE` Implement workout completion state rules
**Goal**
Provide a single tested source of truth for workout status.

**Requirements**
- Planned: no meaningful completion yet.
- Partial: some sets completed, workout not finished.
- Completed: all non-skipped required sets completed, or remaining exercises explicitly skipped.
- Past incomplete workout can be represented as incomplete.
- Skipped exercise is not considered completed.

**Acceptance criteria**
- State transitions are deterministic and test-covered.
- Completion detection can drive the motivational popup without UI-specific duplication.

**Spec references**
- Product Spec: Workout Completion, Workout States in Calendar.

**Dependencies**
- M1.4

---

### M1.6 `DONE` Domain checkpoint
**Goal**
Validate business rules before UI work.

**Required reviews**
- `architecture_guardian`
- `product_spec_guardian`
- `test_ci_agent`

**Acceptance criteria**
- Domain rules match approved product spec.
- No premature Firebase coupling.
- All model/business-rule tests pass.

---

## Milestone 2 — Exercise catalog and Program planning UX (local/mock persistence first)

### M2.1 `DONE` Add bundled system exercise catalog
**Goal**
Provide a searchable offline exercise list.

**Requirements**
- Bundled locally with the app.
- English names only.
- Include a practical starter list across Chest, Back, Legs, Shoulders, Biceps, Triceps, Core, Cardio/Other.
- No images/videos in MVP.
- Search is case-insensitive and responsive.

**Acceptance criteria**
- Catalog available with no network.
- Search returns expected matches.

**Dependencies**
- M1.6

---

### M2.2 `DONE` Implement custom exercise support locally
**Goal**
Allow users to add exercises not present in the bundled catalog.

**Requirements**
- Required field: name.
- Optional category if already supported by UX.
- Custom exercise becomes available for future selection.
- Duplicate handling should be simple and predictable; do not block legitimate similarly named exercises unnecessarily.

**Acceptance criteria**
- Add custom exercise flow works with mock/local repository.
- Custom exercise is searchable afterward.

**Dependencies**
- M2.1

---

### M2.3 `DONE` Build Program week/date navigation
**Goal**
Implement the calendar-centric Program screen.

**Requirements**
- Weekly header with previous/next navigation.
- Seven concrete dates visible/selectable.
- User can move to previous and future weeks.
- Selected date drives the workout content below.
- States can represent empty, planned, partial, completed, incomplete without clutter.
- History uses the same navigation rather than a separate top-level tab.

**Acceptance criteria**
- User can navigate at least several weeks backward/forward.
- Selected date is unambiguous.
- Empty dates show a clear create-workout affordance.

**Spec references**
- Product Spec: Program, Week Navigation, Workout States in Calendar, History.

**Dependencies**
- M1.2

---

### M2.4 `DONE` Implement create workout for selected date
**Goal**
Allow one workout to be created for a concrete date.

**Requirements**
- `Create workout` from empty date.
- Prevent two workouts for the same user/date.
- Start with empty ordered exercise list.
- Save/update through repository abstraction.

**Acceptance criteria**
- Creating on one date does not create on other weekdays automatically.
- Duplicate same-date creation is prevented cleanly.

**Dependencies**
- M2.3

---

### M2.5 `DONE` Build Exercise Picker and search
**Goal**
Add exercises quickly while planning.

**Requirements**
- Search field.
- System exercise results.
- User custom exercise results.
- `Add custom exercise` fallback.
- Selecting an exercise returns directly to workout editor.

**Acceptance criteria**
- Existing exercise can be added in a short flow.
- Missing exercise can be created and added without dead ends.

**Dependencies**
- M2.1, M2.2, M2.4

---

### M2.6 `DONE` Build workout exercise editing
**Goal**
Manage the ordered exercise list for a date.

**Requirements**
- Add exercise.
- Delete exercise.
- Reorder exercises.
- Preserve independent per-date workout content.
- Do not expose exercise media/details in MVP.

**Acceptance criteria**
- Reordering persists in local/mock repository.
- Delete behavior is reversible only through re-adding; confirmation only if appropriate.

**Dependencies**
- M2.5

---

### M2.7 `DONE` Build arbitrary set editor
**Goal**
Let every set have independent reps/weight/time values.

**Requirements**
- Add set.
- Edit set.
- Delete set.
- Reorder sets if needed by the UI model.
- Reps, weight, time accept non-negative valid values.
- `Add set` may copy previous set values to reduce input.
- Support weight=0 explicitly.
- Support time values.

**Acceptance criteria**
- Exercise can have 1 or many sets.
- Sets can differ from one another.
- Bodyweight/no-weight and time-based exercises can be represented without a separate tracking-type model.

**Spec references**
- Product Spec: Sets/Reps/Weight/Time, Workout Editing, Set Editing, Adding Multiple Sets.

**Dependencies**
- M2.6

---

### M2.8 `DONE` Implement workout edit/delete behavior
**Goal**
Make planned workouts fully maintainable.

**Requirements**
- Existing date workout can be edited.
- Deleting a workout requires confirmation.
- Editing incomplete sets updates Today immediately once Today exists.
- Completed actual values are not silently overwritten.

**Acceptance criteria**
- Changes persist locally/mock.
- Delete removes the date workout and Program returns to empty state.

**Dependencies**
- M2.7

---

### M2.9 `IN PROGRESS (PENDING CI)` Implement Copy Workout
**Goal**
Copy one date's plan to another date with minimal effort.

**Requirements**
- Source workout remains unchanged.
- User selects destination date.
- Copy exercises, order, sets, reps, weight, time.
- Do not copy completion, actual values, skipped state, or history.
- Destination becomes an independent workout.
- Handle occupied destination clearly; do not silently overwrite without explicit confirmation.

**Acceptance criteria**
- Editing copied Wednesday later does not change Monday source.
- Completion history is never copied.

**Spec references**
- Product Spec: Copy Workout.

**Dependencies**
- M2.8

---

### M2.10 `IN PROGRESS (PENDING CI)` Implement simple weekly Repeat Workout
**Goal**
Generate future independent workout copies without a recurring-template engine.

**Requirements**
- Options: 4 weeks, 8 weeks, until selected date.
- Generate concrete future workouts.
- Generated workouts are independent after creation.
- Detect occupied destination dates and handle them predictably; prefer explicit skip/confirm behavior over silent replacement.
- Avoid complex recurrence-rule abstractions.

**Acceptance criteria**
- Repetition creates expected dates only.
- Editing one generated workout does not propagate to others.

**Spec references**
- Product Spec: Repeat Workout.

**Dependencies**
- M2.9

---

### M2.11 `IN PROGRESS (PENDING CI)` Program UX checkpoint
**Goal**
Ensure planning remains understandable before implementing Today.

**Required reviews**
- `ios_ux_guardian`
- `product_spec_guardian`
- `architecture_guardian`
- `test_ci_agent`

**Acceptance criteria**
- A user can create a complete workout from an empty date using local/mock data.
- Copy and repeat pass tests.
- No unnecessary complexity leaks into Today assumptions.

---

## Milestone 3 — Today: protected core product experience

### M3.1 `IN PROGRESS (PENDING CI)` Implement active Today workout layout
**Goal**
Build the main product screen exactly around the checklist-first concept.

**Requirements**
- Header: Today + current date, kept visually quiet.
- Exercise sections are vertically scrollable.
- Each set is one row.
- Rows use M1.3 display formatting.
- No Start Workout button.
- No charts, stats, timers, PRs, calories, muscle diagrams, recommendations, or social content.
- Entire workout may be scrolled and sets completed in any order.

**Acceptance criteria**
- User sees enough information to know what to perform without entering another screen.
- Dense but readable layout works in Light and Dark system appearance even before custom settings implementation.

**Spec references**
- Product Spec: Today Screen, UI Priority, Main UX Rule.
- UX Spec: Today principles.

**Dependencies**
- M2.11

---

### M3.2 `IN PROGRESS (PENDING CI)` Implement one-tap set complete/undo
**Goal**
Make the primary interaction instantaneous.

**Requirements**
- One tap on incomplete set => completed immediately.
- One tap on completed set => incomplete immediately.
- No confirmation modal.
- No navigation.
- Preserve scroll position.
- Optional subtle haptic feedback.
- Support completing sets/exercises in arbitrary order.

**Acceptance criteria**
- Tap feedback feels immediate against local/mock repository.
- UI reflects actual values after completion.
- Undo is equally simple.

**Tests**
- Unit test state mutation.
- UI test complete/undo.
- UI test arbitrary-order completion.

**Spec references**
- TODAY-001..006, Haptic Feedback, AC-TODAY-02/03/05.

**Dependencies**
- M3.1, M1.4

---

### M3.3 `IN PROGRESS (PENDING CI)` Implement long-press set editor
**Goal**
Allow correction without polluting the main screen.

**Requirements**
- Long press on any set opens a compact editor, preferably bottom sheet/context-driven sheet.
- Incomplete set edits current planned values.
- Completed set edits actual values.
- Fields: reps, weight, time.
- Save returns directly to Today.
- Cancel changes nothing.
- Completed set remains completed after actual edit.
- Scroll position remains stable.
- Negative values rejected.

**Acceptance criteria**
- `☑ 8 reps × 60 kg` can become `☑ 6 reps × 60 kg` without leaving Today flow.
- Editing incomplete set is reflected consistently in Program.
- Editing completed actual does not rewrite plan history because no separate plan-history model exists.

**Tests**
- Unit tests for edit semantics.
- UI test completed-set edit.
- UI test incomplete-set edit.
- UI test cancel.

**Spec references**
- TODAY-010..013, Planned / Actual Model.

**Dependencies**
- M3.2

---

### M3.4 `IN PROGRESS (PENDING CI)` Implement Skip Exercise
**Goal**
Let users remove an exercise from the active Today flow without treating it as completed.

**Requirements**
- Secondary action via long press/header context or unobtrusive overflow.
- `Skip exercise` removes exercise from active Today list.
- Sets remain not completed.
- History preserves skipped state.
- No large permanent Skip button on every exercise card.

**Acceptance criteria**
- Skipping does not increment completed sets.
- Remaining workout continues normally.

**Spec references**
- TODAY-020..022.

**Dependencies**
- M3.1

---

### M3.5 `IN PROGRESS (PENDING CI)` Implement Restore Skipped Exercise
**Goal**
Recover accidental skips during the same day.

**Requirements**
- Provide unobtrusive access to skipped exercises, likely near the end of Today or a secondary menu.
- Restored exercise returns with original set completion state.
- Do not clutter default active workout layout.

**Acceptance criteria**
- Skip -> restore round trip works.
- Restored exercise remains incomplete unless sets had already been completed before skip.

**Spec references**
- TODAY-023.

**Dependencies**
- M3.4

---

### M3.6 `IN PROGRESS (PENDING CI)` Implement Today empty states
**Goal**
Handle no-program and rest-day cases cleanly.

**Requirements**
- No workouts anywhere/first-use state: `No workout planned yet.` + `Create workout` CTA.
- No workout on current date but user has other program data: `Rest day. See you tomorrow.` + `View program`.
- CTA navigates to Program appropriately.
- No unnecessary onboarding carousel.

**Acceptance criteria**
- Correct state chosen from repository data.
- CTA takes user to useful Program context.

**Spec references**
- First Launch, Rest Day, Empty States.

**Dependencies**
- M3.1

---

### M3.7 `IN PROGRESS (PENDING CI)` Implement workout completion popup
**Goal**
Celebrate completion without creating navigation friction.

**Requirements**
- Trigger only when whole workout becomes completed.
- Dismissible overlay/popup, not a separate navigation screen.
- Short emotional/memetic English message.
- Small animation/illustration placeholder acceptable initially.
- Dismiss returns to Today.
- Avoid repeated popup on every app open after already-completed workout unless behavior is explicitly justified.

**Acceptance criteria**
- Last required set triggers popup once for the completion transition.
- Skipped remaining exercise can still allow workout completion according to M1.5.
- Closing popup requires one simple action.

**Spec references**
- TODAY-030..032, Motivational Completion Popup, AC-COMPLETE-01.

**Dependencies**
- M3.2, M3.4, M1.5

---

### M3.8 `IN PROGRESS (PENDING CI)` Add Today accessibility and interaction identifiers
**Goal**
Make the protected core flow testable and accessible.

**Requirements**
- VoiceOver labels describe exercise/set and completion state.
- Completion not conveyed by color alone.
- Reasonable touch targets.
- Accessibility identifiers for UI tests.
- Dynamic Type does not make sets unusable at common accessibility sizes.

**Acceptance criteria**
- Critical UI tests use stable accessibility identifiers.
- VoiceOver review finds no blocking issue in main flow.

**Dependencies**
- M3.7

---

### M3.9 `IN PROGRESS (PENDING CI)` Today UX acceptance checkpoint
**Goal**
Protect the app's defining feature before backend integration.

**Required reviews**
- `ios_ux_guardian`
- `product_spec_guardian`
- `architecture_guardian`
- `code_quality_agent`
- `test_ci_agent`

**Acceptance criteria**
- Main scenario works end-to-end with local/mock data: Open -> Today -> tap sets -> completion popup.
- No unnecessary transitions were introduced.
- Complete/undo, long press, skip/restore, rest day, no-program states pass tests.
- CI green.
- Any blocking review findings fixed before M4.

---

## Milestone 4 — Firebase persistence and offline behavior

### M4.1 `IN PROGRESS (PENDING CI)` Add Firebase dependencies and safe configuration hooks
**Goal**
Prepare Firebase without committing credentials/secrets.

**Requirements**
- Firebase Authentication, Firestore, Analytics, Crashlytics dependencies as appropriate.
- `GoogleService-Info.plist` handling documented and excluded from unsafe publication if necessary.
- App must fail clearly in development if required config is missing.
- Do not hardcode secrets.

**Acceptance criteria**
- Project builds with dependency integration on CI using a safe strategy.
- Required user configuration is batched in `docs/progress.md` if external console setup is blocking.

**Dependencies**
- M3.9

---

### M4.2 `IN PROGRESS (PENDING CI)` Define repository protocols and Firestore mapping
**Goal**
Connect domain logic to persistence without coupling SwiftUI views directly to Firestore.

**Requirements**
- Repository interfaces for workouts, custom exercises, settings as needed.
- Mapping preserves date semantics and ordering.
- Views/ViewModels do not contain Firestore query code.

**Acceptance criteria**
- Local/mock and Firestore-backed repositories satisfy the same domain-facing contracts where practical.

**Dependencies**
- M4.1

---

### M4.3 `IN PROGRESS (PENDING CI/RULES)` Implement Firestore workout persistence
**Goal**
Persist Program/Today workout data per authenticated user.

**Requirements**
- Owner-scoped paths/documents.
- Store workouts by concrete date with child exercises/sets or equivalent approved schema.
- Persist order, skipped, completed, actual values.
- Preserve one-workout-per-date invariant.

**Acceptance criteria**
- Create/edit/delete workout persists.
- Today reads persisted current-date workout.
- Historical dates load correctly.

**Dependencies**
- M4.2

---

### M4.4 `IN PROGRESS (PENDING CI/RULES)` Implement Firestore custom exercise persistence
**Goal**
Persist user-created exercises while keeping system catalog bundled locally.

**Requirements**
- Custom exercises scoped to user.
- Search combines local system catalog + user custom exercises.
- Offline cached custom exercises remain usable after prior sync.

**Acceptance criteria**
- Custom exercise survives app restart/user session.

**Dependencies**
- M4.3

---

### M4.5 `IN PROGRESS (PENDING CI/RULES)` Implement Firestore UserSettings persistence
**Goal**
Persist theme and weight-unit preferences.

**Requirements**
- User-owned settings document.
- Defaults: sensible system appearance and kg unless spec/user later changes.
- Local app can read last known settings offline.

**Acceptance criteria**
- Settings survive restart and sync.

**Dependencies**
- M4.3

---

### M4.6 `IN PROGRESS (PENDING M5/LIVE/CI)` Verify and harden offline workout execution
**Goal**
Guarantee the app remains useful in a gym without network.

**Requirements**
- Cached Today loads offline.
- Completion/undo writes optimistically/local-first.
- Actual editing works offline.
- Skip/restore works offline.
- Program edits to cached data work offline where Firestore supports them.
- Changes sync automatically when connectivity returns.
- No manual Sync button.
- Network failure messaging is non-blocking when local data exists.

**Acceptance criteria**
- Test/manual test plan demonstrates airplane-mode flow after cache priming.
- Reconnect syncs changes without duplicate workout/set creation.

**Spec references**
- Offline Behaviour, Synchronisation Rules, AC-TODAY-06.

**Dependencies**
- M4.3

---

### M4.7 `IN PROGRESS (PENDING DEPLOYMENT/EMULATOR/CI)` Implement Firestore Security Rules
**Goal**
Ensure users can access only their own cloud data.

**Requirements**
- Owner-only access for user workout/settings/custom exercise documents.
- No unauthenticated access to user data.
- Rules align with actual schema.
- Add emulator/rules tests if practical.

**Acceptance criteria**
- User A cannot read/write User B data in tests/emulator validation.
- Required rules are documented for deployment.

**Dependencies**
- M4.3, M4.4, M4.5

---

### M4.8 `IN PROGRESS (PENDING CI/LIVE)` Firebase/offline checkpoint
**Goal**
Review persistence before adding auth UI.

**Required reviews**
- `firebase_data_guardian`
- `security_privacy_agent`
- `architecture_guardian`
- `test_ci_agent`

**Acceptance criteria**
- Offline contract passes.
- Security blockers resolved.
- No secret committed.
- CI green.

---

## Milestone 5 — Authentication and account routing

### M5.1 `IN PROGRESS (PENDING CI)` Implement email/password registration
**Goal**
Create accounts using Firebase Auth.

**Requirements**
- Email, password, confirm password.
- Validation and useful English errors.
- Successful registration routes directly to Today.
- No onboarding screens.

**Acceptance criteria**
- New user reaches Today empty state.
- Password mismatch/invalid input handled inline or non-disruptively.

**Dependencies**
- M4.8

---

### M5.2 `IN PROGRESS (PENDING CI)` Implement email/password sign-in and logout
**Goal**
Support returning users and account exit.

**Requirements**
- Sign-in form.
- Auth session routes to Today.
- Logout in Settings returns to auth screen.
- User data from previous account must not remain visibly attached to a new account session.

**Acceptance criteria**
- Sign in/out round trip works.
- Auth loading does not flash another user's workout content.

**Dependencies**
- M5.1

---

### M5.3 `IN PROGRESS (PENDING CI)` Implement password reset
**Goal**
Provide standard recovery for email accounts.

**Requirements**
- `Forgot password?` entry point.
- Email submission.
- Clear success/error feedback.

**Acceptance criteria**
- Reset request uses Firebase Auth correctly.

**Dependencies**
- M5.2

---

### M5.4 `IN PROGRESS (PENDING EXTERNAL)` Implement Google Sign-In
**Goal**
Add the approved secondary auth method.

**Requirements**
- Google sign-in integrated with Firebase Auth.
- Existing account/session behavior consistent with email login.
- External setup steps batched for the user if configuration is required.
- Do not add Sign in with Apple yet unless required to unblock testing; release requirement is handled in M8.

**Acceptance criteria**
- Google user reaches Today.
- Failure/cancel returns cleanly to auth screen.

**Dependencies**
- M5.2

---

### M5.5 `IN PROGRESS (PENDING CI)` Harden auth loading/error/account isolation
**Goal**
Make auth reliable without adding visual complexity.

**Requirements**
- Loading state while auth session resolves.
- No stale cross-account data display.
- Errors are human-readable and do not expose provider internals/tokens.
- Offline authenticated cached-user behavior is documented and sane.

**Acceptance criteria**
- Sign-out clears user-scoped observable state.
- Re-login reloads correct owner data.

**Dependencies**
- M5.4

---

### M5.6 `TODO` Auth/security checkpoint
**Required reviews**
- `security_privacy_agent`
- `firebase_data_guardian`
- `product_spec_guardian`
- `test_ci_agent`

**Acceptance criteria**
- Email/password + Google flows pass.
- Account isolation verified.
- No auth secrets/log leakage.

---

## Milestone 6 — History and Settings completion

### M6.1 `IN PROGRESS (PENDING CI)` Implement historical workout view in Program
**Goal**
Use the Program calendar as history.

**Requirements**
- Navigate to past dates.
- Show exercises/sets and completed/incomplete/skipped state.
- Show actual values for completed sets.
- Do not create a separate History tab.
- Do not add analytics/graphs.

**Acceptance criteria**
- Past workout can be inspected from weekly calendar navigation.

**Dependencies**
- M5.6

---

### M6.2 `TODO` Allow historical actual editing
**Goal**
Correct past workout results.

**Requirements**
- Completed historical actual reps/weight/time can be edited.
- Persist changes to Firestore/offline cache.
- Keep workout status consistent after edits.
- No historical planned-vs-actual comparison UI.

**Acceptance criteria**
- Edit persists after reopen.

**Dependencies**
- M6.1

---

### M6.3 `IN PROGRESS (PENDING CI)` Implement appearance setting
**Goal**
Support one design system with System/Light/Dark themes.

**Requirements**
- Settings choices: System, Light, Dark.
- Entire app responds consistently.
- No separate design variants.

**Acceptance criteria**
- Choice persists locally/cloud via UserSettings.
- Today remains readable in both themes.

**Dependencies**
- M4.5

---

### M6.4 `IN PROGRESS (PENDING CI)` Implement kg/lb setting
**Goal**
Switch weight display and editing units.

**Requirements**
- Settings choices: kg, lb.
- Display formatter updates everywhere.
- Define and document whether stored canonical weight is converted or values are stored in chosen unit; choose one consistent strategy and test it.
- Switching units must not corrupt existing data.

**Acceptance criteria**
- Today, Program, History show consistent unit.
- Round-trip switching does not produce material drift beyond chosen precision.

**Dependencies**
- M1.3, M4.5

---

### M6.5 `IN PROGRESS (PENDING CI)` Complete Settings/Account screen
**Goal**
Provide only the approved MVP settings.

**Requirements**
- Appearance.
- Weight unit.
- Account summary.
- Logout.
- App version/About links may be included if low-noise.
- No unnecessary preference switches.

**Acceptance criteria**
- Settings matches approved scope.

**Dependencies**
- M6.3, M6.4, M5.2

---

### M6.6 `TODO` Product-surface checkpoint
**Required reviews**
- `ios_ux_guardian`
- `product_spec_guardian`
- `code_quality_agent`
- `test_ci_agent`

**Acceptance criteria**
- Every approved MVP surface exists.
- No out-of-scope product area added.
- CI green.

---

## Milestone 7 — Quality, analytics, privacy, and regression hardening

### M7.1 `TODO` Add minimal Firebase Analytics events
**Goal**
Measure product funnel without collecting sensitive workout content.

**Required events**
- sign_up
- login
- workout_created
- workout_copied
- workout_repeat_created
- exercise_added
- custom_exercise_created
- set_completed
- set_uncompleted
- set_actual_edited
- exercise_skipped
- workout_completed

**Requirements**
- Do not log exercise names, weights, reps, emails, tokens, or free-form user workout content as event parameters unless explicitly approved.

**Acceptance criteria**
- Events are emitted at correct transitions, not merely screen renders.

**Dependencies**
- M6.6

---

### M7.2 `TODO` Add Crashlytics
**Goal**
Capture production crashes/non-fatal critical failures safely.

**Requirements**
- No sensitive auth/user workout content in crash custom keys/logs.
- Build/version symbol handling documented.

**Acceptance criteria**
- Integration compiles and initialization is safe with missing dev config where needed.

**Dependencies**
- M7.1

---

### M7.3 `TODO` Accessibility pass
**Goal**
Apply baseline iOS accessibility across all screens.

**Requirements**
- VoiceOver labels.
- Non-color-only states.
- Touch targets.
- Dynamic Type resilience.
- Focus/order sensible on auth, Today, Program editor, Settings.

**Acceptance criteria**
- No critical accessibility blocker in main flows.

**Dependencies**
- M7.2

---

### M7.4 `TODO` Offline/error/loading state pass
**Goal**
Make network/storage failures non-disruptive.

**Requirements**
- Cached Today remains interactive.
- Non-blocking sync/offline messaging.
- No raw Firebase errors in UI.
- Loading only where data is truly unavailable.
- Empty vs error states clearly distinguished.

**Acceptance criteria**
- Airplane mode and reconnect scenarios pass documented manual/automated checks.

**Dependencies**
- M7.3

---

### M7.5 `TODO` Expand regression test suite
**Goal**
Protect critical behavior before beta distribution.

**Required coverage**
- Date selection/day boundary.
- Display rules.
- Completion/undo.
- Actual edit.
- Skip/restore.
- Workout completion popup trigger.
- Create/edit/delete workout.
- Copy/repeat independence.
- History actual edit.
- Auth routing/account isolation.
- Offline repository behavior where testable.
- kg/lb behavior.

**Acceptance criteria**
- CI test suite is stable enough to gate PRs.

**Dependencies**
- M7.4

---

### M7.6 `TODO` Broad repository quality/security/product review
**Required reviews**
- `architecture_guardian`
- `ios_ux_guardian`
- `firebase_data_guardian`
- `security_privacy_agent`
- `code_quality_agent`
- `test_ci_agent`
- `product_spec_guardian`

**Acceptance criteria**
- Fix all high/critical findings and product-spec mismatches.
- Medium findings are fixed or explicitly documented with rationale.
- CI green.

---

## Milestone 8 — TestFlight readiness and iPhone beta distribution

### M8.1 `TODO` Verify current App Store authentication requirements
**Goal**
Resolve release compliance for third-party login.

**Requirements**
- Verify current Apple requirement for Google Sign-In and equivalent login options.
- Add Sign in with Apple if required for TestFlight/App Store compliance.
- Update Product Spec if this becomes mandatory release scope.

**Required agent**
- `release_appstore_agent`

**Acceptance criteria**
- Auth methods are release-compliant based on current Apple rules.

**Dependencies**
- M7.6

---

### M8.2 `TODO` Define app identity and release metadata baseline
**Goal**
Prepare signing/build identity.

**Requirements**
- Bundle identifier.
- Version/build numbering convention.
- App display name.
- App icon placeholder/final asset path.
- Minimum deployment target confirmed.

**Acceptance criteria**
- Release metadata documented.

**Dependencies**
- M8.1

---

### M8.3 `TODO` Apple Developer account/signing checkpoint — USER ACTION MAY BE REQUIRED
**Goal**
Obtain the external account/signing prerequisites for device/TestFlight distribution.

**Codex behavior**
- Batch all user actions into one checklist.
- Do not ask piecemeal questions across multiple tasks.
- Record the exact blocker in `docs/progress.md`. Stop only if the full remaining backlog scan finds no technically safe work without the external action; otherwise defer this task and continue safe work elsewhere.

**Acceptance criteria**
- Team/signing/provisioning path is known and available.

**Dependencies**
- M8.2

---

### M8.4 `TODO` Configure GitHub release secrets safely — USER ACTION MAY BE REQUIRED
**Goal**
Provide CI with only the secrets needed for signed archive/TestFlight upload.

**Requirements**
- Prefer App Store Connect API key or current recommended CI auth mechanism.
- Never commit credentials/certificates in plaintext.
- Document required GitHub Actions secrets/variables.

**Acceptance criteria**
- CI can access required signing/upload credentials without exposing them in logs.

**Dependencies**
- M8.3

---

### M8.5 `TODO` Add signed archive/export workflow
**Goal**
Build a distributable beta on macOS CI.

**Requirements**
- Archive app.
- Export signed IPA or upload artifact using current Apple-supported workflow.
- Separate normal simulator CI from release workflow.
- Release workflow should not run on every small commit unless intentionally configured.

**Acceptance criteria**
- CI produces a valid signed beta artifact/upload candidate.

**Dependencies**
- M8.4

---

### M8.6 `TODO` Automate TestFlight upload
**Goal**
Allow the user to get current beta builds on their iPhone without App Store publication.

**Requirements**
- Upload to App Store Connect/TestFlight.
- Document processing delay expectations and where to find build.
- Prefer Internal Testing first.
- Record exact workflow trigger.

**Acceptance criteria**
- At least one build appears in TestFlight for the user.

**Dependencies**
- M8.5

---

### M8.7 `TODO` Document iPhone beta update workflow
**Goal**
Make recurring physical-device testing trivial for the user.

**Requirements**
Document:
- how a new beta is generated;
- how the user sees it in TestFlight;
- how to install/update;
- how to report build number with bugs;
- what Codex should do when the user says a specific beta is broken.

**Acceptance criteria**
- User can update to the latest internal beta without App Store publication.

**Dependencies**
- M8.6

---

### M8.8 `TODO` TestFlight readiness checkpoint
**Required reviews**
- `release_appstore_agent`
- `security_privacy_agent`
- `test_ci_agent`

**Acceptance criteria**
- Signed pipeline is reproducible.
- No secrets leak.
- User can install a current build on iPhone.

---

## Milestone 9 — MVP acceptance and stable release preparation

### M9.1 `TODO` Run full product acceptance checklist
**Goal**
Validate every approved MVP scenario against `docs/product_spec.md`.

**Required scenarios**
- Register via email/password.
- Login via email/password.
- Google sign-in.
- Logout.
- First-use Today -> create workout.
- Create workout by concrete date.
- Add/search/custom exercise.
- Arbitrary sets/reps/weight/time.
- Copy workout.
- Repeat workout.
- Today one-tap complete/undo in arbitrary order.
- Long-press edit before/after completion.
- Skip and restore exercise.
- Rest day.
- Workout completion popup.
- Historical viewing/editing.
- Theme selection.
- kg/lb.
- Offline workout and reconnect sync.

**Acceptance criteria**
- All critical scenarios pass or have explicit blocking bug tasks created and fixed before release.

**Dependencies**
- M8.8

---

### M9.2 `TODO` Fix acceptance blockers and regressions
**Goal**
Resolve only issues that block approved MVP quality.

**Requirements**
- Do not opportunistically add future features.
- Add regression tests for fixed critical bugs.

**Acceptance criteria**
- M9.1 rerun passes.

**Dependencies**
- M9.1

---

### M9.3 `TODO` Produce MVP release notes and known limitations
**Goal**
Document what the beta/release does and deliberately does not do.

**Requirements**
- User-visible concise release notes.
- Technical known limitations in docs.
- Explicit future candidates remain out of scope.

**Dependencies**
- M9.2

---

### M9.4 `TODO` Prepare `dev -> main` release PR
**Goal**
Prepare stable/release integration only after explicit user approval.

**Requirements**
- Do not merge automatically.
- Include CI status, acceptance summary, known limitations, TestFlight build reference, and security/release review summary.

**Acceptance criteria**
- PR ready for user decision.

**Dependencies**
- M9.3

---

## Autonomous execution rules

1. Reconstruct actual state from Git/code/tests and `docs/progress.md` before selecting work.
2. Prefer the active `IN PROGRESS` task. If it is blocked, scan the entire remaining plan for another technically safe task instead of stopping at the first dependency chain.
3. Task bodies, acceptance criteria, and dependencies in this file remain authoritative. Runtime task status in `docs/progress.md` plus actual Git/code state wins if a header status here is stale.
4. For scheduling only, an implementation-complete dependency pending solely CI/live/external verification may be treated as provisionally satisfied when later implementation is safe without that missing evidence. This never makes the dependency `DONE` and never waives its acceptance criteria.
5. Read the full task body plus referenced Product/UX/Architecture sections and apply required agents from `agents/routing.toml`.
6. Mark active work accurately before substantial implementation.
7. Implement the smallest complete safe solution, add/update required tests, and run the strongest available verification.
8. Self-review against acceptance criteria, product scope, Today UX, architecture, security/privacy, offline behavior, and release rules. Fix established failures that can be resolved with available tools.
9. Mark `DONE` only when all required acceptance and verification genuinely pass. Otherwise keep an accurate pending state such as `PENDING CI`, `PENDING LIVE`, or `PENDING EXTERNAL`.
10. Update `docs/progress.md` after each meaningful checkpoint and make a focused commit when possible.
11. Immediately continue to the next technically safe action. A task completion, milestone completion, commit, push, review, CI result, progress update, or known `Next:` action is not a stopping point.
12. If the current task needs credentials, external configuration, live validation, or unavailable verification, finish every safe local part, record the deferred action, scan the full remaining backlog, and continue independent safe work.
13. Stop only when all planned work is complete, the platform/model/tool limit actually ends execution, or no technically safe backlog work remains anywhere and one genuine terminal condition from `AGENTS.md` applies.
14. Do not wait for or request a routine user `continue` message. A later fresh Desktop Codex task, if the platform itself forces an interruption, must reconstruct state from Git/docs and resume without asking the user to restate context.

## Future candidates — never implement automatically
- Exercise images/videos/instructions.
- Rest timer.
- Progress graphs, PR analytics, body measurements.
- Apple Watch / HealthKit.
- AI workout generation, coaching, recommendations.
- Social, sharing, leaderboards, challenges.
- Subscription/payments.
- Multiple workouts per day.
- Android or web client.
