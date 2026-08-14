# Codex Instructions

## Purpose
This repository is designed for long-running, low-touch Codex implementation. The user should not need to manually decompose every engineering task.

## Startup sequence
For every new Codex session:
1. Read `AGENTS.md`.
2. Read `docs/product_spec.md`.
3. Read `docs/ux_spec.md`.
4. Read `docs/architecture.md`.
5. Read `docs/implementation_plan.md`.
6. Read `docs/progress.md`.
7. Read `agents/routing.toml` and any required agent files.
8. Inspect git status/branch and current repository state.
9. Resume an existing `IN PROGRESS` task first; otherwise take the first `TODO` task whose dependencies are `DONE`.

If the user says only `continue`, follow the same startup sequence and resume from repository state.

## Autonomy policy
Codex should continue task-by-task without waiting for user confirmation between normal implementation steps.

Stop only when:
- product behavior is ambiguous enough that different choices materially change the intended UX;
- credentials, Firebase console configuration, Apple Developer signing/provisioning, or other external account action is required;
- a destructive migration or irreversible operation needs approval;
- a genuinely required implementation tool is unavailable and no safe work within the current milestone can continue without it;
- model/tool usage limits are exhausted.

Do not stop for routine naming, folder placement, implementation detail, test refactoring, or other reversible engineering decisions that are already bounded by the specs.

## Codex Cloud execution rule
Codex Cloud may receive a repository snapshot without exposing a normal writable `origin`, authenticated `gh`, or direct PR creation inside the Linux sandbox. This is expected and is **not** a user-action blocker by itself.

When running in Codex Cloud:
- Do not stop merely because `git remote -v` is empty, `origin` is missing, `gh auth status` is unauthenticated, `git push` is unavailable, or a PR cannot be created from the sandbox.
- Do not ask the user to configure a PAT, `GH_TOKEN`, remote, or GitHub CLI solely to work around this Cloud sandbox limitation.
- Make focused checkpoint commits inside the Cloud task when possible.
- If authoritative GitHub/macOS CI cannot run only because Cloud cannot publish the checkpoint, record that verification as `PENDING EXTERNAL CI` rather than as a development blocker.
- A task whose implementation and all available checks pass may remain `IN PROGRESS (PENDING CI)` while Codex continues to the next technically safe dependent task.
- For dependency purposes inside the same Cloud run, `IN PROGRESS (PENDING CI)` counts as provisionally satisfied when the only missing acceptance item is external macOS/GitHub CI and the implementation is otherwise complete.
- Do not finish the Cloud response after one such task. Immediately begin the next safe task in the same milestone.
- Continue through all safe implementation tasks in the current milestone until reaching the milestone checkpoint task.
- At the milestone checkpoint, consolidate all pending external CI into one user/export checkpoint. Do not request `Apply locally` or publishing after each individual task.
- If a later task can be implemented safely without the missing external verification, continue. Missing CI is only a hard stop at a checkpoint that explicitly requires it, or when a real failure result exists and must be fixed before safe continuation.

**Cloud final-response rule:** do not produce a final summary or end the task while another safe implementation task in the current milestone is eligible. A final response is appropriate only at a genuine stop condition, the milestone checkpoint/export boundary, or a usage/tool limit.

The intended Cloud rhythm is:
`implement task -> local/static verification -> checkpoint commit -> next task -> ... -> milestone checkpoint -> one export/publish/CI cycle`.

## Task lifecycle
For each implementation item:
1. Confirm dependencies are complete, or in Cloud mode confirm that any incomplete dependency is incomplete **only** because external CI is pending and continuing is technically safe.
2. Mark it `IN PROGRESS` in `docs/implementation_plan.md` before implementation.
3. Immediately update `docs/progress.md` with the active task, intended scope, and last known good commit/branch state.
4. Read affected code, referenced specs, and relevant subagent instructions.
5. Implement the smallest coherent change.
6. Add regression/unit/UI tests where appropriate.
7. Run all verification available in the current environment.
8. Use macOS CI for authoritative Xcode build/test once the milestone batch is published to GitHub.
9. Fix failures before declaring the task complete when possible.
10. Self-review against product/UX/architecture rules and every task acceptance criterion.
11. Mark the task `DONE` only after required acceptance/verification passes; if only external CI is unavailable in Cloud, keep it explicitly `IN PROGRESS (PENDING CI)` and continue safely without claiming completion.
12. Update `docs/progress.md` after the task with what changed, exact verification, checkpoint state, unresolved limitations, and exact next task.
13. Create a checkpoint commit for the task or smallest tightly coupled task set.
14. In Cloud, immediately start the next safe task in the same milestone. Do not return control to the user merely because one task reached `PENDING CI`.

## Session continuity and context-window resilience
Chat memory is not the project state. The repository is the project state.

Required rules:
- `docs/progress.md` must be current after every completed task and whenever a task becomes meaningfully `IN PROGRESS`.
- Prefer frequent focused commits over carrying a large uncommitted multi-task diff.
- Record the current branch, active task, last completed task, last known good commit, verification/CI state, blockers, and exact next action in `docs/progress.md`.
- At the beginning of a fresh session, trust Git state, committed files, current CI results, `docs/implementation_plan.md`, and `docs/progress.md` over assumptions from an older conversation.
- If chat/context is compacted, reset, lost, or appears inconsistent, do not guess. Re-read repository checkpoint files and inspect the diff/branch.
- If a prior session stopped mid-task, finish/reconcile that `IN PROGRESS` task before taking another task.
- Never rely on the user to notice context pressure or manually summarize the prior session.
- When practical, if a session has become very long or repeated reasoning starts losing precision, finish the current atomic task, write a clean checkpoint, and explicitly recommend starting a fresh Codex task/session. This recommendation is advisory, not a blocker.
- A usage-limit stop and a context/session reset are different: after a usage-limit reset, `continue` in the same coherent task is fine; after a new task/session, the same repository checkpoints allow recovery without chat history.

## Branching
- Never implement normal work directly on `main`.
- Use `dev` for integration.
- Prefer `feature/<short-name>` for focused work based on `dev` when normal Git publishing is available.
- PR target is `dev`.
- Only create `dev -> main` release PR when explicitly requested.

For the initial repository bootstrap, Codex may create/repair project scaffolding directly on `dev` if no feature workflow exists yet, then move to feature branches once the Xcode project and CI are stable.

## Product-change rule
The specification is authoritative. Do not add attractive but unrequested fitness features.

If implementation exposes a likely product improvement, record it under `Future candidates` in `docs/progress.md`; do not implement it automatically.

## UI rule
Today is the protected UX surface. Every addition must justify why it is needed during an active workout. Prefer hiding secondary functionality rather than surfacing more controls.

## Windows/macOS reality
The user's primary machine is Windows and does not have Xcode.
- Do not claim local Xcode verification on Windows.
- Use GitHub Actions macOS runners for real builds/tests once milestone changes are published.
- Keep CI output actionable.
- Once TestFlight automation exists, treat successful upload as distribution verification, not proof of UX correctness.

## External configuration checkpoints
When an external action is required, write exact steps into `docs/progress.md` under `USER ACTION REQUIRED`, including:
- where to click,
- what value to create/select,
- what secret name to add to GitHub,
- how Codex will verify it afterward.

Keep these asks consolidated. Avoid asking the user to perform one small console action at a time when several can be batched.

## Pull request quality
PR description should include:
- task/milestone,
- summary,
- key files,
- behavior confirmation,
- tests/CI run,
- offline impact,
- security/privacy impact,
- known limitations,
- next planned task.

## Progress continuity
`docs/progress.md` is mandatory and must be kept current enough that a fresh Codex session with no chat history can resume safely from repository state alone.
