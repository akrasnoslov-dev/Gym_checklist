# No-Cost CI and Quota Continuation Policy

## Purpose
This policy keeps iOS verification useful while minimizing GitHub Actions macOS usage for a private repository developed primarily from Windows/Codex.

The project uses a two-tier CI model:
- cheap Linux checks for normal code checkpoints;
- authoritative macOS/Xcode verification only at meaningful checkpoints.

The policy also defines how implementation continues if the included GitHub Actions quota is exhausted.

## User decision
- Paid GitHub Actions usage is not approved.
- Do not ask the user to add a payment method, increase an Actions budget, buy GitHub Pro, rent a macOS runner, or pay for another CI provider merely to continue normal implementation.
- The repository is public by the user's explicit 2026-08-24 decision so free GitHub-hosted macOS Actions are available; do not make it private without further instruction.

## Normal no-cost CI strategy
### Linux checks — default checkpoint CI
Normal pushes to `dev` and PRs run `.github/workflows/linux-checks.yml` on `ubuntu-latest` when code/configuration changed.

Linux CI should perform every useful platform-independent check available, including repository consistency checks, merge-conflict marker detection, Xcode scheme XML validation, whitespace checks, and `swift test` if a Linux-compatible Swift package exists.

Linux checks are useful engineering feedback but do **not** prove that the iOS app compiles or that simulator/UI tests pass.

### macOS checks — authoritative but deliberately sparse
`.github/workflows/ios-ci.yml` is the authoritative Xcode build/test workflow.

A normal push to `dev` must not allocate a macOS runner. The macOS job runs only when one of these conditions applies:
1. the push commit message contains `[macos-ci]`;
2. the workflow is started manually with `workflow_dispatch`;
3. a release-oriented pull request targets `main`.

Use `[macos-ci]` for milestone/checkpoint commits that genuinely need authoritative Xcode evidence. Do not add `[macos-ci]` to every task or routine checkpoint.

Preferred cadence during normal MVP development:
- run Linux checks continuously on code checkpoints;
- run one consolidated macOS build/unit/UI-test verification at milestone checkpoints;
- run macOS earlier only when a change is unsafe to continue without Xcode evidence (for example Xcode project configuration, build-system changes, dependency integration, signing/release plumbing, or a suspected compile/UI-test regression).

When diagnosing a real Xcode failure, use the narrowest manual `verification_scope` before spending a consolidated run:
- `build` runs `build-for-testing` to compile the app and both test bundles without executing tests;
- `unit` runs only `GymChecklistTests` after compilation is clean;
- `ui` runs only `GymChecklistUITests` after the relevant build/lower test evidence is clean;
- `full` runs the complete suite only for milestone reconciliation or after the preceding layers pass.

Batch equivalent compiler, unit-test, or UI-test diagnostics into one correction before rerunning the matching layer. A UI-test-only edit does not require rerunning unaffected unit tests that already passed; it still requires an authoritative test-bundle compile before focused UI execution.

A milestone checkpoint that explicitly requires authoritative macOS verification cannot be marked `DONE` until that verification passes, even though implementation may continue provisionally where this policy allows it.

## CI waste controls
Both CI workflows should use GitHub Actions concurrency with `cancel-in-progress: true`, so a newer run on the same ref cancels an obsolete in-progress run.

Docs-only changes are excluded from automatic Linux/macOS CI through path filters. A manual macOS run remains available when needed.

Prefer a single consolidated authoritative macOS run over rerunning every historical commit.

## Verification-deferred mode
When GitHub-hosted macOS CI cannot start solely because the included Actions quota is exhausted:

1. Treat this as `CI UNAVAILABLE — FREE QUOTA EXHAUSTED`, not as a product/code failure.
2. Do not mark tasks or milestone checkpoints `DONE` when their required macOS CI has not passed.
3. Record implementation-complete tasks as `IN PROGRESS (PENDING CI)` or equivalent in `docs/progress.md`.
4. Run every useful non-macOS check available in the current environment and Linux CI when available.
5. Continue to later tasks and later milestones when the only unsatisfied dependency is unavailable macOS CI and continuing is technically safe.
6. For scheduling purposes only, a dependency/checkpoint that is implementation-complete and pending solely on quota-blocked CI counts as provisionally satisfied. This exception overrides generic `dependencies must be DONE` and milestone-checkpoint stop rules in `AGENTS.md`, `docs/codex_instructions.md`, and `docs/implementation_plan.md` only for deciding whether safe implementation may continue.
7. This exception does **not** change acceptance criteria or the meaning of `DONE`. Required CI must eventually pass before affected tasks/checkpoints are finally marked `DONE` and before release readiness can be claimed.
8. If a real CI run starts and produces an actual build/test failure, that is not covered by this exception. Diagnose/fix the real failure before relying on affected behavior where unsafe.
9. Keep focused checkpoint commits and `docs/progress.md` current so deferred verification can later be consolidated.

## Cross-milestone rule
A milestone checkpoint may remain `IN PROGRESS (PENDING CI)` while implementation proceeds into the next milestone if:
- all implementation/review work for the checkpoint is otherwise complete;
- the only missing requirement is macOS CI blocked by exhausted included quota;
- required agent reviews have no unresolved blocking findings; and
- the next task can be implemented safely without evidence from the unavailable CI run.

Do not use this rule to bypass product ambiguity, security blockers, required credentials/configuration, destructive decisions, or actual test failures.

## CI reset checkpoint
When free GitHub Actions capacity becomes available again:
- publish the latest coherent checkpoint if needed;
- trigger one consolidated authoritative macOS run, preferably via a coherent `[macos-ci]` checkpoint commit or manual dispatch;
- fix real failures;
- reconcile all earlier `PENDING CI` tasks/checkpoints in order;
- mark them `DONE` only when their required verification is genuinely satisfied.

## Cost guardrail
Do not enable or recommend paid CI as an execution requirement for this project unless the user explicitly reverses the no-paid-Actions decision.
