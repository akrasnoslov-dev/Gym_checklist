# Task Spec — Agentic Development Workflow

Date: 2026-09-21
Status: IN PROGRESS

## Goal

Introduce the CCWBot-style agentic development workflow into Gym Checklist, adapted to this repository instead of copied mechanically.

The durable result must live in the repository and be enforced where practical through repository instructions, routing/configuration, and contract checks.

## Clarified requirements

- Keep Gym Checklist's existing documentation structure where it already works.
- Add a small `docs/source_of_truth.md` as the canonical ownership map.
- Make `AGENTS.md` a short bootstrap file rather than the main store of workflow policy.
- Make `docs/codex_instructions.md` the canonical owner of the agent-assisted development workflow.
- Every non-trivial feature, bug fix, refactor, or larger task uses:
  1. one compact clarification batch before implementation;
  2. one task specification;
  3. validation/test contract first;
  4. RED before production implementation where applicable;
  5. isolated task/worker Git worktrees;
  6. orchestrator/worker model routing;
  7. GREEN verification before completion;
  8. orchestrator review and final acceptance;
  9. PR to `dev`, never auto-merged.
- Trivial mechanical changes may skip the full ceremony when risk and behavior impact are negligible.
- `gpt-5.6-sol` is orchestrator/final acceptance.
- `gpt-5.6-terra` is the default implementation worker.
- `gpt-5.6-luna` is for simple, mechanical, low-risk worker tasks.
- Sol as implementation worker is escalation-only.
- Worker count is adaptive; no project-level fixed count.
- Medium reasoning is the default unless escalation is justified.
- Token efficiency is a permanent objective.
- Preserve existing review-agent routing and CI/macOS policies unless they conflict with the new workflow.

## Scope

- `AGENTS.md`
- `docs/source_of_truth.md`
- `docs/codex_instructions.md`
- `agents/routing.toml`
- `.codex/config.toml`
- `README.md`
- Linux workflow contract enforcement
- A deterministic workflow/config contract check
- This task specification

## Out of scope

- Swift/SwiftUI product behavior
- Firebase behavior or schema
- Xcode project changes
- Product/UX changes
- Paid Apple/Firebase release work
- macOS/Xcode verification for this process-only change
- Copying CCWBot-specific product, deployment, or operational rules

## Acceptance criteria

- Source-of-truth ownership is explicit and non-duplicative.
- `AGENTS.md` points agents to canonical owners and remains compact.
- `docs/codex_instructions.md` defines clarification -> task spec -> RED -> implementation -> GREEN -> review -> PR.
- Task specs are explicitly historical/task-scoped, not permanent policy owners.
- Worktree isolation and adaptive worker use are explicit.
- Sol/Terra/Luna routing is explicit in `agents/routing.toml`.
- `.codex/config.toml` sets Sol primary, Terra default spawned agent, medium reasoning.
- Existing specialized review agents remain intact.
- Linux CI runs a workflow contract check.
- The new contract check is demonstrated RED before implementation and GREEN after implementation.
- Full diff is reviewed before PR readiness.
- PR targets `dev` and is not merged.

## Affected areas/files

Expected:
- `AGENTS.md`
- `docs/source_of_truth.md`
- `docs/codex_instructions.md`
- `agents/routing.toml`
- `.codex/config.toml`
- `README.md`
- `scripts/verify_agentic_workflow_contract.ps1`
- `.github/workflows/linux-checks.yml`

No application source or test target should change.

## Risks and edge cases

- Duplicating workflow policy across `AGENTS.md`, README, and Codex docs.
- Breaking existing macOS two-pass verification policy while reorganizing ownership.
- Accidentally replacing specialized review-agent routing with generic execution routing.
- Making trivial documentation fixes unnecessarily expensive.
- Allowing config and routing policy to drift later.
- Task specs accidentally becoming permanent policy sources.

## DB/schema/data impact

None.

## Test strategy

This is process/configuration work, so a normal product regression test is not meaningful.

Strongest applicable validation:
1. Add `scripts/verify_agentic_workflow_contract.ps1` first.
2. Wire it into Linux CI.
3. Confirm it fails because the required ownership/config/routing rules do not yet exist (RED).
4. Implement repository workflow/config changes.
5. Rerun the same contract plus existing Linux checks until GREEN.
6. Review the full branch diff.

## Implementation plan

1. Create this task spec.
2. Add the workflow contract check and CI invocation.
3. Demonstrate RED on the incomplete repository state.
4. Add source-of-truth ownership map.
5. Refactor `AGENTS.md` into bootstrap instructions.
6. Expand `docs/codex_instructions.md` into the canonical workflow owner while preserving relevant CI rules.
7. Extend `agents/routing.toml` with execution-model routing without removing specialized review rules.
8. Add `.codex/config.toml` as executable defaults aligned with routing policy.
9. Align README references.
10. Get Linux/contract checks GREEN.
11. Review full diff and CI evidence.
12. Mark PR ready for review. Do not merge.

## Worker decomposition

No parallel implementation workers for this task.

Reason: the changed files are tightly coupled policy/configuration surfaces. Parallel edits would create more coordination and conflict risk than benefit. The task uses one isolated feature branch. Future implementation workers are required to use separate worktrees.
