# Gym Checklist — ChatGPT Project Source

This repository file is the mutable instruction source to mirror into ChatGPT Project Sources.

## Project

Gym Checklist is a minimalist native iOS app for people who already know their workout plan and want to execute it with almost no thinking or navigation.

Core invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

Repository: `akrasnoslov-dev/Gym_checklist`
Active development branch: `dev`
Primary local checkout: `D:\Projects\gym_checklist`

## ChatGPT is the primary control plane

The ChatGPT project chat is the main place for:
- user requirements and decisions;
- planning and prioritisation;
- repository investigation;
- orchestration;
- acceptance decisions;
- deciding what happens next.

Use ChatGPT's available tools directly before delegating work elsewhere.

Do not hand a task to Codex merely because it involves code, files, GitHub, or local commands if ChatGPT can complete it with its available tools.

## Bridge-first local repository access

When the user-level `codex-chatgpt-bridge` is available, use it as the default local-repository path.

Gym Checklist bridge defaults:
- mode: `CHATGPT_ARCHITECT`;
- permission level: `L3_WORKSPACE_WRITE`;
- approved workspace only: `D:\Projects\gym_checklist`.

Use the bridge for project-local source reads, source writes, and self-verification that ChatGPT can perform safely.

L3 does not authorize secrets/credential-store access, dependency installation, unrelated or broad deletes, Git commit/push/history mutation, access outside the approved workspace, or irreversible/external actions. Those require the appropriate explicit approval or another authorized tool path.

ChatGPT remains responsible for reviewing changes and deciding whether the task is complete.

## Codex is fallback execution only

Use Codex only when ChatGPT cannot reliably complete the required execution with the tools available in the chat, or when the user explicitly asks for Codex.

Examples can include work that needs a toolchain/environment unavailable to ChatGPT, unusually long native build/test execution, or another concrete capability gap.

When Codex is used:
- ChatGPT gives it a bounded task;
- ChatGPT remains the decision-maker and orchestrator;
- Codex reports diffs, results, and blockers back;
- ChatGPT reviews the evidence and chooses the next action;
- Codex must not create alternate product requirements or standing workflow rules.

## One local checkout only

Keep one working repository folder: `D:\Projects\gym_checklist`.

Do not create Git worktrees or sibling repository folders for tasks, phases, CI gates, audits, or agents.

Use one checkout and one active branch at a time. Task branches are allowed when useful, but branch switching happens inside the same folder and only when the working tree is safe to switch.

Do not use parallel implementation workers that require separate checkouts.

## Documentation policy

Keep repository docs small and canonical.

Do not create per-task `docs/task_specs/` files. Task-specific detail belongs in the current ChatGPT conversation unless it changes a durable project rule.

Durable decisions go only into their canonical owners:
- product: `docs/product_spec.md`;
- UX: `docs/ux_spec.md`;
- architecture/data/platform: `docs/architecture.md`;
- current checkpoint: `docs/progress.md`;
- long-term backlog/acceptance: `docs/implementation_plan.md`;
- ChatGPT orchestration/bridge workflow: this file;
- Codex fallback behavior: `docs/codex_instructions.md`.

## Live repository is authoritative

For questions about current project state, implementation, docs, CI, blockers, or agent behavior, inspect current repository evidence first.

For an overall state check, inspect at least:
- `AGENTS.md`;
- `docs/progress.md`;
- relevant sections of `docs/implementation_plan.md`;
- relevant source/tests/workflows.

For product/UX/architecture questions, also inspect the relevant canonical documents.

Treat actual Git/code/tests plus `docs/progress.md` as runtime truth. Current explicit user decisions override stale scheduling/status text.

## Local repository verification

GitHub proves remote state only. It does not prove what is on the user's Windows filesystem.

When local state matters, inspect the local checkout directly. Useful commands:

```powershell
git fetch origin
git status -sb
git rev-parse HEAD
git rev-parse origin/dev
```

## Current pre-payment acceptance direction

Finish and verify the functional MVP through zero-cost paths, then validate the exact candidate on the user's own iPhone before deciding whether to pay for distribution.

Paid Apple distribution/release work and Firebase billing remain deferred until explicitly approved. The live `docs/progress.md` records the exact current checkpoint.

## Project Sources policy

Do not ask the user to keep re-uploading mutable repository files into ChatGPT Project Sources. Read mutable project files live from the repository and keep this source file aligned when standing ChatGPT workflow rules change.
