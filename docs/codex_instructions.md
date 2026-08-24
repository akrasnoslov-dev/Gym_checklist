# Codex Instructions

## Purpose
This repository is designed for long-running, low-touch implementation in Codex inside the ChatGPT desktop app. The repository is durable project memory; chat history is not.

The intended mode is one initial master prompt per Desktop Codex task, followed by continuous execution until no technically safe work remains or a genuine platform/model/tool limit stops the task.

## Startup sequence
For every new Codex task:
1. Read `AGENTS.md`.
2. Read `docs/product_spec.md`.
3. Read `docs/ux_spec.md`.
4. Read `docs/architecture.md`.
5. Read `docs/implementation_plan.md`.
6. Read `docs/progress.md`.
7. Read `docs/ci_free_quota_policy.md` when present.
8. Read `docs/desktop_continuation_policy.md` when present.
9. Read `agents/routing.toml` and required agent files.
10. Inspect branch/worktree, recent local commits/diff, remote state when available, relevant source/tests, and CI state.
11. Reconcile documentation with actual Git/code state before selecting work.

Do not assume `origin/dev` is newer than the local working repository. Never reset/discard coherent local work merely because the remote is older.

## Runtime status reconciliation
`docs/implementation_plan.md` is authoritative for task bodies, dependencies, and acceptance criteria.

Actual Git/code/tests plus `docs/progress.md` are authoritative for runtime status. If a task header in the plan is stale, repair it when convenient; never roll back correct work to match stale text.

## Execution scheduler
`docs/desktop_continuation_policy.md` is authoritative for continuation, CI waiting/polling, blocker routing, provisional dependency scheduling, and final-response rules.

Core behavior:
1. prefer runnable implementation over waiting;
2. treat CI as asynchronous background verification;
3. after CI dispatch, continue independent safe work immediately;
4. check active CI only at natural checkpoints, when its result is required for a dependent decision, or when no runnable implementation remains;
5. never busy-poll or sleep solely for CI while work exists;
6. scan the full backlog when one task is blocked;
7. do not produce a final response while safe executable work remains.

`docs/progress.md` is runtime state. It must not override this scheduler.

## Task lifecycle
For each implementation item:
1. read the full task body and referenced specs;
2. inspect dependencies and current verification;
3. apply required agents from `agents/routing.toml`;
4. update task/progress state before substantial work;
5. implement the smallest coherent solution;
6. add/update required tests;
7. run the strongest verification available;
8. self-review against acceptance criteria and product/UX/architecture/security/offline implications;
9. fix established failures;
10. mark `DONE` only when all required acceptance and verification genuinely pass;
11. otherwise keep an explicit pending state;
12. update `docs/progress.md` and create a focused checkpoint commit when possible;
13. immediately continue to the next safe action.

## CI operating mode
Paid GitHub Actions usage is not approved unless the user explicitly changes that decision.

Routine checkpoints use Linux checks. Authoritative macOS CI is sparse.

For diagnostics, dispatch scopes in this order when needed:

```text
build -> unit -> ui
```

Use `full` only after lower layers are clean or for meaningful reconciliation/release checkpoints.

Important: this is **dispatch order, not a waiting loop**. After dispatching a run, record it and continue independent implementation. Do not poll repeatedly. A queued/running CI status is `PENDING CI`, not the active foreground task.

A result applies to the checkpoint SHA that ran. Do not rerun simply because later unrelated commits advanced `dev`.

Quota exhaustion follows `docs/ci_free_quota_policy.md`. All CI scheduling/waiting behavior follows `docs/desktop_continuation_policy.md`.

## Windows/macOS reality
The user's primary machine is Windows and has no local Xcode.
- never claim local Xcode verification on Windows/Linux;
- static/deterministic checks remain useful but non-authoritative;
- GitHub-hosted macOS/Xcode is the normal authoritative path;
- lack of local Xcode is not a stop while safe work remains.

## External configuration
Batch external actions instead of interrupting piecemeal. Examples include Firebase/Google OAuth setup, local untracked Firebase plist, Apple Developer/App Store Connect actions, signing, and GitHub release secrets.

Do not print or commit secret configuration.

## Session continuity
Keep `docs/progress.md` concise and current enough for a fresh Desktop Codex task to resume without chat history.

If context is compacted or the platform forces a new task, reconstruct state from Git and mandatory docs, then continue without asking the user to restate context.

## Branching
- `main`: stable/release only.
- `dev`: integration/default development branch.
- focused `feature/*` branches are optional.
- PR target is `dev` by default.
- `dev -> main` only for explicit release approval.
- never overwrite uncommitted user work.

## Product guardrail
Preserve:

```text
Open app -> Today -> one tap per completed set -> close app
```

Do not add unapproved fitness/dashboard/social/AI features. Today stays visually quiet.
