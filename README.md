# Gym Checklist

Minimalist iOS workout checklist app.

Core product flow:

> Open app → see today's workout → mark completed sets → close app.

The project is intentionally optimized for very low interaction overhead during a gym session. Product and engineering decisions are documented under `docs/`.

## Development workflow

- ChatGPT project chat is the primary decision-maker and orchestrator.
- ChatGPT uses direct tools and the approved bridge before delegating execution.
- Codex is fallback execution only for tasks ChatGPT cannot reliably perform with available tools, or when explicitly requested.
- One local checkout only: `D:\Projects\gym_checklist`.
- Do not use Git worktrees or sibling task/phase repository folders.
- `main` is stable/release.
- `dev` is normal integration.
- Focused task branches are allowed, but they use the same checkout.
- Pull requests normally target `dev`.
- `dev -> main` requires explicit user approval.
- Pull requests are never auto-merged.

Start with `AGENTS.md`. Canonical document ownership is in `docs/source_of_truth.md`. ChatGPT/bridge policy is in `CHATGPT_PROJECT_SOURCE.md`. Codex fallback rules are in `docs/codex_instructions.md`.

## Phase 5B prototype review

Open `design/prototype/index.html` directly in a browser. Use **Review gallery** to show every deterministic state in fixed iPhone-sized frames, then use Light/Dark to inspect both themes. In normal mode, Today sets support one-tap completion and press-and-hold planned/actual editing; keyboard users can use Shift+F10 on a focused set for the same editor.

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

See `docs/progress.md` for the exact current checkpoint, verification evidence, blockers, and next action.
