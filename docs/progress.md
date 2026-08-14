# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 1 — Core domain model and business rules.

## Active task
`M1.6` — Domain checkpoint. M1.1–M1.5 are implemented and provisionally satisfied, but the milestone remains `IN PROGRESS (PENDING CI)` until the published batch passes authoritative macOS CI.

## Published state
- User confirmed the authoritative `iOS CI / build-and-test` workflow passed for commit `7fe85bd` on `dev`.
- M0.1–M0.6 are `DONE`; the Milestone 0 bootstrap checkpoint is complete.
- Current Cloud branch: `work`; Milestone 1 changes are not yet published.

## Milestone 1 implementation
- Foundation-only domain entities cover UserSettings, Exercise, Workout, WorkoutExercise, and WorkoutSet with typed identifiers, explicit ordering, skip state, and Codable support.
- LocalDate stores validated calendar components independently from absolute timestamps and supports deterministic day/week navigation.
- Reusable set formatting covers kg/lb, weighted, reps-only, time-only, and combined meaningful values without displaying technical zero weight.
- WorkoutSet transitions centralize completion snapshots, deterministic undo, plan editing, and completed actual editing; invalid completed payloads are rejected during decoding.
- Workout completion/calendar status rules cover planned, partial, completed, past incomplete, empty, zero-set, and explicitly skipped cases.
- WorkoutDateKey and WorkoutScheduleRules enforce one workout per user/local date without Firebase coupling.

## Verification status
- Authoritative Milestone 0 macOS CI: PASS for published commit `7fe85bd` on `dev` (user-confirmed).
- Milestone 1 macOS CI run `31802308423` for commit `03c6ead` failed because the app Debug configuration omitted `ENABLE_TESTABILITY`, so `@testable import GymChecklist` could not import the emitted module. The focused project-setting fix is in progress and requires a new authoritative run.
- Milestone 1 temporary Swift Package test execution on Linux: PASS, 11 tests, 0 failures.
- `swiftc -typecheck GymChecklist/Core/Models/*.swift GymChecklist/Core/Utilities/*.swift`: PASS.
- Test source type-check against an emitted `GymChecklist` module: PASS.
- Xcode project membership/static syntax, shared scheme XML, workflow YAML, and `git diff --check`: PASS.
- `xcodebuild` is unavailable in this Linux environment. Authoritative macOS CI for the new Milestone 1 batch is `PENDING EXTERNAL CI`.

## Agent reviews
- `architecture_guardian`: PASS; no blocking findings, Firebase/UI leakage, duplicated status source, or premature repository abstraction.
- `product_spec_guardian`: PASS after completed-payload validation, combined weighted/time display, and per-user/date uniqueness fixes.
- `test_ci_agent`: PASS for available checks and coverage; external macOS CI remains the only checkpoint gate.

## Blockers
Milestone 1 remains gated on publishing the `ENABLE_TESTABILITY` fix and obtaining a green replacement macOS CI run.

## Exact next action
Commit and push the focused project-setting fix, verify the replacement `iOS CI / build-and-test` run, then mark M1.1–M1.6 `DONE` and begin M2.1.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
