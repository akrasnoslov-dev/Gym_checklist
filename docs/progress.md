# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 0 — Repository/bootstrap.

## Active task
`M0.6` — Bootstrap checkpoint. M0.1–M0.5 are implemented and remain pending one authoritative macOS CI run; the milestone gate cannot be marked `DONE` until that run is green.

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
- M0.3 now provides a native `TabView` shell with Today selected by default and minimal Program/Settings placeholders in their feature folders.
- M0.3 UI coverage asserts the initial Today surface, navigation to all three tabs, and tab preservation across background/activation. Linux static project/source assertions, shared scheme XML parsing, and `git diff --check` passed; macOS build/UI tests remain pending.
- M0.4 CI now selects a concrete available iPhone simulator UDID from the newest installed iOS runtime, avoiding ambiguous device-name destinations, and uses strict Bash error handling. Ruby YAML parsing, targeted workflow assertions, and `git diff --check` passed; one green GitHub macOS run remains required.
- M0.5 keeps native Xcode/compiler diagnostics as the quality baseline and documents the exact macOS `xcodebuild test` and non-authoritative static commands. Documentation assertions, shared scheme XML parsing, and `git diff --check` passed; CI green status remains pending.

## Agent reviews
- `architecture_guardian`: no findings; layout matches the documented boundaries and avoids speculative abstractions.
- `code_quality_agent`: no findings; the focused source relocation preserves target membership without dead code.
- `test_ci_agent`: no blocking findings and no new behavior requiring tests; macOS build/test remains the required external verification. A pre-existing non-blocking CI robustness candidate is selecting a simulator by UDID rather than an ambiguous device name.
- M0.3–M0.6 delegated reviews were completed by `architecture_guardian`, `code_quality_agent`, and `test_ci_agent`. Their shared simulator-name ambiguity finding was fixed in M0.4; no source architecture, maintainability, product-scope, or test-structure blockers remain. The checkpoint remains gated only on authoritative external CI.

## Codex Cloud execution note
Codex Cloud may not expose a writable Git remote or authenticated GitHub CLI inside its sandbox. That condition alone is not a blocker. Cloud should keep implementing safe backlog work and record CI-dependent verification as `PENDING EXTERNAL CI` until the batch is published. The user should not be asked to Apply locally after every task.

## USER ACTION REQUIRED
None right now.

Later checkpoints may require batched external setup for:
- Firebase project/app configuration.
- Apple Developer Program / App Store Connect setup for TestFlight.
- Signing and CI secrets.

## Blockers
The Cloud snapshot has no configured Git remote, so it cannot publish this milestone batch or trigger the required GitHub/macOS CI run from inside the sandbox. This is the consolidated M0.6 external verification boundary, not an implementation defect.

## Exact next action
Run the M0.6 bootstrap checkpoint review, publish the milestone batch, and obtain one green authoritative macOS `iOS CI` run before marking M0.1–M0.6 `DONE` and starting M1.1.

## Future candidates
None approved for implementation beyond the explicit backlog in `docs/implementation_plan.md`.
