# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 2 — Exercise catalog and Program planning UX (local/mock persistence first).

## Active task
`M2.6` — Add persistent delete and reorder controls for each selected-date workout's ordered exercise list.

## Published state
- Authoritative `iOS CI / build-and-test` run `31803547147`, attempt 2, passed for commit `56c8e28` on `dev`.
- M0.1–M0.6 are `DONE`; the Milestone 0 bootstrap checkpoint is complete.
- M1.1–M1.6 are `DONE`; the Milestone 1 domain checkpoint is complete.
- Current branch: `dev`; local HEAD and `origin/dev` are `f13e385` before M2.6 edits.
- M2.2 is published as commit `0d3471d` on `dev`.
- M2.3 is published as commit `d0e9fc1` on `dev`.
- M2.4 is published as commit `045f8ae` on `dev`.
- M2.5 is published as commit `f13e385` on `dev`.

## Milestone 1 implementation
- Foundation-only domain entities cover UserSettings, Exercise, Workout, WorkoutExercise, and WorkoutSet with typed identifiers, explicit ordering, skip state, and Codable support.
- LocalDate stores validated calendar components independently from absolute timestamps and supports deterministic day/week navigation.
- Reusable set formatting covers kg/lb, weighted, reps-only, time-only, and combined meaningful values without displaying technical zero weight.
- WorkoutSet transitions centralize completion snapshots, deterministic undo, plan editing, and completed actual editing; invalid completed payloads are rejected during decoding.
- Workout completion/calendar status rules cover planned, partial, completed, past incomplete, empty, zero-set, and explicitly skipped cases.
- WorkoutDateKey and WorkoutScheduleRules enforce one workout per user/local date without Firebase coupling.

## M2.1 implementation
- A compiled immutable catalog provides 34 deterministic English system exercises across Chest, Back, Legs, Shoulders, Biceps, Triceps, Core, and Cardio/Other without network or resource decoding.
- Stable UUIDs, deterministic order, `isSystem = true`, and no owning user make entries safe for later workout references.
- Local in-memory search trims whitespace, matches exercise-name substrings case-insensitively, returns the full catalog for an empty query, and returns an empty result for no match.
- Focused tests cover category breadth, catalog size, ownership flags, unique/stable IDs and names, mixed-case/trimmed search, deterministic ordering, empty queries, and no-match queries.

## M2.2 implementation
- A user-scoped `LocalExerciseLibrary` value type retains custom exercises locally without introducing the repository protocols reserved for M4.2.
- Creation trims and collapses whitespace, rejects empty names, normalizes blank categories to nil, assigns the current owner, and prevents callers from supplying ownership/system flags.
- Exact normalized matches reuse an existing system or owner-scoped custom exercise; similarly named exercises remain allowed.
- Combined local search preserves bundled order followed by custom insertion order and cannot expose another library owner's custom entries.
- Focused tests cover validation, ownership, category normalization, reuse, similar names, combined search, deterministic ordering, empty/no-match queries, and user isolation.

## M2.3 implementation
- Program now opens a locale-aware seven-date week centered on the selected concrete local date, with unbounded previous/next week navigation that preserves the weekday.
- Quiet, shape-distinct status markers derive from the existing workout calendar rules; absence of a workout remains a feature-only empty state.
- The selected date is repeated in full and drives the content below. Empty dates expose an enabled `Create workout` intent without adding the persistence owned by M2.4.
- Accessibility labels expose full dates, selection, and textual status; deterministic UI launch state covers week navigation and date selection.

## M2.4 implementation
- An owner-scoped `WorkoutRepository` boundary and in-memory implementation enforce one workout per `WorkoutDateKey`, return existing workouts idempotently, and reject cross-owner or identity/date collisions.
- New workouts receive repository-owned user/date identity, an injected ID and timestamp, and an empty ordered exercise list; save/update preserves the original creation timestamp.
- A single observable Program model owns selection and the current repository snapshot, so creation immediately replaces the empty-date CTA with a planned empty-workout state while leaving adjacent dates untouched.
- Focused unit and UI coverage exercises creation, duplicate idempotency, distinct dates and owners, save protections, immediate selected-date refresh, and tab/week navigation regression.

## M2.5 implementation
- Program exposes `Add exercise` only for an existing selected-date workout and presents a native searchable picker over the long-lived owner-scoped local exercise library.
- Bundled and custom results are searched together; selecting a result appends an ordered empty workout-exercise entry through the repository and returns directly to the same date.
- The secondary custom flow prefills a missing search, validates the required name, reuses normalized exact matches, retains genuinely new custom exercises, adds the result, and dismisses without an extra confirmation screen.
- The returned editor state resolves system/custom names without adding set editing, reorder/delete controls, media, category filters, or Today changes.

## M2.6 implementation
- Program now uses a native sectioned list for the selected-date editor, with Edit-mode drag reordering, swipe deletion, and accessible per-row move/delete actions keyed by stable workout-exercise identity.
- View-model mutations are scoped to a concrete `LocalDate`, validate exact ID permutations, preserve full exercise/set payloads, normalize contiguous order, save through the repository, and refresh only after success.
- Deleting removes only the selected workout-exercise aggregate; re-adding uses the existing picker and produces a fresh entry at the end without changing the exercise library or neighboring dates.
- Focused tests cover persisted reorder from legacy order gaps, payload preservation, invalid-order rollback, deletion compaction, typed missing-entry errors, independent re-add identity, and cross-date isolation.

## Verification status
- Authoritative Milestone 0 macOS CI: PASS for published commit `7fe85bd` on `dev` (user-confirmed).
- Milestone 1 macOS CI: PASS for commit `56c8e28`, run `31803547147` attempt 2. All 11 unit tests and the UI smoke test passed. Attempt 1 had a transient simulator app-launch timeout after all unit tests passed; rerunning the failed job succeeded without code changes.
- Milestone 1 temporary Swift Package test execution on Linux: PASS, 11 tests, 0 failures.
- `swiftc -typecheck GymChecklist/Core/Models/*.swift GymChecklist/Core/Utilities/*.swift`: PASS.
- Test source type-check against an emitted `GymChecklist` module: PASS.
- Xcode project membership/static syntax, shared scheme XML, workflow YAML, and `git diff --check`: PASS.
- M2.1 Windows static checks: PASS for catalog/category/scope assertions, explicit Xcode app-target membership, catalog test presence, shared scheme XML, and `git diff --check`.
- M2.1 macOS CI: PASS for commit `765c237`, run `31805329059` attempt 1; all unit tests and the UI smoke test passed.
- M2.2 Windows static checks: PASS for local API/ownership/duplicate/search assertions, explicit Xcode app-target membership, focused test presence, shared scheme XML, and `git diff --check`.
- M2.2 macOS CI: PASS for commit `0d3471d`, run `31806340413` attempt 1; all unit tests and the UI smoke test passed.
- M2.3 Windows static checks: PASS for deterministic calendar/status test presence, explicit Xcode app-target membership, updated UI smoke coverage, shared scheme XML, and `git diff --check`.
- M2.3 macOS CI: PASS for commit `d0e9fc1`, run `31807783466` attempt 1; the full build, unit-test, and simulator UI-test job passed.
- M2.4 Windows static checks: PASS for repository ownership/date-key assertions, deterministic test and UI flow presence, explicit Xcode membership for all three new sources, shared scheme XML, and `git diff --check`.
- M2.4 macOS CI: PASS for commit `045f8ae`, run `31809202522` attempt 1; the full build, unit-test, and simulator UI-test job passed.
- M2.5 Windows static checks: PASS for combined search/custom integration assertions, ordered repository-add mapping, typed missing-workout handling, picker PBX membership, shared scheme XML, focused UI-flow presence, and `git diff --check`.
- M2.5 macOS CI: PASS for commit `f13e385`, run `31810779194` attempt 1; the full build, unit-test, and simulator picker/custom flow passed.
- M2.6 Windows static checks: PASS for stable-ID mutation APIs, reorder/delete persistence assertions, cross-date and re-add coverage, native List edit-control presence, shared scheme XML, and `git diff --check`.
- `swiftc` and `xcodebuild` are unavailable on this Windows host. M2.6 authoritative macOS build/tests are pending publication.
- M2.6 initial macOS CI run `31812569305`: FAILURE in the UI regression because the stable row accessibility identifier masked its child exercise-name identifier; build/unit execution reached the UI flow, and the row now explicitly contains child accessibility elements before republishing.
- M2.6 replacement run `31813267131`: UI flow passed custom add, reorder, delete, and per-date persistence, then failed because the converted List had virtualized the offscreen seven-date row before the next-week assertion; the test now scrolls back to the week selector before checking Aug 21.

## Agent reviews
- `architecture_guardian`: PASS; no blocking findings, Firebase/UI leakage, duplicated status source, or premature repository abstraction.
- `product_spec_guardian`: PASS after completed-payload validation, combined weighted/time display, and per-user/date uniqueness fixes.
- `test_ci_agent`: PASS; diagnosed missing app-target Debug testability, confirmed the focused fix, and verified the existing domain tests were sufficient regression coverage.
- M2.1 `architecture_guardian`, `product_spec_guardian`, and `test_ci_agent`: PASS; no blocking findings or scope drift.
- M2.1 completion code review: no critical findings; checkpoint accuracy and complete stable-ID coverage were fixed before publication.
- M2.2 `architecture_guardian`, `product_spec_guardian`, and `test_ci_agent`: PASS; the implementation remains local/user-scoped and defers picker UI and persistence protocols to their scheduled tasks.
- M2.2 completion review ownership finding fixed: an explicit `init(userID:)` prevents synthesized seeding of arbitrary or cross-owner custom entries.
- M2.3 `architecture_guardian`, `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent`: PASS; navigation has one date source of truth, reuses domain status rules, remains calendar-centric, and includes deterministic accessibility/UI coverage.
- M2.4 `architecture_guardian`, `firebase_data_guardian`, `security_privacy_agent`, `code_quality_agent`, `test_ci_agent`, `product_spec_guardian`, and `ios_ux_guardian`: PASS on the owner-scoped, idempotent local repository and immediate Program state-flow design; no Firebase or later editor scope was added.
- M2.5 `architecture_guardian`, `code_quality_agent`, `test_ci_agent`, `product_spec_guardian`, and `ios_ux_guardian`: PASS on the long-lived exercise-library ownership, one-tap result return, custom fallback/reuse flow, storage-agnostic picker UI, and later-editor scope boundary.
- M2.6 `architecture_guardian`, `code_quality_agent`, `test_ci_agent`, `product_spec_guardian`, and `ios_ux_guardian`: PASS on concrete-date stable-ID mutations, contiguous order normalization, native list controls, per-date isolation, and the M2.7+ scope boundary.

## Blockers
None for M2.6.

## Exact next action
Complete M2.6 code review, commit and push, verify macOS CI, mark M2.6 `DONE`, and continue automatically with M2.7.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
