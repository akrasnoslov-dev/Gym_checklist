# Gym Checklist — ChatGPT Project Source

This file is intended to be the only persistent mutable-context instruction kept in the ChatGPT Project Sources for Gym Checklist.

## Project
Gym Checklist is a minimalist native iOS app for people who already know their workout plan and want to execute it with almost no thinking or navigation.

Core invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

The MVP is iOS-only and uses Swift/SwiftUI with Firebase for authentication, persistence, analytics, and crash reporting. Development is performed with Codex inside the ChatGPT desktop app.

## Live repository is authoritative
Repository: `akrasnoslov-dev/Gym_checklist`

Active development branch: `dev`

For every question about current project state, implementation status, source code, documentation, CI, blockers, next actions, or what Codex is doing:

1. Read the current live repository from GitHub first.
2. Use the current `dev` branch unless the user explicitly names another ref.
3. Read the relevant live files instead of relying on copies previously uploaded to ChatGPT Project Sources.
4. For overall project state, always inspect at least:
   - `AGENTS.md`
   - `docs/progress.md`
   - `docs/implementation_plan.md`
   - `docs/codex_instructions.md`
   - `docs/codex_master_prompt.md`
   - `docs/desktop_continuation_policy.md`
   - `docs/ci_free_quota_policy.md`
   - relevant source/tests/workflows for the question
5. For product/UX/architecture questions, also read the current live versions of:
   - `docs/product_spec.md`
   - `docs/ux_spec.md`
   - `docs/architecture.md`
6. Treat Git/code/tests plus `docs/progress.md` as runtime truth. Treat `docs/implementation_plan.md` as the task/acceptance source.
7. Do not claim a Project Source copy is current unless it was actually compared with the live repository.
8. If GitHub cannot be accessed, say that current repository state cannot be verified; do not guess from stale Project Sources.

## Local-repository verification
GitHub access proves remote state only. It does not prove what is currently on the user's Windows filesystem.

Never claim the local repository is synchronized unless local Git state is directly available in the current tool environment or the user provides current command output.

When local-vs-GitHub synchronization must be verified and no direct local-repository access exists, ask for or use these outputs:

```powershell
git status -sb
git rev-parse HEAD
git rev-parse origin/dev
```

A clean synchronized local `dev` should show no ahead/behind divergence and the same SHA for `HEAD` and `origin/dev` after `git fetch origin`.

## ChatGPT Project Sources policy
Do not require the user to keep re-uploading mutable repository documents into Project Sources.

This file alone is sufficient as the persistent project instruction. Optional stable visual/reference material may also be kept in Project Sources if useful.

Mutable files such as `progress.md`, `implementation_plan.md`, `AGENTS.md`, CI policy, Codex prompts/instructions, architecture, UX, and product specs should normally be read live from GitHub.
