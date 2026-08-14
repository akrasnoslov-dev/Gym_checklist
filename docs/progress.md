# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 0 — Repository/bootstrap.

## Active task
`M0.1` — Create the native iOS SwiftUI project, unit test target, and UI test target. Implementation checkpoint is commit `6b0c8f0` on branch `work` (the commit will change if this progress note is amended into it).

## Completed
- Repository created.
- `main` initialized.
- `dev` branch created.
- Product, UX, architecture, Codex workflow, and implementation plan added.
- Agent routing framework added/planned.

## Next task
`M0.1` — Create Xcode iOS SwiftUI project named `GymChecklist` with unit and UI test targets.

## Verification status
- The Xcode project, shared scheme, unit smoke test, and UI launch test are implemented locally.
- Static checks passed: `git diff --check`, scheme XML parsing, and assertions for all three target product types, iOS 17.0, and UI test host configuration.
- `xcodebuild` is unavailable in this Linux environment, so no local iOS build/test result is claimed.
- Authoritative macOS GitHub Actions build/tests have not run because this checkout has no configured Git remote. M0.1 remains `IN PROGRESS` until that required CI verification passes.

## Agent reviews
- `test_ci_agent` reviewed M0.1. Its project/scheme/test settings are applied; the remaining blocking finding is a successful macOS CI run.

## USER ACTION REQUIRED
None right now.

Later checkpoints will require:
- Firebase project/app configuration.
- Apple Developer Program / App Store Connect setup for TestFlight.
- Signing and CI secrets.

Codex must consolidate those requests rather than interrupting after every small external setup step.

## Blockers
- This checkout has no Git remote, the `make_pr` integration is unavailable, and `gh pr create` cannot authenticate because no `GH_TOKEN`/GitHub CLI login is configured. Configure the repository remote/PR integration, push this checkpoint, open a PR to `dev`, and run `.github/workflows/ios-ci.yml` to complete M0.1.

## Exact next action
Push the M0.1 checkpoint to the hosted repository, open a PR targeting `dev`, and require a green `xcodebuild ... test` macOS CI run. Then record the run, mark M0.1 `DONE`, and begin M0.2.

## Future candidates
None approved for implementation beyond the explicit backlog in `docs/implementation_plan.md`.
