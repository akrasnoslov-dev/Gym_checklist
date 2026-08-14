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
- a genuinely required implementation tool is unavailable;
- model/tool usage limits are exhausted.

Do not stop for routine naming, folder placement, implementation detail, test refactoring, or other reversible engineering decisions that are already bounded by the specs.

## Codex Cloud execution rule
Codex Cloud may receive a repository snapshot without exposing a normal writable `origin`, authenticated `gh`, or direct PR creation inside the Linux sandbox. This is expected and is **not** a user-action blocker by itself.

When running in Codex Cloud:
- Do not stop merely because `git remote -v` is empty, `origin` is missing, `gh auth status` is unauthenticated, `git push` is unavailable, or a PR cannot be created from the sandbox.
- Do not ask the user to configure a PAT, `GH_TOKEN`, remote, or GitHub CLI solely to work around this Cloud sandbox limitation.
- Make focused checkpoint commits inside the Cloud task when possible and continue implementing the backlog.
- If authoritative GitHub/macOS CI cannot run only because Cloud cannot publish the checkpoint, record that verification as `PENDING EXTERNAL CI` rather than as a development blocker.
- A task whose implementation and all available checks pass may remain `IN PROGRESS (PENDING CI)` while Codex continues to the next safely dependent implementation task. Do not falsely mark the missing CI check as passed.
- Mandatory milestone checkpoints that explicitly require green CI must remain open until the changes are exported/published and CI actually passes.
- The user may later use Codex UI `Apply locally`/PR export to publish a batch. Do not require that action after every implementation item.

The goal is one long Cloud run that keeps implementing until a genuine product/external-configuration blocker or usage limit occurs.

## Task lifecycle
For each implementation item:
1. Confirm dependencies are complete, or in Cloud mode confirm that any incomplete dependency is incomplete **only** because its external CI verification is pending and that continuing is technically safe.
2. Mark it `IN PROGRESS` in `docs/implementation_plan.md` before implementation.
3. Immediately update `docs/progress.md` with the active task, intended scope, and last known good commit/branch state.
4. Read affected code, referenced specs, and relevant subagent instructions.
5. Implement the smallest coherent change.
6. Add regression/unit/UI tests where appropriate.
7. Run all verification available in the current environment.
8. Use macOS CI for authoritative Xcode build/test once the changes are published to GitHub.
9. Fix failures before declaring the task complete when possible.
10. Self-review against product/UX/architecture rules and every task acceptance criterion.
11. Mark the task `DONE` only after required acceptance/verification passes; if only external CI is unavailable in Cloud, record `PENDING CI` and continue safely without claiming completion.
12. Update `docs/progress.md` immediately after the task with what changed, exact verification, commit/PR/CI state, unresolved limitations, and exact next task.
13. Create a checkpoint commit for the completed task or smallest tightly coupled task set before moving materially forward.
14. Continue to the next task unless a genuine stop condition applies.

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
- Use GitHub Actions macOS runners for real builds/tests once changes are published.
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
