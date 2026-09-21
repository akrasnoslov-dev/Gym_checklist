# Gym Checklist

Minimalist iOS workout checklist app.

Core product flow:

> Open app → see today's workout → mark completed sets → close app.

The project is intentionally optimized for very low interaction overhead during a gym session. Product and engineering decisions are documented under `docs/`.

## Development workflow

- `main` — stable/release branch.
- `dev` — integration branch for normal development.
- Non-trivial work uses a focused task branch based on `dev`.
- Normal pull requests target `dev`.
- `dev -> main` is reserved for explicit release work.
- Pull requests are never auto-merged.

Agent/tool bootstrap starts in `AGENTS.md`.
Canonical document ownership is defined in `docs/source_of_truth.md`.
The agent-assisted clarification/spec/test-first/worktree/review workflow is defined in `docs/codex_instructions.md`.
Execution and specialist-review routing lives in `agents/routing.toml`.

## Planned stack

- Swift
- SwiftUI
- Feature-oriented MVVM
- Firebase Authentication
- Cloud Firestore with offline persistence
- Firebase Analytics
- Firebase Crashlytics
- GitHub Actions on macOS for authoritative iOS build/test verification

## Current status

The original MVP feature set is implemented on `dev` and is in pre-payment functional acceptance/hardening.

See `docs/progress.md` for the exact current checkpoint, verification evidence, blockers, and next action.
