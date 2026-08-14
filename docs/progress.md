# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 2 — Exercise catalog and Program planning UX (local/mock persistence first).

## Active task
`M2.1` — Add the bundled English system exercise catalog and case-insensitive offline search.

## Published state
- Authoritative `iOS CI / build-and-test` run `31803547147`, attempt 2, passed for commit `56c8e28` on `dev`.
- M0.1–M0.6 are `DONE`; the Milestone 0 bootstrap checkpoint is complete.
- M1.1–M1.6 are `DONE`; the Milestone 1 domain checkpoint is complete.
- Current branch: `dev`; local HEAD and `origin/dev` are `56c8e28` before M2.1 edits.

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

## Verification status
- Authoritative Milestone 0 macOS CI: PASS for published commit `7fe85bd` on `dev` (user-confirmed).
- Milestone 1 macOS CI: PASS for commit `56c8e28`, run `31803547147` attempt 2. All 11 unit tests and the UI smoke test passed. Attempt 1 had a transient simulator app-launch timeout after all unit tests passed; rerunning the failed job succeeded without code changes.
- Milestone 1 temporary Swift Package test execution on Linux: PASS, 11 tests, 0 failures.
- `swiftc -typecheck GymChecklist/Core/Models/*.swift GymChecklist/Core/Utilities/*.swift`: PASS.
- Test source type-check against an emitted `GymChecklist` module: PASS.
- Xcode project membership/static syntax, shared scheme XML, workflow YAML, and `git diff --check`: PASS.
- M2.1 Windows static checks: PASS for catalog/category/scope assertions, explicit Xcode app-target membership, catalog test presence, shared scheme XML, and `git diff --check`.
- `swiftc` and `xcodebuild` are unavailable on this Windows host. M2.1 authoritative macOS build/tests are pending publication.

## Agent reviews
- `architecture_guardian`: PASS; no blocking findings, Firebase/UI leakage, duplicated status source, or premature repository abstraction.
- `product_spec_guardian`: PASS after completed-payload validation, combined weighted/time display, and per-user/date uniqueness fixes.
- `test_ci_agent`: PASS; diagnosed missing app-target Debug testability, confirmed the focused fix, and verified the existing domain tests were sufficient regression coverage.
- M2.1 `architecture_guardian`, `product_spec_guardian`, and `test_ci_agent`: PASS; no blocking findings or scope drift.
- M2.1 completion code review: no critical findings; checkpoint accuracy and complete stable-ID coverage were fixed before publication.

## Blockers
None for M2.1.

## Exact next action
Commit and push M2.1, verify the authoritative macOS `iOS CI / build-and-test` run, mark M2.1 `DONE`, and begin M2.2 automatically.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
