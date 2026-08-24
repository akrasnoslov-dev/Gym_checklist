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
- `docs/desktop_continuation_policy.md` when present
- `agents/routing.toml`

Then inspect relevant source/tests, Git/worktree state, available CI state, and applicable `agents/*.toml` instructions.

## Source of truth
1. Explicit current user instruction.
2. `docs/product_spec.md` for approved behavior.
3. `docs/ux_spec.md` for approved UX.
4. `docs/architecture.md` for technical boundaries.
5. `docs/implementation_plan.md` for task definitions, dependencies, and acceptance criteria.
6. Actual Git/code/tests plus `docs/progress.md` for current runtime status/checkpoint.
7. `docs/desktop_continuation_policy.md` for ChatGPT Desktop execution mechanics.
8. `docs/ci_free_quota_policy.md` for the user-approved no-paid-CI policy.

If a task status label in `docs/implementation_plan.md` is stale, reconcile it to actual Git/code and `docs/progress.md`; never discard coherent implementation just to match an old label.

## Desktop-only execution
Normal autonomous development runs in Codex inside the ChatGPT desktop app.

Do not require a CLI, PowerShell supervisor, Python watchdog, or scheduled-task heartbeat for normal execution.

The intended mode is one master prompt, then continuous execution for as long as the Desktop Codex task itself can run.

## Continuous execution contract
A Codex implementation run is a continuous backlog-execution loop, not a one-task interaction.

The following are **not** stopping points:
- a task completed;
- a milestone completed;
- a commit or push completed;
- `docs/progress.md` was updated;
- required agent reviews completed;
- a CI run completed or verification is pending;
- a known `Next:` action exists;
- one task is blocked by external configuration;
- local Xcode is unavailable on Windows/Linux;
- Codex wants to provide a progress summary.

After every atomic checkpoint, immediately determine and begin the next technically safe backlog action.

## Blocked task != blocked run
If one task needs external configuration, credentials, live validation, or unavailable verification:
1. finish every safe local part;
2. keep it non-`DONE` with an accurate pending state;
3. record the missing action in `docs/progress.md` under `USER ACTION REQUIRED QUEUE`;
4. scan the entire remaining implementation plan;
5. continue any other technically safe work.

A task-level external dependency becomes run-level `USER_ACTION_REQUIRED` only when no technically safe work remains anywhere.

For scheduling only, an implementation-complete dependency pending solely CI/live/external verification may be crossed provisionally when later implementation is safe without the missing evidence. This never makes it `DONE`.

## Final-response gate
Before producing any final response:
1. inspect actual Git/worktree state and `docs/progress.md`;
2. identify the exact next backlog action;
3. if it is executable safely now, execute it instead of responding finally;
4. otherwise scan the full remaining backlog for another safe action;
5. only stop if no safe continuation remains or the platform/model/tool limit actually prevents continuation.

Allowed genuine terminal reasons:
- `USER_ACTION_REQUIRED`
- `PRODUCT_DECISION_REQUIRED`
- `DESTRUCTIVE_APPROVAL_REQUIRED`
- `REAL_FAILURE_BLOCKS_CONTINUATION`
- `REQUIRED_TOOL_UNAVAILABLE`
- `MODEL_OR_TOOL_LIMIT`

When stopping, record the exact reason, evidence, deferred user action if any, and exact resume action in `docs/progress.md`, checkpoint coherent work, then summarize.

## Task lifecycle
For every task:
1. read the full task body and referenced Product/UX/Architecture sections;
2. inspect dependencies and current verification state;
3. apply required agents from `agents/routing.toml`;
4. mark state accurately before substantial work;
5. implement the smallest complete safe solution;
6. add/update required tests;
7. run the strongest verification actually available;
8. self-review against acceptance criteria and product/UX/architecture/security/offline rules;
9. fix established failures;
10. mark `DONE` only when required acceptance and verification genuinely pass;
11. otherwise use an accurate pending state such as `PENDING CI`, `PENDING LIVE`, or `PENDING EXTERNAL`;
12. update `docs/progress.md` and make a focused checkpoint commit when possible;
13. immediately continue to the next safe action.

## CI policy
The repository uses tiered no-cost CI.
- Linux checks are routine, cheap, and non-authoritative for iOS.
- macOS/Xcode CI is authoritative and intentionally sparse.
- Do not add `[macos-ci]` to routine commits.
- Use focused `build`, then `unit`, then `ui` scopes while diagnosing Xcode failures.
- Use `full` at meaningful reconciliation/checkpoints after lower layers are clean.
- A real CI failure is engineering evidence and must be fixed when it blocks safe dependent work.
- Quota exhaustion is verification unavailable, not a code failure; follow `docs/ci_free_quota_policy.md`.
- Paid CI is not approved unless the user explicitly reverses that decision.

## Session continuity
The repository, not chat history, is durable project memory.

`docs/progress.md` must contain enough current state for a brand-new Desktop Codex task to resume safely: branch, active/deferred work, pending verification, blockers/user-action queue, latest meaningful CI evidence, and exact next safe action.

If context is compacted or a fresh task is required by platform limits, reconstruct from Git plus the mandatory docs and continue without asking the user to restate context.

## Product rules
- English only for MVP.
- Top-level navigation: Today / Program / Settings.
- Today opens first after authentication.
- One tap completes a set; tapping again undoes completion.
- No Start Workout flow.
- Sets/exercises may be completed in any order.
- Long press opens compact set editing.
- Skip/restore exercise must remain available without cluttering Today.
- One workout maximum per concrete local calendar date.
- Copy and weekly repeat create independent workouts.
- History lives in Program and historical actual values may be edited.
- No historical planned-vs-actual analytics snapshot model in MVP.
- Offline workout execution is mandatory.
- kg/lb supported.
- System/Light/Dark use one design system.
- Completion motivation appears only after the whole workout finishes as a dismissible overlay/popup.

## Today UX invariant
Today must remain visually quiet. Do not add charts, statistics, progress dashboards, PRs, calories, timers, recommendations, muscle diagrams, feeds, or other secondary information.

## Architecture/security guardrails
Target stack: Swift + SwiftUI, feature-oriented MVVM, repository/service boundaries, Firebase Auth/Firestore/Analytics/Crashlytics, bundled system exercise catalog.

User cloud data must be owner-scoped. Never log or commit passwords, auth tokens, signing secrets, service-account material, or unnecessary private workout content. Never weaken security to make tests pass.

## Branching
- `main`: stable/release only.
- `dev`: integration/default development branch.
- `feature/*`: focused implementation when useful.
- PRs target `dev` by default.
- `dev -> main` only for explicit release.
- Do not auto-merge unless explicitly requested.
- Never delete or overwrite uncommitted user work.

## Documentation discipline
Update docs when behavior, architecture, setup, verification, CI, Firebase contracts, or release process changes.

`docs/progress.md` is the live continuity checkpoint. `docs/implementation_plan.md` remains the detailed backlog/acceptance source and must not be weakened to match temporary environment limitations.
