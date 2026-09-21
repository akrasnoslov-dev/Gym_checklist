# Gym Checklist — Agent-Assisted Development Workflow

This file is the canonical owner of the Gym Checklist development workflow for ChatGPT Work, Codex, and other repository agents.

Read `docs/source_of_truth.md` first. Do not copy standing workflow rules into task prompts, chat memory, PR comments, or external notes. Task prompts should contain only the requested task delta.

## What counts as non-trivial

Use the full workflow below for every feature, bug fix, refactor, behavior change, data/schema change, CI/configuration change, agent/workflow change, or larger task.

A change may be treated as trivial only when it is clearly mechanical, low-risk, and behavior-neutral, for example:
- a typo;
- formatting only;
- a broken documentation link;
- a comment-only correction;
- similarly clerical metadata.

If there is reasonable doubt, treat the task as non-trivial.

## Mandatory pipeline

### 1. Clarification gate

Before implementation of a non-trivial task:
1. inspect the repository read-only when needed to understand the current state;
2. ask the user one compact batch of clarification questions;
3. cover requirements, constraints, expected behavior, important edge cases, acceptance criteria, and explicit non-goals;
4. wait for the user's answers before changing implementation files.

Do this even when the request initially appears clear.

If the user already answered the relevant questions in the same task, do not ask them again.

### 2. Task specification and plan

After clarification and before implementation:
1. create one task specification under `docs/task_specs/YYYY-MM-DD-<task-slug>.md`;
2. record:
   - goal;
   - clarified requirements;
   - scope;
   - out of scope;
   - acceptance criteria;
   - affected areas/files;
   - risks and edge cases;
   - DB/schema/data impact, if any;
   - test strategy;
   - implementation plan;
   - worker decomposition, if useful;
3. keep the task spec current when accepted requirements change;
4. write the implementation plan from the task spec.

Task specs are historical task records. They are not permanent policy owners and must not override `docs/source_of_truth.md` or its canonical owners.

### 3. Test-first gate

Define validation before production implementation.

For a behavior change or bug fix:
1. add or modify the focused automated test first;
2. run it against the old behavior;
3. confirm the new expectation is RED for the intended reason;
4. only then change production code;
5. implement until the focused test is GREEN.

For documentation, configuration, infrastructure, migration, or workflow work where a normal regression test is not meaningful:
1. create the strongest applicable contract, validation, lint, migration, or configuration check first;
2. run it and confirm the intended RED state when a meaningful failing state exists;
3. document why a normal product regression test is not applicable;
4. implement until the contract is GREEN.

After implementation, run the repository-required affected checks and final verification.

**No green verification, no completion.**

Never describe a task as complete while an applicable required check is failing, skipped without an explicit reason, or not run.

### 4. Isolated Git work

Use isolated Git branches and `git worktree` for implementation workers.

- Start non-trivial implementation from current `dev`.
- Create one task/integration branch for the task.
- A single implementation worker uses one isolated task worktree.
- Each parallel worker gets its own branch and worktree.
- Parallel workers must never edit the same worktree.
- Give each worker a clearly bounded, preferably independent scope.
- The orchestrator integrates accepted worker branches one by one.
- Rerun affected validation after each integration.
- Do not create parallel workers when the coordination cost is higher than the expected benefit.
- Never reset, overwrite, or discard coherent user work or uncommitted changes.

### 5. Orchestrator and workers

For ChatGPT Work and Codex:

- Orchestrator and final acceptance: `gpt-5.6-sol`.
- Default implementation worker: `gpt-5.6-terra`.
- Simple, mechanical, low-risk worker: `gpt-5.6-luna`.
- Use Sol as an implementation worker only as escalation when complexity, risk, or a failed lower-tier attempt justifies it.
- Worker count is adaptive. There is no fixed project-level worker count.
- Medium reasoning is the default. Escalate reasoning only when the task justifies it.

The orchestrator owns:
- clarification synthesis;
- planning;
- decomposition;
- model routing;
- worker scopes;
- integration;
- review;
- final acceptance.

Worker completion is not final acceptance. The orchestrator must review worker diffs and test evidence before accepting them.

Execution-model policy is canonical in `agents/routing.toml`. `.codex/config.toml` is the executable Codex adapter and must remain consistent with that policy.

### 6. Token-efficiency objective

Token-efficiency objective: maximum useful work with minimum unnecessary context and model cost, without sacrificing correctness.

- Use Sol mainly for clarification synthesis, planning, difficult decisions, integration, review, and final acceptance.
- Use Terra/Luna for bounded implementation work.
- Search first; read only relevant files and canonical docs.
- Do not repeatedly load the entire repository.
- Pass workers only the task spec, relevant canonical rules, assigned scope, acceptance criteria, and necessary evidence.
- Reuse the task spec as compact shared context.
- Avoid duplicate reviews and unchanged reruns.
- Use parallel workers only when they are truly independent and useful.
- Prefer reasonable/default reasoning over maximum reasoning everywhere.

### 7. Specialist review routing

After implementation, use the specialist review agents required by `agents/routing.toml`.

Do not replace those domain reviews with generic workers. Execution routing and specialist review routing are complementary.

The orchestrator must:
1. inspect the full task diff;
2. review test/contract evidence;
3. run required specialist reviews;
4. address valid blocking findings;
5. rerun affected checks after fixes;
6. perform final acceptance only when the required evidence is GREEN.

## Repository investigation rules

Before stating material claims about current implementation or project state:
- inspect current primary repository evidence;
- prefer code/tests for what exists;
- prefer the canonical owner for intended behavior;
- report documentation/implementation drift instead of guessing;
- search repository-wide before claiming functionality is missing;
- do not repeatedly read unrelated files.

For current local filesystem state, GitHub proves only remote state. Do not claim the user's local checkout is synchronized unless local Git state is directly available or the user provides it.

## Branch and PR policy

- `main`: stable/release only.
- `dev`: integration/default development branch.
- Non-trivial implementation uses a focused task branch based on current `dev`.
- Worker branches are subordinate to the task/integration branch and use separate worktrees.
- PRs target `dev` by default.
- `dev -> main` requires explicit user approval.
- Do not auto-merge any PR.
- Prepare the PR only after required validation and orchestrator review are complete.
- A worker branch is never accepted directly as the final task result.

Every non-trivial PR should include:
- summary;
- behavior impact;
- files/areas changed;
- DB/schema/data impact;
- verification performed;
- RED evidence where applicable;
- GREEN evidence;
- self-review/risk check;
- known limitations or follow-ups.

## Current CI strategy

Current runtime/release phase constraints live in `docs/progress.md` and the relevant current sections of `docs/implementation_plan.md`.

Linux CI is routine feedback. macOS/Xcode CI is authoritative for iOS compilation and simulator behavior.

Use the repository's existing zero-cost policy while pre-payment acceptance remains active. Do not enable paid Apple or Firebase services without explicit approval.

### macOS remote-gate conservation

macOS/Xcode CI is an expensive authoritative gate, not the normal development loop.

For production Swift, XCTest/UI-test, persistence/migration, Xcode project, or other iOS-runtime-relevant changes:

**Pass A — implementation/hardening**
- finish the whole runnable implementation batch;
- add/update regression coverage;
- review affected code and tests;
- run all available local/static/security/offline checks;
- update relevant docs;
- commit/push a coherent candidate;
- record `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>` in `docs/progress.md`;
- do not dispatch authoritative macOS CI in the same implementation task.

**Pass B — fresh final audit**
- start from the exact recorded SHA;
- perform an independent preflight review;
- rerun available local/static checks;
- if production/test/project code must change, the task becomes Pass A again and records a new SHA;
- only a clean audit with no such changes may record `REMOTE_GATE_APPROVED <SHA>` and dispatch one justified candidate/full run.

A red candidate/full run revokes approval and restarts the process.

Do not use macOS CI as a routine compiler oracle. Do not dispatch it after every fix or commit.

For documentation/process/config-only work that cannot affect iOS compilation or simulator behavior, macOS verification is not required unless the change itself alters the authoritative iOS workflow or another iOS-runtime gate in a way that needs live verification.

### Asynchronous CI

Do not keep a task alive only to wait for macOS CI.

After dispatch:
- record run ID, scope, and exact SHA in `docs/progress.md`;
- continue only useful work that cannot invalidate the tested candidate;
- if none remains, end the task;
- inspect an in-progress run once on the next task rather than polling repeatedly.

## Useful Windows/Linux verification

Use task-relevant checks. Current common commands include:

```text
git status -sb
git diff --check
pwsh -File scripts/verify_agentic_workflow_contract.ps1
pwsh -File scripts/verify_security_hygiene.ps1
pwsh -File scripts/verify_account_deletion_contract.ps1
pwsh -File scripts/verify_firestore_rules.ps1
pwsh -File scripts/verify_offline_contract.ps1
pwsh -File scripts/verify_google_signin_configuration_contract.ps1
pwsh -File scripts/verify_release_workflow_contract.ps1
pwsh -File scripts/verify_ios_ci_contract.ps1
```

Run only the checks relevant to the task plus the repository-required CI gates. Do not run expensive or unrelated verification for ceremony.

## Final acceptance

Before calling a non-trivial task complete:
1. confirm accepted requirements still match the task spec;
2. confirm all applicable acceptance criteria are satisfied;
3. confirm required focused and broader checks are GREEN;
4. inspect the full diff;
5. inspect required specialist-review findings;
6. confirm no unrelated changes were introduced;
7. update the task spec if accepted scope changed;
8. prepare/update the PR with RED/GREEN and risk evidence;
9. leave merge ownership with the user.
