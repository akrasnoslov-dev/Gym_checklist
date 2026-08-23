# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 3 — Today implementation may proceed provisionally while the Milestone 2 checkpoint remains pending authoritative macOS CI.

## Active task
`M3.1` — Implement active Today workout layout.

## Verification-deferred state
The user explicitly chose **no paid GitHub Actions usage**. The included GitHub Actions quota is exhausted for the current billing cycle, so GitHub-hosted macOS jobs cannot currently provide authoritative Xcode verification.

`docs/ci_free_quota_policy.md` is active. It allows safe implementation to continue across milestone boundaries when the **only** unsatisfied requirement is macOS CI unavailable because the included quota is exhausted. This does not change acceptance criteria and does not allow unverified tasks/checkpoints to be marked `DONE`.

## CI cost-control strategy — implemented
The repository now uses tiered CI to reduce the chance of exhausting the included GitHub Actions quota again:
- `.github/workflows/linux-checks.yml` runs low-cost platform-independent checks on normal code pushes to `dev` and relevant PRs;
- `.github/workflows/ios-ci.yml` remains the authoritative macOS/Xcode workflow but a normal `dev` push does not allocate a macOS runner;
- macOS runs are reserved for commits explicitly containing `[macos-ci]`, manual `workflow_dispatch`, and release PRs targeting `main`;
- both workflows use `concurrency` with `cancel-in-progress: true`;
- docs-only changes are excluded from automatic CI.

Codex should use Linux CI for routine checkpoints and request authoritative macOS verification at milestone checkpoints or earlier only when Xcode evidence is required for safe continuation. Do not put `[macos-ci]` on every commit.

## Completed and verified
- Milestone 0 (`M0.1`–`M0.6`): `DONE`; authoritative macOS CI passed.
- Milestone 1 (`M1.1`–`M1.6`): `DONE`; authoritative macOS CI passed.
- Milestone 2 `M2.1`–`M2.8`: implementation complete and authoritative macOS CI passed.
- M2.6 CI: PASS for `4c956ac`, run `32503808413`.
- M2.7 CI: PASS for `000f798`, run `32506833516`.
- M2.8 CI: PASS for `ff2377a`, run `32528720383`.

## Milestone 2 pending CI
### M2.9 — Copy Workout
Implementation is complete.
- Plan-only copy with fresh workout/exercise/set identities.
- Completion, actual values, skipped state, and history are reset.
- Source/destination remain independent.
- Occupied destinations are not silently overwritten.
- Deterministic/local checks passed.

The attempted macOS run `32530423499` did not execute workflow steps and produced no job logs. This is treated as CI infrastructure/quota unavailability, not as an observed code/test failure.

### M2.10 — Repeat Workout
Implementation is complete.
- Fixed weekly cadence.
- 4 weeks / 8 weeks / Until date.
- Occupied dates are explicitly skipped.
- Generated workouts are independent plan-only copies with fresh identities.
- Deterministic/local checks and required agent reviews passed.

### M2.11 — Program UX checkpoint
Required Program reviews are provisionally satisfied with no blocking findings. The checkpoint remains `IN PROGRESS (PENDING CI)` because the consolidated authoritative macOS run has not yet been possible.

## Current Program capability
With local/mock persistence, Program currently supports:
- week/date navigation;
- create workout for a concrete date;
- bundled exercise catalog and search;
- custom exercises;
- add/delete/reorder exercises;
- arbitrary set add/edit/delete/reorder with reps/weight/time;
- workout editing/deletion;
- copy workout;
- weekly repeat generation.

## GitHub Actions quota
The current billing/usage report shows Actions usage fully covered by included usage so far (`net_amount = 0`). Paid Actions usage is not approved. Do not ask the user to enable billing merely to continue development.

When included GitHub Actions capacity becomes available again, run one consolidated authoritative macOS build/unit/UI test against the latest coherent checkpoint using `[macos-ci]` or manual dispatch, fix real failures, and reconcile all affected `PENDING CI` tasks/checkpoints before marking them `DONE`.

After quota resets, keep the new tiered CI strategy permanently: routine code checkpoints use Linux CI; macOS remains sparse and authoritative.

## USER ACTION REQUIRED
None for the current implementation work or CI optimization.

Later genuine external checkpoints may still require batched user action for Firebase configuration, Apple Developer/App Store Connect, signing, or release secrets.

## Blockers
No product or implementation blocker is currently known.

Authoritative macOS CI is temporarily unavailable because the free GitHub Actions quota is exhausted. Under `docs/ci_free_quota_policy.md`, this is a verification deferral rather than a development stop.

## Exact next action
Start `M3.1` now. Read the full M3.1 task plus Product/UX/Architecture references, apply the required agents, implement the active Today workout layout using the existing local/mock repository/domain model, add appropriate tests, run all available non-macOS checks, checkpoint the work, then continue through later safe M3 tasks without waiting for paid CI.

For routine M3 checkpoints, rely on Linux CI and deterministic checks. Trigger macOS only at the next meaningful authoritative checkpoint or earlier if a real Xcode-dependent risk makes continuation unsafe.

If a task exposes a real dependency that cannot be validated safely without macOS/Xcode, stop at that specific dependency and record it. Do not stop merely because an earlier milestone checkpoint is `PENDING CI` for quota reasons.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
