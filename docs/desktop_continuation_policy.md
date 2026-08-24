# Gym Checklist — ChatGPT Desktop Execution Policy

## 1. Authority and operating surface

Normal autonomous development for this project runs in **Codex inside the ChatGPT desktop app**.

This file is the single authoritative source for execution mechanics: scheduling, CI waiting/polling, blocked-task routing, dependency bypass for implementation, and final-response rules.

Other documents may summarize these rules but must not redefine them. If execution wording elsewhere conflicts with this file, this file wins.

Do not require a separate Codex CLI, PowerShell supervisor, Python watchdog, scheduled-task heartbeat, or another launch path for normal development.

## 2. Goal

The user should be able to start one Desktop Codex task with `docs/codex_master_prompt.md` and leave it running until:
- all technically safe backlog work available in that task is exhausted; or
- a genuine run-level terminal condition or platform/model/tool limit prevents further work.

A task, commit, push, review, CI dispatch, CI completion, progress update, or milestone boundary is never by itself a reason to stop.

## 3. Work-first scheduler

At every checkpoint classify remaining work into:

- **RUNNABLE IMPLEMENTATION** — safe code/docs/review work that can be done now.
- **PENDING CI** — implementation exists but authoritative verification is running or not yet performed.
- **PENDING EXTERNAL** — remaining acceptance/live work needs user/external configuration.
- **BLOCKED** — work cannot safely advance because a real failure, decision, or unavailable requirement affects it.

Scheduling rule:

1. If any **RUNNABLE IMPLEMENTATION** exists anywhere in the approved backlog, do it.
2. Do not wait for CI, external setup, or another blocked task while runnable implementation exists.
3. Re-check pending work at natural checkpoints, not continuously.
4. Stop only when no runnable implementation remains and a genuine terminal condition applies.

`docs/progress.md` records state and next work. It must not turn CI into a synchronous queue.

## 4. CI is asynchronous — mandatory

GitHub Actions is background verification, not the foreground task.

When a macOS run is appropriate:

1. Create/push one coherent checkpoint.
2. Dispatch the narrowest justified scope.
3. Record the checkpoint SHA, scope, and run ID/status when available.
4. **Immediately return to RUNNABLE IMPLEMENTATION.**
5. Check the CI result later at a natural checkpoint.

Forbidden behavior while runnable implementation exists:
- waiting/sleeping solely for CI;
- repeatedly polling the same run;
- making CI status checks the active task;
- launching another identical run because the previous one is still running;
- repeatedly running `full` to discover failures that can be isolated with narrower scopes.

### Layer sequencing

For diagnostic macOS verification:

```text
build -> unit -> ui -> full
```

This ordering controls **which CI layer may be dispatched next**. It does **not** mean Codex must sit idle between layers.

Example:

```text
dispatch build
-> continue independent implementation
-> later check build
-> if green, dispatch unit
-> continue independent implementation
-> later check unit
-> if green, dispatch ui
-> continue independent implementation
```

Do not dispatch `unit` until the relevant `build` is known green. Do not dispatch `ui` until the relevant lower-layer evidence is clean. But keep working elsewhere while those runs execute.

### Polling rule

Check an active CI run only when at least one is true:
- a natural implementation/checkpoint boundary has been reached;
- its result is required before accepting or safely changing the next dependent area;
- no other runnable implementation remains.

Never busy-poll. If a status check returns `queued` or `in_progress`, record that state once and move to other runnable work.

### Checkpoint-SHA rule

A CI result verifies the code checkpoint/SHA it actually ran against.

If later independent commits are added while CI runs:
- do not invalidate the old result retroactively;
- do not immediately rerun CI just because branch HEAD advanced;
- use the result for the checkpoint it verified;
- run newer authoritative CI only when later changes touch the relevant verified surface or a milestone/release checkpoint requires current-head evidence.

### Rerun rule

Do not rerun the same failed scope until a code/configuration change intended to address that failure exists, unless the failure is clearly infrastructure/transient.

After fixing a real CI failure:
- dispatch the narrowest relevant scope once;
- continue independent implementation instead of waiting.

### Full-suite rule

Use `full` only:
- after lower diagnostic layers are clean; or
- for a meaningful milestone/release reconciliation.

Do not use repeated full-suite runs as a development loop.

## 5. Dependency semantics

Dependencies remain strict for **acceptance and `DONE`**.

For **implementation scheduling only**, later work may start before a dependency is `DONE` when Codex establishes that the missing part does not make the later implementation unsafe.

Allowed provisional scheduling includes:
- dependency implementation is complete but CI/live verification is pending;
- dependency is waiting on external configuration that is isolated from the later task;
- a dependency contains a missing auth/provider/release path that the later task does not need to implement its own local/domain/UI behavior safely.

When using provisional scheduling:
- keep the dependency non-`DONE`;
- record the bypass/rationale in `docs/progress.md`;
- do not claim dependent acceptance that relies on the missing behavior;
- do not bypass security/privacy ownership boundaries, data-integrity invariants, destructive decisions, or a real failure that could invalidate the later work.

## 6. Blocked task != blocked run

If the current task is blocked by external configuration, credentials, live validation, unavailable verification, or another non-code prerequisite:

1. finish every safe local/repository part;
2. keep the task non-`DONE` with an accurate pending state;
3. record the missing action under `USER ACTION REQUIRED QUEUE` in `docs/progress.md`;
4. scan the **entire remaining implementation plan**, not only the next sequential task;
5. continue any other technically safe task;
6. return to the deferred task when its prerequisite becomes available.

`USER_ACTION_REQUIRED` is run-level only: it applies after the full backlog scan finds no technically safe work that can proceed without the user action.

## 7. Real CI failures

A real compiler/test failure is engineering evidence, but it still does not automatically block the whole run.

When CI fails:
1. inspect the failure once;
2. determine the affected code/test surface;
3. fix it if possible with available tools;
4. add/update regression coverage if appropriate;
5. dispatch one narrow verification run;
6. continue unrelated safe work while it runs.

Stop for `REAL_FAILURE_BLOCKS_CONTINUATION` only when the unresolved failure makes **all** remaining safe work impossible or unsafe.

## 8. Final-response gate

Before any final response:

1. inspect actual Git/worktree state and `docs/progress.md`;
2. identify the exact next safe backlog action;
3. if it can be executed now, execute it instead of responding finally;
4. if not, scan the full remaining backlog for another safe action;
5. check whether pending CI/external work can remain deferred while other work proceeds;
6. only stop when no technically safe work remains anywhere or the platform/model/tool limit actually prevents continuation.

These are not stop conditions:
- a task/milestone completed;
- commit/push completed;
- agent reviews completed;
- CI was dispatched;
- CI is queued/running;
- one CI layer passed;
- CI verification remains pending;
- local Xcode is unavailable;
- one task needs external configuration;
- `docs/progress.md` was updated;
- a known next action exists;
- Codex wants to summarize.

## 9. Explicit user pause override

An explicit current user instruction to pause or stop overrides the autonomous scheduler.

When the user explicitly requests a pause:
- stop foreground implementation as soon as the current atomic operation is left coherent;
- do not start new CI or new backlog work;
- record `USER-REQUESTED PAUSE` in `docs/progress.md`;
- preserve any already-running external CI as background state;
- do not resume until the user explicitly starts/resumes development again.

`USER-REQUESTED PAUSE` is not a generic terminal reason Codex may invent. It is valid only when the current user explicitly asked to pause/stop.

A later explicit resume instruction or a fresh task started with `docs/codex_master_prompt.md` clears that pause.

## 10. Genuine terminal conditions

Run-level stops are limited to:
- `USER_ACTION_REQUIRED`
- `PRODUCT_DECISION_REQUIRED`
- `DESTRUCTIVE_APPROVAL_REQUIRED`
- `REAL_FAILURE_BLOCKS_CONTINUATION`
- `REQUIRED_TOOL_UNAVAILABLE`
- `MODEL_OR_TOOL_LIMIT`

Before using any terminal reason except a platform-enforced limit, scan the full remaining backlog and establish that no technically safe work can continue.

When stopping:
- finish the smallest coherent safe unit;
- update `docs/progress.md` with exact reason, evidence, queued action if any, and exact resume action;
- checkpoint coherent work when possible;
- then provide a concise final summary.

## 11. Progress-file discipline

`docs/progress.md` is runtime state, not an alternative scheduler.

It should contain:
- branch/current code checkpoint;
- implemented/pending/deferred work;
- active CI run(s) with scope + checkpoint SHA when known;
- latest meaningful CI evidence;
- `USER ACTION REQUIRED QUEUE`;
- current blockers;
- **next runnable implementation action**;
- deferred verification/external actions.

Do not write an `Exact next action` that says only `wait for CI`, `poll CI`, or `run build -> wait -> unit -> wait -> ui` when runnable implementation exists.

## 12. Platform interruption

Repository instructions can prevent voluntary premature stops but cannot override a platform-enforced model/tool/session limit.

If ChatGPT/Codex itself ends the task because of such a limit:
- start a fresh Desktop Codex task later with the same master prompt;
- reconstruct state from Git and repository docs;
- continue without asking the user to restate project context.

Do not introduce a separate launcher or external supervisor merely to work around this limitation.

## 13. Priority

This document controls execution mechanics and overrides conflicting execution wording in:
- `AGENTS.md`;
- `docs/codex_instructions.md`;
- `docs/implementation_plan.md`;
- `docs/progress.md`;
- `docs/ci_free_quota_policy.md`.

It does not override product behavior, UX, architecture, security/privacy requirements, task acceptance criteria, or release approvals.
