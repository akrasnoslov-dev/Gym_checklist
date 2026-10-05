# Gym Checklist — Repository Source of Truth

The repository is the durable source of truth for product rules, UX, architecture, development workflow, verification, and current project state.

The current explicit user instruction has highest priority for the active task. If it changes a standing rule, update the canonical repository owner in the same task.

## Canonical ownership

Each durable subject has one primary owner:

- ChatGPT orchestration, bridge use, single-checkout policy, and Codex delegation boundary: `CHATGPT_PROJECT_SOURCE.md`
- Repository bootstrap for agents: `AGENTS.md`
- Product behavior and scope: `docs/product_spec.md`
- UX behavior and interaction rules: `docs/ux_spec.md`
- Technical architecture, data boundaries, and platform constraints: `docs/architecture.md`
- Codex fallback execution and verification behavior: `docs/codex_instructions.md`
- Specialist review routing: `agents/routing.toml`
- Codex executable model defaults: `.codex/config.toml`
- Long-term implementation backlog and milestone acceptance definitions: `docs/implementation_plan.md`
- Current runtime checkpoint, verification, blockers, and next action: `docs/progress.md`
- Current UI/UX design decisions when relevant: `docs/ui_redesign_plan.md`, `docs/ui_research_phase4.md`, and `docs/ui_ux_design_rules.md`
- Public project overview: `README.md`

Task-specific planning and discussion stay in the active ChatGPT conversation unless they need to become a durable project rule or checkpoint.

There is no per-task `docs/task_specs/` system.

## Runtime truth

Actual Git/code/tests are evidence of what currently exists. `docs/progress.md` records the live checkpoint.

When implementation and canonical documentation disagree:
1. report the drift;
2. use code/tests as evidence of current behavior;
3. use the canonical owner above for intended behavior;
4. fix the inconsistency instead of adding another policy copy.

Do not treat stale milestone text as newer than current code, tests, `docs/progress.md`, or a current explicit user decision.

## Conflict resolution

When repository files disagree:
1. use the canonical owner listed above for that subject;
2. inspect current code/tests when the disagreement concerns implementation state;
3. update the stale/non-owning file to point to the owner instead of duplicating policy.

## Session bootstrap

For normal ChatGPT-led work:
1. read `AGENTS.md`;
2. read `docs/progress.md`;
3. read only the task-relevant canonical documents;
4. inspect relevant Git/code/tests/CI evidence.

Read `docs/codex_instructions.md` only when delegating execution to Codex or answering about Codex behavior.

Do not preload the whole repository or all of `docs/`.
