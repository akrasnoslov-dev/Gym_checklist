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
