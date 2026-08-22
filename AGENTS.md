# AGENTS.md

## Project
Gym Checklist (`akrasnoslov-dev/Gym_checklist`). Native iOS app for executing pre-planned gym workouts with minimal interaction.

Core product invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

Do not add friction, analytics, coaching, timers, social features, or other unapproved scope to the workout flow.

## Mandatory context
Before any non-trivial task, read:
- `AGENTS.md`
- `docs/codex_instructions.md`
- `docs/product_spec.md`
- `docs/ux_spec.md`
- `docs/architecture.md`
- `docs/implementation_plan.md`
- `docs/progress.md`
- `docs/ci_free_quota_policy.md` when present
- `agents/routing.toml`

Then inspect relevant source/tests, Git state, available CI state, and applicable `agents/*.toml` instructions.

## Source of truth
1. Explicit current user instruction.
2. `docs/product_spec.md` for approved behavior.
3. `docs/ux_spec.md` for approved UX.
4. `docs/architecture.md` for technical boundaries.
5. `docs/implementation_plan.md` for ordered execution.
6. `docs/progress.md` for current checkpoint/state.
7. `docs/ci_free_quota_policy.md` for the user-approved no-paid-CI continuation exception.

Do not silently change product behavior to make implementation easier.

## Autonomous implementation contract
For every task:
1. Read the entire task body and all referenced Product/UX/Architecture sections.
2. Inspect dependencies and current verification state.
3. Apply required agents from `agents/routing.toml`.
4. Mark the task `IN PROGRESS` and update `docs/progress.md` before substantial edits.
5. Implement the smallest complete solution.
6. Add/update required tests.
7. Run the strongest verification actually available.
8. Self-review against all acceptance criteria and relevant product/UX/architecture/security/offline rules.
9. Fix established failures.
10. Mark `DONE` only when required acceptance and verification genuinely pass.
11. Update `docs/progress.md` with exact verification, branch/commit state, blockers, and next action.
12. Make a focused checkpoint commit.
13. Continue automatically to the next technically safe task unless a genuine blocker exists.

Do not mark work `DONE` merely because code exists.

## No-cost CI quota exception
The user has explicitly chosen not to pay for additional GitHub Actions usage.

When GitHub-hosted macOS CI is unavailable **solely because the included Actions quota is exhausted**, `docs/ci_free_quota_policy.md` applies:
- treat this as verification unavailable, not a code failure;
- keep affected tasks/checkpoints `IN PROGRESS (PENDING CI)`;
- run all available non-macOS/static/deterministic checks;
- for scheduling only, treat implementation-complete dependencies/checkpoints pending solely on quota-blocked CI as provisionally satisfied;
- continue across milestone boundaries when technically safe;
- never claim the missing CI passed;
- reconcile pending verification with authoritative macOS CI once free capacity returns.

This exception overrides generic `dependencies must be DONE` and milestone-checkpoint stop rules only for deciding whether safe implementation may continue. Acceptance criteria and the definition of `DONE` are unchanged.

Do not ask the user to enable paid Actions, buy GitHub Pro, add a payment method, rent a Mac runner, or pay another CI provider merely to continue normal development.

A **real** CI run that starts and reports an actual build/test failure is not covered by this exception and must be treated as an engineering failure.

## Default Codex workflow
- Work from `dev` or a focused `feature/*` based on `dev`; never normal development directly on `main`.
- Resume the active `IN PROGRESS` task from repository state.
- A task/checkpoint pending only on quota-blocked CI may be provisionally crossed under the no-cost policy.
- Keep changes focused on the active task plus strictly necessary support.
- On Windows/Linux, run available static checks but never claim Xcode verification.
- Keep `docs/progress.md` current.
- Continue sequentially without asking approval for routine reversible engineering decisions.
- If the user says `continue`, reconstruct state from the repository and resume.

Stop only for a genuine blocker: material product ambiguity, unavailable required credentials/configuration, destructive/irreversible choice, actual failure that makes continuation unsafe, unavailable required tools with no safe work left, or exhausted model/tool limits.

## Session continuity
The repository, not chat history, is durable project memory.

`docs/progress.md` must record enough for a brand-new Codex session to resume safely: current branch, active task, last verified checkpoint, pending-CI work, available verification state, blockers, and exact next action.

Prefer small checkpoint commits. If context becomes unreliable, finish the smallest safe atomic unit and checkpoint it before moving sessions.

## Product rules
- English only for MVP.
- Top-level navigation: Today / Program / Settings.
- Today opens first after authentication.
- One tap completes a set; tapping again undoes completion.
- No Start Workout flow.
- Sets/exercises may be completed in any order.
- Long press opens compact set editing.
- Skip Exercise removes it from active Today but preserves skipped/incomplete history; restore must be possible.
- One workout maximum per concrete local calendar date.
- Copy creates an independent workout.
- Weekly repeat generates independent future workouts; no complex recurring-template engine.
- History lives in Program and historical actual values may be edited.
- No historical planned-vs-actual analytics snapshot model in MVP.
- Offline workout execution is mandatory.
- kg/lb supported.
- System/Light/Dark use one design system.
- Completion motivation appears only after the whole workout finishes as a dismissible overlay/popup.

## Today UX invariant
Today must remain visually quiet. Do not add charts, statistics, progress dashboards, PRs, calories, timers, recommendations, muscle diagrams, feeds, or other secondary information.

Each set is one readable row, e.g.:
- `8 reps × 60 kg`
- `12 reps`
- `45 sec`

Display rules hide technical zero/placeholder values that do not help the user.

## Architecture
Target stack:
- Swift + SwiftUI
- feature-oriented MVVM
- repository/service boundaries for persistence/auth
- Firebase Authentication
- Cloud Firestore with offline persistence
- Firebase Analytics
- Firebase Crashlytics
- locally bundled system exercise catalog

Avoid over-engineered Clean Architecture, custom backend services, dependency frameworks, or speculative abstractions.

## Data rules
Core entities: User/UserSettings, Exercise, Workout, WorkoutExercise, WorkoutSet.
- Workout date is a local calendar date; operation timestamps are absolute.
- Before completion, set values are current planned values.
- On completion, actual values are initialized from current values.
- Actual values remain editable.
- Program edits affect incomplete sets immediately.
- Do not silently overwrite completed actual values.

## Offline rules
- Cached Today remains usable without network.
- Completion/undo, actual editing, skip/restore apply locally immediately.
- Sync recovers automatically when connectivity returns.
- No manual Sync button.
- Do not claim offline support complete before its explicit acceptance checkpoint passes.

## Security/privacy
- User cloud data must be owner-scoped.
- Never log passwords, auth tokens, Firebase credentials, signing secrets, or unnecessary private workout content.
- Do not commit secrets/configuration containing credentials.
- Firestore Security Rules are required before production use.
- Never weaken security to make tests pass.

## Agent workflow
Agent instructions live in `agents/*.toml`; routing is in `agents/routing.toml`.
Available roles include `architecture_guardian`, `ios_ux_guardian`, `firebase_data_guardian`, `security_privacy_agent`, `code_quality_agent`, `test_ci_agent`, `release_appstore_agent`, and `product_spec_guardian`.

Required checkpoint agents must be applied before a checkpoint can ultimately become `DONE`. High/critical findings must be fixed. Medium findings must be fixed or explicitly justified where the task permits.

## Verification
Authoritative iOS build/test verification requires a real macOS/Xcode environment. GitHub Actions macOS is the normal authoritative path when free quota is available.

On Windows/Linux:
- run available static/repository checks;
- never claim Xcode build/test passed;
- record unavailable authoritative verification as pending when appropriate.

Real CI failures block completion of tasks whose acceptance requires them. Quota-blocked CI follows `docs/ci_free_quota_policy.md`.

## Branching
- `main`: stable/release only.
- `dev`: integration/default development branch.
- `feature/*`: focused implementation when useful.
- PRs target `dev` by default.
- `dev -> main` only for explicit release.
- Do not auto-merge unless explicitly requested.
- Do not delete or overwrite uncommitted user work.

## Documentation discipline
Update docs when behavior, architecture, setup, verification, CI, Firebase contracts, or release process changes.

`docs/progress.md` is the continuity checkpoint. `docs/implementation_plan.md` remains the ordered backlog; do not weaken its acceptance criteria to match temporary environment limitations.