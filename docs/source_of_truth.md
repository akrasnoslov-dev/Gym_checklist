# Gym Checklist — Repository Source of Truth

This repository is the durable source of truth for Gym Checklist product rules, UX, architecture, development workflow, agent routing, verification, and current project state.

Chat history, ChatGPT Project instructions, Codex/Work prompts, PR comments, memories, and external notes may provide task-specific context. They must not become competing owners of permanent project rules.

A current explicit user instruction may change the task or override an older decision. If that decision is intended to remain permanent, update the canonical repository owner in the same task.

## Canonical ownership

Each durable rule has one primary owner:

- Product behavior and scope: `docs/product_spec.md`
- UX behavior and interaction rules: `docs/ux_spec.md`
- Technical architecture, data boundaries, and platform constraints: `docs/architecture.md`
- Agent-assisted development workflow, clarification/test-first gates, worktree rules, branch/PR policy, and verification process: `docs/codex_instructions.md`
- Agent/model execution routing and specialist review routing: `agents/routing.toml`
- Codex project-scoped executable model defaults: `.codex/config.toml` (adapter only; it must match `agents/routing.toml`)
- Long-term implementation backlog and milestone acceptance definitions: `docs/implementation_plan.md`
- Current runtime/project checkpoint, latest meaningful verification, blockers, and next action: `docs/progress.md`
- Current UI/UX redesign process and durable visual rules when relevant: `docs/ui_redesign_plan.md`, `docs/ui_research_phase4.md`, and `docs/ui_ux_design_rules.md`
- Task-specific clarified requirements, plans, test evidence, and decisions: `docs/task_specs/`
- Public project overview: `README.md`

`AGENTS.md` is a bootstrap file. It points agents to the canonical owners above and must stay compact. It must not become a second copy of workflow, product, release, or scheduling policy.

`docs/task_specs/` contains task-specific historical records. A task spec may preserve accepted requirements and evidence for one task, but it must never become the permanent owner of standing project rules.

## Runtime truth

Actual Git/code/tests are evidence of what currently exists. `docs/progress.md` records the current project checkpoint.

When implementation and canonical documentation disagree:
1. report the drift;
2. use code/tests as evidence of current behavior;
3. use the canonical owner above for intended behavior;
4. fix the inconsistency instead of creating another copy of the rule.

Do not treat stale milestone text as newer than current code, tests, `docs/progress.md`, or a current explicit user decision.

## Conflict resolution

When repository files disagree:
1. use the canonical owner listed above for that subject;
2. inspect current code/tests when the disagreement concerns implementation state;
3. update the stale/non-owning file to point to the owner instead of duplicating policy.

Do not solve conflicts by adding the same standing rule to more files.

## Agent/session bootstrap

For non-trivial repository work:
1. read `AGENTS.md`;
2. read this file;
3. read `docs/codex_instructions.md`;
4. read `agents/routing.toml`;
5. read `docs/progress.md`;
6. read only the task-relevant canonical product/UX/architecture/backlog/design documents;
7. inspect Git/worktree state, relevant source/tests, and current CI evidence.

Do not preload the whole repository or all of `docs/`.
