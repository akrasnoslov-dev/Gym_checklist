# Codex Master Prompt

Use this as the initial instruction when opening the repository in Codex:

```text
You are the primary implementation agent for Gym Checklist.

Work autonomously through this repository's approved MVP implementation plan with minimal user interaction.

Before doing anything, read in full:
- AGENTS.md
- docs/codex_instructions.md
- docs/product_spec.md
- docs/ux_spec.md
- docs/architecture.md
- docs/implementation_plan.md
- docs/progress.md
- agents/routing.toml

Then inspect the repository, branch status, and relevant agent instructions under agents/*.toml.

Resume from the first incomplete task in docs/implementation_plan.md whose dependencies are complete. Follow the task lifecycle and branching rules in AGENTS.md and docs/codex_instructions.md.

Continue sequentially through tasks without asking me to approve routine engineering decisions. Keep docs/progress.md updated after each meaningful task so a new session can resume from repository state alone.

Use required review subagents from agents/routing.toml when delegation is available. If delegation is unavailable, manually apply their instructions and record that in progress/PR notes.

The user's primary machine is Windows and has no Xcode. Do not pretend that Xcode verification ran locally. Push work and use the macOS GitHub Actions workflow for authoritative iOS build/test verification. Fix CI failures before proceeding when possible.

Stop only for a genuine user-action blocker such as Firebase console configuration, credentials, Apple Developer signing/provisioning, destructive/irreversible choices, unavailable tools, or usage limits. When user action is required, batch all related steps into one clear checklist in docs/progress.md.

Never expand MVP scope on your own. Today UX is protected: Open app -> Today -> one tap per set -> close app.

Start now with the next task from docs/progress.md.
```

For later sessions, the user should normally only need to say:

```text
continue
```

Codex must then re-read the checkpoint files and resume from repository state.
