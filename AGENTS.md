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

## Desktop execution mechanics
`docs/desktop_continuation_policy.md` is the single authoritative execution scheduler.

Non-negotiable summary:
- work-first: runnable implementation outranks waiting;
- CI is asynchronous background verification;
- after dispatching CI, immediately continue independent safe work;
- never busy-poll or sleep solely for CI while runnable work exists;
- a blocked task is not a blocked run;
- dependency `DONE` is strict for acceptance, while provisional implementation scheduling is allowed only under the safety rules in the desktop policy;
- a final response is forbidden while safe executable backlog work remains.

Do not reinterpret `docs/progress.md` as a synchronous CI queue. If it says `build -> unit -> ui`, that means CI layer order, not `run -> wait -> run -> wait`.

## CI policy
The repository uses tiered no-cost CI. Detailed cost/quota rules are in `docs/ci_free_quota_policy.md`; scheduling/waiting rules are in `docs/desktop_continuation_policy.md`.

- Linux checks are routine and non-authoritative for iOS.
- macOS/Xcode CI is authoritative and intentionally sparse.
- Diagnostic layer order is `build -> unit -> ui`; `full` is for clean milestone/release reconciliation.
- Layer order gates the next CI dispatch, not unrelated implementation.
- Never wait/poll an active CI run while other safe implementation exists.
- A CI result verifies the checkpoint SHA it ran against, not every later branch commit.
- A real failure should be fixed and narrowly reverified; it blocks the whole run only if it makes all remaining safe work impossible.
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
