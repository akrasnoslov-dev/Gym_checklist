# Gym Checklist — Desktop Continuation Policy

## Operating surface

This project is intentionally developed through **Codex inside the ChatGPT desktop app**.

Do not require a separate CLI supervisor, external PowerShell runner, or another launch path for normal autonomous development.

## Continuation heartbeat

For every long-running implementation chat, create or update one scheduled task attached to **this same Codex chat**:

`Gym Checklist continuation heartbeat`

Schedule:
- every 5 minutes;
- return to this same chat;
- use the same local Gym Checklist project/checkout;
- reuse or update the existing heartbeat instead of creating duplicates.

Heartbeat behavior:
1. If another implementation turn is actively modifying the same checkout, do not start conflicting edits. Wait for the next heartbeat.
2. Otherwise reconstruct state from Git, `docs/progress.md`, `docs/implementation_plan.md`, and the relevant specs/tests.
3. If technically safe backlog work remains, continue implementation immediately.
4. If the current task is blocked by external configuration, credentials, live validation, or unavailable verification:
   - finish every safe local/repository part;
   - keep the task non-`DONE` with an accurate pending state such as `IN PROGRESS (PENDING EXTERNAL)`;
   - batch the missing user action under `USER ACTION REQUIRED QUEUE` in `docs/progress.md`;
   - scan the **entire remaining implementation plan**, not only the next sequential task;
   - continue any other technically safe task.
5. Pause/disable the heartbeat only when:
   - all implementation-plan work is complete; or
   - no technically safe backlog work remains anywhere and a genuine terminal condition requires user/tool/platform action.

The heartbeat exists specifically so a premature normal Codex turn ending does not require the user to type `continue`.

## Blocked task != blocked run

A task-level external dependency is not automatically a run-level `USER_ACTION_REQUIRED`.

Before stopping for user action, scan all remaining tasks for independent safe work.

For scheduling only, an implementation-complete dependency pending solely CI/live/external verification may be treated as provisionally satisfied when later implementation is safe without that missing evidence.

This does **not** change acceptance criteria or the meaning of `DONE`.

## Priority

This document controls **execution mechanics in ChatGPT Desktop Codex** and overrides conflicting generic execution wording in `docs/implementation_plan.md`.

It does not override:
- `docs/product_spec.md` product behavior;
- `docs/ux_spec.md` UX behavior;
- `docs/architecture.md` technical boundaries;
- task-specific acceptance criteria;
- security/privacy requirements;
- release approval requirements.

## Final response rule

A completed task, milestone, commit, push, CI run, review, or progress update is not a stopping point.

A final response is appropriate only when:
- all planned work is complete; or
- no technically safe work remains anywhere and one genuine terminal condition applies.

When a genuine external user action is eventually required, batch it into one clear checklist instead of stopping piecemeal.
