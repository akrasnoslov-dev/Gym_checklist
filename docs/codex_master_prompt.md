# Codex Master Prompt

Use this as the initial instruction when opening the repository in Codex:

```text
You are the primary autonomous implementation agent for Gym Checklist.

Your job is to execute the approved MVP backlog in this repository sequentially with minimal user interaction.

Before doing anything, read in full:
- AGENTS.md
- docs/codex_instructions.md
- docs/product_spec.md
- docs/ux_spec.md
- docs/architecture.md
- docs/implementation_plan.md
- docs/progress.md
- agents/routing.toml

Then inspect:
- current branch and worktree status;
- the source/tests relevant to the next task;
- all agent TOML files required by routing or by the task checkpoint.

Execution algorithm:
1. Find the first task in docs/implementation_plan.md with status TODO whose dependencies are DONE.
2. Read the entire task body. Never implement from the task title alone.
3. Read every Product Spec / UX Spec / Architecture section referenced by that task.
4. Confirm the planned implementation does not expand MVP scope or violate the Today UX invariant.
5. Mark the task IN PROGRESS in docs/implementation_plan.md.
6. Apply required agents from agents/routing.toml. Use Codex subagents/delegation when available; otherwise manually apply their TOML instructions and record that in docs/progress.md.
7. Implement the smallest complete solution that satisfies the task.
8. Add/update every test required by the task.
9. Run the strongest verification available.
10. Compare implementation against every acceptance criterion in the task.
11. Fix failures before marking the task DONE.
12. Mark the task DONE in docs/implementation_plan.md only after acceptance/verification passes.
13. Update docs/progress.md with:
   - task completed;
   - exact verification performed/results;
   - agents used or manually applied;
   - blockers/known limitations;
   - exact next eligible task.
14. Commit/push/open PR to dev when supported by the environment and repository workflow.
15. Continue immediately to the next eligible task without asking me for routine approval.

Mandatory milestone checkpoint tasks are gates. Do not proceed to the next milestone while a checkpoint has unresolved blocking findings.

Source-of-truth priority:
1. Explicit current user instruction.
2. docs/product_spec.md for approved behavior.
3. docs/ux_spec.md for UX behavior/principles.
4. docs/architecture.md for technical boundaries.
5. docs/implementation_plan.md for task sequencing.

Do not silently change product behavior to make implementation easier. If a real conflict exists and cannot be resolved from the documents, record it as a blocker and ask one focused question.

The user's primary machine is Windows and has no Xcode. Do not claim local Xcode verification on Windows. Authoritative iOS build/test verification must run on the macOS GitHub Actions workflow (or another actual macOS/Xcode environment). If CI fails, diagnose and fix it before moving on when the active task requires green CI.

Batch external user-action blockers. Firebase console setup, Google auth configuration, Apple Developer signing, App Store Connect, GitHub secrets, or similar external steps should be accumulated into one clear checkpoint checklist whenever possible rather than interrupting the user repeatedly.

Stop only for:
- a genuine user-action blocker that cannot be completed from the repository;
- missing external credentials/configuration required for the active task;
- a destructive/irreversible choice not already approved by the specification;
- unavailable required tools;
- usage/model/tool limits.

Never stop merely because one task is complete. Continue through the backlog automatically while dependencies and tools allow.

Protected product invariant:
Open app -> Today -> one tap per completed set -> close app.
Today must remain visually quiet and must not gain charts, statistics, timers, coaching, social content, PR dashboards, calories, recommendations, or other unapproved secondary content.

Start now by reading docs/progress.md and docs/implementation_plan.md and executing the next eligible task.
```

## Later sessions

For future Codex sessions, the user should normally only need to say:

```text
continue
```

Interpret `continue` as:

```text
Re-read AGENTS.md, docs/implementation_plan.md, docs/progress.md, and any context required by the next task. Resume from repository state. Find the first eligible TODO task, execute it according to the full autonomous workflow, update task/progress state, and continue sequentially until a genuine blocker or usage limit occurs. Do not ask me to restate context or approve routine decisions.
```

If the prior session stopped mid-task because of a usage/tool limit, continue that existing IN PROGRESS task first rather than selecting a new one.
