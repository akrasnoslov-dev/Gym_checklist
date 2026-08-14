# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 0 — Repository/bootstrap.

## Active task
`M0.1` — Create the native iOS SwiftUI project, unit test target, and UI test target.

## Published state
- The first Codex Cloud implementation was applied locally and published to `dev` as commit `a8d9e37` (`Bootstrap native iOS project`).
- `dev` now contains the Xcode project, shared scheme, app placeholder, unit smoke test, UI launch test, and iOS 17.0 deployment baseline.
- Codex Cloud workflow instructions were updated afterward so missing sandbox `origin` / `gh` authentication is not treated as a user-action blocker.

## Completed foundation
- Repository created.
- `main` initialized.
- `dev` branch created.
- Product, UX, architecture, Codex workflow, implementation plan, and agent routing added.
- Native Xcode project implementation for M0.1 is present on `dev`.

## Verification status
- Cloud/Linux static checks previously passed: project file validation, shared scheme XML validation, required target settings, `git diff --check`, and clean checkpoint commit.
- Local Windows checkout successfully committed and pushed the implementation to `origin/dev`.
- GitHub Actions `iOS CI` now triggers on `dev`; macOS CI is the authoritative Xcode build/test verification.
- M0.1 remains `IN PROGRESS` until a green macOS CI run verifies the Xcode build/tests.

## Codex Cloud execution note
Codex Cloud may not expose a writable Git remote or authenticated GitHub CLI inside its sandbox. That condition alone is not a blocker. Cloud should keep implementing safe backlog work and record CI-dependent verification as `PENDING EXTERNAL CI` until the batch is published. The user should not be asked to Apply locally after every task.

## USER ACTION REQUIRED
None right now.

Later checkpoints may require batched external setup for:
- Firebase project/app configuration.
- Apple Developer Program / App Store Connect setup for TestFlight.
- Signing and CI secrets.

## Blockers
None requiring user action right now.

## Exact next action
Check the macOS `iOS CI` result for the current `dev` state. If green, mark M0.1 `DONE` and continue with M0.2. In Codex Cloud, continue safe implementation work even if direct sandbox push/PR commands are unavailable; do not treat that sandbox limitation as a blocker.

## Future candidates
None approved for implementation beyond the explicit backlog in `docs/implementation_plan.md`.
