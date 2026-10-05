# Agent Instructions

Gym Checklist is a native SwiftUI iOS app built around one protected loop:

`Open app -> Today -> one tap per completed set -> close app`

## Control plane

The ChatGPT project chat is the primary decision-maker and orchestrator.

- ChatGPT owns requirement interpretation, planning, sequencing, and final acceptance.
- ChatGPT should use its direct repository/local tools and the approved bridge before delegating.
- Codex is a fallback executor only for work ChatGPT cannot reliably execute with available tools, or when the user explicitly requests Codex.
- When Codex is used, it receives a bounded task and reports evidence back to ChatGPT.

Standing ChatGPT/bridge policy lives in `CHATGPT_PROJECT_SOURCE.md`.
Codex fallback rules live in `docs/codex_instructions.md`.

## Before non-trivial work

Read only what is needed:
1. `docs/source_of_truth.md`;
2. `docs/progress.md`;
3. task-relevant canonical product/UX/architecture/backlog/design docs;
4. relevant source/tests/workflows and current Git/CI evidence.

Read `docs/codex_instructions.md` and `agents/routing.toml` when Codex or specialist review agents are actually being used.

Do not preload the whole repository or all of `docs/`.

## Repository discipline

- Primary checkout: `D:\Projects\gym_checklist`.
- Keep one checkout only.
- Do not create `git worktree` checkouts or sibling task/phase folders.
- Use one active branch at a time in the main checkout.
- Preserve coherent user work. Never reset, overwrite, or discard uncommitted changes.
- Do not create per-task `docs/task_specs/` records.
- If a task changes a durable rule, update the canonical owner instead of creating another policy document.
- Use focused validation appropriate to the change. Do not claim completion with a known applicable failing check.
- Do not auto-merge. `dev -> main` requires explicit user approval.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current when graphify is available.
