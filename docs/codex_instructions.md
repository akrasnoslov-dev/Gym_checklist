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

## Desktop-only execution
Do not require a separate CLI, PowerShell runner, Python supervisor, or scheduled-task heartbeat for normal development.

Repository instructions must be sufficient to keep the current Desktop Codex task working continuously for as long as the platform allows.

## Continuous-run contract
After each implementation step, review, verification pass, documentation update, commit, or push:
1. determine the exact next technically safe action;
2. if it can be executed now, execute it immediately;
3. do not produce a final response merely to report the checkpoint;
4. repeat.

The following are not stop conditions:
- one task or milestone completed;
- a commit/push completed;
- progress docs updated;
- agent reviews completed;
- CI is pending or one focused CI layer completed;
- a known next action exists;
- local Xcode is unavailable on Windows/Linux;
- one task needs external configuration;
- the session is long but state can be reconstructed;
- Codex wants to summarize progress.

## Blocked-task routing
When the active task is blocked by external configuration, credentials, live validation, or unavailable verification:
1. finish every safe local/repository part;
2. record an accurate pending state;
3. add the missing external action to `USER ACTION REQUIRED QUEUE` in `docs/progress.md`;
4. scan the entire remaining implementation plan for independent safe work;
5. continue it;
6. return to the deferred task when its prerequisite becomes available.

For scheduling only, an implementation-complete dependency pending solely CI/live/external verification may be treated as provisionally satisfied when later implementation is safe without the missing evidence. Acceptance criteria remain unchanged.

## Final-response gate
A final response is forbidden while executable safe work remains.

Before every final response:
1. inspect actual Git/worktree state and `docs/progress.md`;
2. identify the exact next backlog action;
3. if it can be executed safely, execute it;
4. otherwise scan the full remaining backlog for another safe action;
5. stop only if no safe work remains or platform/model/tool limits actually prevent continuation.

Allowed terminal reasons:
- `USER_ACTION_REQUIRED`: external action is required and no other safe backlog work remains;
- `PRODUCT_DECISION_REQUIRED`: material product ambiguity cannot be resolved from authoritative specs;
- `DESTRUCTIVE_APPROVAL_REQUIRED`: destructive/irreversible action needs approval;
- `REAL_FAILURE_BLOCKS_CONTINUATION`: unresolved real failure makes all safe dependent continuation impossible;
- `REQUIRED_TOOL_UNAVAILABLE`: required tool/environment is unavailable and no other safe work remains;
- `MODEL_OR_TOOL_LIMIT`: the platform/model/tool limit prevents further execution.

When stopping, write the exact reason, evidence, queued user action, and exact resume action to `docs/progress.md`, checkpoint coherent work, then summarize.

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

Routine checkpoints:
- rely on `.github/workflows/linux-checks.yml`;
- do not use `[macos-ci]` routinely;
- Linux success is non-authoritative for iOS.

Authoritative macOS CI:
- use at meaningful checkpoints or when Xcode-specific risk makes continuation unsafe;
- while diagnosing failures, use `build` -> `unit` -> `ui` and batch equivalent failures;
- run `full` only after lower layers are clean or for meaningful reconciliation/release checkpoints.

Quota exhaustion follows `docs/ci_free_quota_policy.md`: verification may remain pending while safe implementation continues. A real CI failure is different and must be fixed when it blocks safe dependent work.

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
