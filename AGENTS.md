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

## Continuous execution contract
A Codex implementation run is a continuous backlog-execution loop, not a one-task interaction.

The user's intended operating mode is: provide one master prompt, then let Codex continue autonomously through every technically safe backlog item until a genuine hard stop or model/tool usage limit occurs.

Therefore:
- Completing a task is not a stopping point.
- Completing a milestone is not a stopping point.
- Creating a commit is not a stopping point.
- Updating `docs/progress.md` is not a stopping point.
- Finishing required agent reviews is not a stopping point.
- Reaching a known `Next:` action is not a stopping point when that action can be executed now.
- macOS CI being unavailable solely because free GitHub Actions quota is exhausted is not a stopping point.
- A long session, context compaction, or a desire to give the user a progress summary is not by itself a stopping point.

After every atomic checkpoint, immediately select and begin the next technically safe backlog action. Do not wait for the user to say `continue`, approve routine work, or re-send the master prompt.

Status summaries may be produced only as intermediate progress updates while work continues. A summary such as `M4.1 checkpointed; next add Firebase dependencies` must not be used as the final response if adding those dependencies is technically safe now.

## Final-response gate
Before producing any final response, perform this gate explicitly in your own reasoning:

1. Re-read the current task state in `docs/progress.md` and inspect the actual Git/worktree state. If they disagree, treat Git/code as evidence of what was actually implemented and repair `docs/progress.md`.
2. Determine the exact next backlog action.
3. Ask: `Can I execute this action now, safely, with the tools/configuration currently available?`
4. If YES, a final response is prohibited. Execute the next action instead.
5. If NO, determine whether another technically safe backlog action is permitted by the specifications and dependency rules. If one exists, execute it instead of stopping.
6. A final response is allowed only when at least one genuine stop condition below is true and no safe continuation remains.

Allowed genuine stop conditions:
- `USER_ACTION_REQUIRED`: external credentials/configuration/account action is required and cannot be completed from the repository or available tools.
- `PRODUCT_DECISION_REQUIRED`: a material product ambiguity cannot be resolved from authoritative specifications.
- `DESTRUCTIVE_APPROVAL_REQUIRED`: a destructive or irreversible action needs explicit approval.
- `REAL_FAILURE_BLOCKS_CONTINUATION`: an actual build/test/implementation failure makes dependent work unsafe and cannot be resolved with available tools.
- `REQUIRED_TOOL_UNAVAILABLE`: a genuinely required tool/environment is unavailable and no technically safe work remains.
- `MODEL_OR_TOOL_LIMIT`: platform/model/tool usage limits prevent further execution in the current run.

When stopping, record the exact stop-condition label, evidence, and exact resume action in `docs/progress.md`, checkpoint all coherent work, then summarize. Do not invent a blocker merely to end the run.

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
13. Immediately loop to the next technically safe task. Do not emit a final response between routine tasks/checkpoints.

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

## CI cost-control default
The no-cost strategy is permanent, not only a quota-emergency fallback.

- Normal code/configuration checkpoints use `.github/workflows/linux-checks.yml` on Linux.
- Do not put `[macos-ci]` in routine checkpoint commits.
- `.github/workflows/ios-ci.yml` is authoritative but intentionally sparse. It runs for `[macos-ci]` checkpoint commits, manual dispatch, and release PRs targeting `main`.
- Use `[macos-ci]` at milestone/checkpoint verification or earlier only when continuing safely requires real Xcode evidence.
- Prefer one consolidated macOS run over separate runs for every task.
- Docs-only changes should not trigger automatic CI.
- `cancel-in-progress: true` is intentional; newer runs should supersede obsolete runs on the same ref.
- Linux success is not equivalent to macOS/Xcode success and cannot satisfy acceptance criteria that explicitly require authoritative macOS verification.

## Default Codex workflow
- Work from `dev` or a focused `feature/*` based on `dev`; never normal development directly on `main`.
- Resume the active `IN PROGRESS` task from repository state.
- A task/checkpoint pending only on quota-blocked CI may be provisionally crossed under the no-cost policy.
- Keep changes focused on the active task plus strictly necessary support.
- On Windows/Linux, run available static checks but never claim Xcode verification.
- Keep `docs/progress.md` current after every atomic checkpoint, not only at the end of the run.
- Continue sequentially without asking approval for routine reversible engineering decisions.
- Never require the user to send `continue` while the current run can still execute safe work.
- If execution is resumed after a platform interruption, reconstruct state from the repository and continue without asking the user to restate context.

Stop only under the Final-response gate above.

## Session continuity
The repository, not chat history, is durable project memory.

`docs/progress.md` must record enough for a brand-new Codex session to resume safely: current branch, active task, last verified checkpoint, pending-CI work, available verification state, blockers, and exact next action.

Prefer small checkpoint commits. If context is compacted or seems incomplete, re-read Git history and the mandatory context files, repair your state model, and continue. Do not stop merely because the session is long or context was compacted. Stop for context reasons only if reliable reconstruction is genuinely impossible and further edits would be unsafe; classify that under `REQUIRED_TOOL_UNAVAILABLE` or `MODEL_OR_TOOL_LIMIT` as appropriate.

Do not discard or reset coherent local commits merely because `origin/dev` is behind. Local repository state may be newer than GitHub during a Codex Local task.

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

`docs/progress.md` is the continuity checkpoint. It must reflect the actual latest local implementation state at every checkpoint. `docs/implementation_plan.md` remains the ordered backlog; do not weaken its acceptance criteria to match temporary environment limitations.
