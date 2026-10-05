# Gym Checklist — Codex Fallback Execution Rules

Codex is not the primary orchestrator for this project.

The ChatGPT project chat owns requirements, planning, sequencing, and final acceptance. Use this file only when ChatGPT delegates a bounded task to Codex or when the user explicitly starts a Codex task.

## Authority

For a delegated task, follow this order:
1. the current user instruction;
2. the bounded task from ChatGPT;
3. canonical repository owners in `docs/source_of_truth.md`;
4. current code/tests and `docs/progress.md`.

Do not invent new product scope or permanent workflow rules.

If the delegated task is materially ambiguous and cannot be resolved from repository evidence, report the ambiguity back to ChatGPT instead of expanding scope.

## Single-checkout rule

Primary checkout: `D:\Projects\gym_checklist`.

- Do not create Git worktrees.
- Do not create sibling repository folders for tasks, phases, gates, audits, or workers.
- Do not run parallel implementation workers that require separate checkouts.
- Use the assigned/current branch in the one checkout.
- A focused task branch is allowed when appropriate, but branch switching must happen in the same folder and only when the working tree is safe.
- Never reset, overwrite, or discard coherent user changes.

## No task-spec files

Do not create `docs/task_specs/` or other per-task planning documents.

Use the task prompt as temporary task context.

Update repository docs only when the task changes:
- a durable canonical rule;
- the live checkpoint in `docs/progress.md`;
- long-term backlog/acceptance in `docs/implementation_plan.md`;
- another genuinely durable reference.

## Implementation and verification

Use the smallest complete safe change.

For behavior changes and bug fixes:
1. define focused validation before or with the implementation;
2. prefer a regression test that fails for the old behavior when practical;
3. implement the fix;
4. run focused checks;
5. run the relevant broader repository checks.

For documentation/configuration/workflow changes, use the strongest meaningful contract/lint/configuration validation instead of manufacturing a product test.

No green verification, no completion.

Do not run unrelated expensive checks for ceremony.

## Specialist reviews

Use `agents/routing.toml` when the delegated task requires specialist review.

Specialist reviewers may inspect the same checkout sequentially. Do not spawn parallel editing agents.

Codex may use subagents for bounded read-only analysis when useful, but one agent owns all file edits at a time.

## Git and PR policy

- `main`: stable/release.
- `dev`: normal integration branch.
- PRs normally target `dev`.
- `dev -> main` requires explicit user approval.
- Never auto-merge.
- Do not create extra checkouts to isolate a branch.

## macOS/Xcode remote gate

macOS/Xcode CI remains the authoritative iOS build/simulator gate.

For production Swift, tests, persistence/migration, Xcode project, or other iOS-runtime-relevant changes, keep the existing two-pass conservation rule:

**Pass A**
- finish implementation and local/static hardening;
- commit/push a coherent candidate only when authorized by the task/tool policy;
- record `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>` in `docs/progress.md`;
- do not dispatch the authoritative macOS gate in the same implementation pass.

**Pass B**
- audit the exact recorded SHA in a later fresh pass;
- if code/test/project files change, return to Pass A;
- only a clean audit may record `REMOTE_GATE_APPROVED <SHA>` and dispatch the justified candidate/full run.

A red authoritative run revokes approval.

For docs/process-only work that cannot affect iOS runtime or the gate itself, macOS verification is not required.

## Completion report

Codex completion is evidence, not final project acceptance.

Return to ChatGPT with:
- what changed;
- files/areas changed;
- verification run and result;
- remaining blockers or uncertainty;
- any user/external action actually required.

ChatGPT decides the next action and final acceptance.
