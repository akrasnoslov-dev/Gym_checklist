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
9. Resume from the first incomplete implementation task whose dependencies are complete.

If the user says only `continue`, follow the same startup sequence and continue from `docs/progress.md`.

## Autonomy policy
Codex should continue task-by-task without waiting for user confirmation between normal implementation steps.

Stop only when:
- product behavior is ambiguous enough that different choices materially change the intended UX;
- credentials, Firebase console configuration, Apple Developer signing/provisioning, or other external account action is required;
- a destructive migration or irreversible operation needs approval;
- required tools are unavailable;
- model/tool usage limits are exhausted.

Do not stop for routine naming, folder placement, implementation detail, test refactoring, or other reversible engineering decisions that are already bounded by the specs.

## Task lifecycle
For each implementation item:
1. Confirm dependencies are complete.
2. Mark it `IN PROGRESS` in `docs/progress.md` if useful.
3. Read affected code and relevant subagent instructions.
4. Implement the smallest coherent change.
5. Add regression/unit/UI tests where appropriate.
6. Run available local verification.
7. Push branch and rely on macOS CI for authoritative Xcode build/test when local environment is Windows.
8. Fix failures before declaring the task complete when possible.
9. Self-review against product/UX/architecture rules.
10. Update `docs/progress.md` with what changed, verification, unresolved limitations, and next task.
11. Commit with a focused message.
12. Continue to the next task unless a stop condition applies.

## Branching
- Never implement normal work directly on `main`.
- Use `dev` for integration.
- Prefer `feature/<short-name>` for focused work based on `dev`.
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
- Use GitHub Actions macOS runners for real builds/tests.
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
`docs/progress.md` is mandatory and must be kept current enough that a fresh Codex session can resume without relying on chat memory.
