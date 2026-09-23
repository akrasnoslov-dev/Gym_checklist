# Agent Instructions

Gym Checklist is a native SwiftUI iOS app built around one protected loop:

`Open app -> Today -> one tap per completed set -> close app`

This file is bootstrap only. Permanent project rules live in canonical repository documents.

## Before non-trivial work

Read, in order:
1. `docs/source_of_truth.md`
2. `docs/codex_instructions.md`
3. `agents/routing.toml`
4. `docs/progress.md`
5. only the task-relevant canonical product/UX/architecture/backlog/design documents named by the source-of-truth map

Then inspect Git/worktree state, relevant source/tests, recent diffs, and current CI evidence.

Do not preload the whole repository or all of `docs/`.

## Repository discipline

- The repository is durable memory; chat history and external prompts are task context, not permanent policy owners.
- Preserve coherent user work. Never reset, overwrite, or discard uncommitted changes.
- If a current user decision changes a permanent rule, update its canonical repository owner in the same task.
- Follow the clarification, task-spec, test-first, worktree, model-routing, verification, and PR workflow in `docs/codex_instructions.md`.
- Follow execution/review routing in `agents/routing.toml`.
- Do not auto-merge. `dev -> main` requires explicit user approval.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
