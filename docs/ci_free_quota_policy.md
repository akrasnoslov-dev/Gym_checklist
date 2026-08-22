# No-Cost CI Quota Continuation Policy

## Purpose
This policy applies when the GitHub Actions included quota is exhausted and the user has explicitly chosen not to enable paid Actions usage.

The goal is to keep implementation moving without pretending that unavailable macOS/Xcode verification has passed.

## User decision
- Paid GitHub Actions usage is not approved.
- Do not ask the user to add a payment method, increase an Actions budget, buy GitHub Pro, rent a macOS runner, or pay for another CI provider merely to continue normal implementation.
- Wait for the included GitHub Actions quota to reset for authoritative hosted macOS verification unless a genuinely free macOS verification path becomes available.

## Verification-deferred mode
When GitHub-hosted macOS CI cannot start solely because the included Actions quota is exhausted:

1. Treat this as `CI UNAVAILABLE — FREE QUOTA EXHAUSTED`, not as a product/code failure.
2. Do not mark tasks or milestone checkpoints `DONE` when their required macOS CI has not passed.
3. Record implementation-complete tasks as `IN PROGRESS (PENDING CI)` or equivalent in `docs/progress.md`.
4. Run every useful non-macOS check available in the current environment: static checks, deterministic source checks, repository consistency checks, test-source review, `git diff --check`, XML/YAML validation, and any Swift checks that are actually available.
5. Continue to later tasks and later milestones when the only unsatisfied dependency is unavailable macOS CI and continuing is technically safe.
6. For scheduling purposes only, a dependency/checkpoint that is implementation-complete and pending solely on quota-blocked CI counts as provisionally satisfied. This exception overrides generic `dependencies must be DONE` and milestone-checkpoint stop rules in `AGENTS.md`, `docs/codex_instructions.md`, and `docs/implementation_plan.md` only for deciding whether safe implementation may continue.
7. This exception does **not** change acceptance criteria or the meaning of `DONE`. Required CI must eventually pass before affected tasks/checkpoints are finally marked `DONE` and before release readiness can be claimed.
8. If a real CI run starts and produces an actual build/test failure, that is not covered by this exception. Diagnose/fix the real failure before relying on affected behavior where unsafe.
9. Keep focused checkpoint commits and `docs/progress.md` current so all deferred verification can later be consolidated.

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
- run the authoritative macOS build/unit/UI test workflow against the accumulated state;
- fix real failures;
- reconcile all earlier `PENDING CI` tasks/checkpoints in order;
- mark them `DONE` only when their required verification is genuinely satisfied.

Prefer one consolidated authoritative run over rerunning every historical commit.

## Cost guardrail
Do not enable or recommend paid CI as an execution requirement for this project unless the user explicitly reverses the no-paid-Actions decision.