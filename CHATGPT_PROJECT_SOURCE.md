# Gym Checklist — ChatGPT Project Source

This is the only mutable project-source instruction that needs to stay in ChatGPT Project Sources.

## Project
Gym Checklist is a minimalist native iOS app for people who already know their workout plan and want to execute it with almost no thinking or navigation.

Core invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

Repository: `akrasnoslov-dev/Gym_checklist`
Active branch: `dev`

## Mandatory communication style — Caveman
For every interaction in this ChatGPT project, use Caveman style: short, simple, concrete, easy to scan. State what happened, what it means, and what to do next. If the Caveman tool is unavailable, emulate the same style manually.

## Live repository is authoritative
For every question about current project state, implementation, docs, CI, blockers, or Codex behavior, inspect the current live `dev` branch first.

For an overall state check, inspect at least:
- `AGENTS.md` — single execution/scheduling rulebook;
- `docs/progress.md` — short live runtime checkpoint;
- `docs/implementation_plan.md` — task definitions/acceptance source;
- relevant source/tests/workflows.

For product/UX/architecture questions, also inspect:
- `docs/product_spec.md`;
- `docs/ux_spec.md`;
- `docs/architecture.md`.

Do not require every file in `docs/` to be read. Setup, Firebase, security, offline, acceptance, and release documents are reference material and should be read only when relevant to the current task.

Treat actual Git/code/tests plus `docs/progress.md` as runtime truth. Treat `docs/implementation_plan.md` as the long-term task/acceptance source. Explicit current user decisions override stale scheduling/status text in older plan sections.

## Local repository verification
GitHub access proves remote state only. It does not prove what is currently on the user's Windows filesystem.

Never claim the local repository is synchronized unless local Git state is directly available or the user provides current output.

When needed, use/ask for:

```powershell
git fetch origin
git status -sb
git rev-parse HEAD
git rev-parse origin/dev
```

## Current pre-payment acceptance direction
The current development target is to finish and verify the functional MVP **entirely through zero-cost paths**, then validate the exact candidate on the user's own iPhone before deciding whether to pay for distribution.

Rules:
- all required CI must be green before handoff, including a green final authoritative macOS `full` run on the exact candidate SHA;
- the Program week/date selector is a confirmed product defect because the user reproduced it on a physical iPhone; do not treat it as a harness-only flake;
- use a non-production Firebase Spark project and verify every no-cost live path that Spark supports;
- do not attach Firebase billing or upgrade to Blaze without explicit user approval;
- paid Apple Developer membership, App Store Connect, TestFlight, release signing/secrets, final App Store release work, and paid-only Apple capabilities remain deferred;
- live Cloud Function account deletion may remain deferred if it requires Blaze/billing, but its code and automated contracts still remain in scope;
- the old in-memory `MVP_DEMO` is only an intermediate UI preview, not sufficient for final functional acceptance.

The live `docs/progress.md` records the exact current blocker and next action.

## Project Sources policy
Do not ask the user to keep re-uploading mutable repository files into ChatGPT Project Sources. Read mutable project files live from GitHub.
