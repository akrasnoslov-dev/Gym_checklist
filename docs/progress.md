# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 0 — Repository/bootstrap.

## Active task
`M0.2` — Establish the feature-oriented MVVM source structure. M0.1 and M0.2 remain pending authoritative macOS CI; continuing is technically safe because their only unavailable verification is external CI.

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
- M0.2 now has the architecture-aligned physical directories and Xcode groups, with the existing app sources moved under `App/` and no speculative Swift scaffolding.
- M0.2 Linux checks passed: project group/path assertions, source existence checks, balanced project syntax, shared scheme XML parsing, and `git diff --check`.
- `xcodebuild` is unavailable in this Linux environment, so M0.2 remains `IN PROGRESS (PENDING CI)` until macOS CI builds and tests it.

## Agent reviews
- `architecture_guardian`: no findings; layout matches the documented boundaries and avoids speculative abstractions.
- `code_quality_agent`: no findings; the focused source relocation preserves target membership without dead code.
- `test_ci_agent`: no blocking findings and no new behavior requiring tests; macOS build/test remains the required external verification. A pre-existing non-blocking CI robustness candidate is selecting a simulator by UDID rather than an ambiguous device name.

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
Publish the M0.2 checkpoint and run macOS `iOS CI`. When CI is green, mark M0.1 and M0.2 `DONE`, then start M0.3. In Cloud, M0.3 may proceed safely while that external-only verification remains pending.

## Future candidates
None approved for implementation beyond the explicit backlog in `docs/implementation_plan.md`.
