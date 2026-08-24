# Gym Checklist — ChatGPT Desktop Continuation Policy

## Operating surface

Normal autonomous development for this project runs in **Codex inside the ChatGPT desktop app**.

Do not require a separate Codex CLI, PowerShell supervisor, Python watchdog, or another launch path for normal development.

Do not assume that a scheduled-task/heartbeat feature exists inside the current Codex task. Repository instructions must work without such a feature.

## Goal

The user should be able to start one Desktop Codex task with `docs/codex_master_prompt.md` and leave it running until:
- all technically safe backlog work available in that task is exhausted; or
- a genuine terminal condition or platform/model/tool limit prevents further work.

Codex must not voluntarily end a turn merely because it completed a task, commit, review, CI check, milestone, or progress update.

## Blocked task != blocked run

If the current task is blocked by external configuration, credentials, live validation, unavailable verification, or another non-code prerequisite:
1. finish every safe local/repository part of that task;
2. keep the task non-`DONE` with an accurate pending state such as `IN PROGRESS (PENDING EXTERNAL)`;
3. record the missing action under `USER ACTION REQUIRED QUEUE` in `docs/progress.md`;
4. scan the **entire remaining implementation plan**, not only the next sequential task;
5. continue any other technically safe task;
6. return to the deferred task when its prerequisite becomes available.

For scheduling only, an implementation-complete dependency pending solely CI/live/external verification may be treated as provisionally satisfied when later implementation is safe without that missing evidence.

This does **not** change acceptance criteria or the meaning of `DONE`.

## Runtime status authority

`docs/implementation_plan.md` defines task bodies, dependencies, acceptance criteria, and intended ordering.

`docs/progress.md` plus actual Git/code state defines the current runtime status. If a status label in the implementation plan is stale, reconcile it rather than rolling code backward.

## Final-response rule

Before any final response:
1. inspect actual Git/worktree state and `docs/progress.md`;
2. identify the exact next safe backlog action;
3. if it can be executed now, execute it instead of responding finally;
4. if it cannot, scan the full remaining backlog for another safe action;
5. only stop when no technically safe work remains anywhere or the platform/model/tool limit actually prevents continuation.

A completed task, milestone, commit, push, review, CI run, progress update, or known `Next:` action is not a stopping point.

## Genuine terminal conditions

Run-level stops are limited to the terminal conditions defined in `AGENTS.md`:
- `USER_ACTION_REQUIRED`
- `PRODUCT_DECISION_REQUIRED`
- `DESTRUCTIVE_APPROVAL_REQUIRED`
- `REAL_FAILURE_BLOCKS_CONTINUATION`
- `REQUIRED_TOOL_UNAVAILABLE`
- `MODEL_OR_TOOL_LIMIT`

`USER_ACTION_REQUIRED` applies only after a full backlog scan finds no technically safe work that can proceed without the user action.

## Platform interruption

Repository instructions can prevent voluntary premature stops, but they cannot override a platform-enforced model/tool/session limit.

If ChatGPT/Codex itself ends the task because of such a limit, the durable recovery path is:
- start a fresh Desktop Codex task later with the same master prompt;
- reconstruct state from Git and repository docs;
- continue without asking the user to restate project context.

Do not introduce a separate launcher or external supervisor merely to work around this limitation.

## Priority

This document controls execution mechanics in ChatGPT Desktop Codex and overrides conflicting generic execution wording in `docs/implementation_plan.md`.

It does not override product behavior, UX, architecture, security/privacy requirements, task acceptance criteria, or release approvals.
