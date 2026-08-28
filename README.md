# Gym Checklist

Minimalist iOS workout checklist app.

Core product flow:

> Open app → see today's workout → mark completed sets → close app.

The project is intentionally optimized for very low interaction overhead during a gym session. Product and engineering decisions are documented under `docs/`.

## Development workflow

- `main` — stable/release branch.
- `dev` — integration branch for normal development.
- `feature/*` — focused implementation branches based on `dev`.
- Normal pull requests target `dev`.
- `dev -> main` is reserved for explicit release work.

Codex must read `AGENTS.md`, `docs/codex_instructions.md`, `docs/product_spec.md`, `docs/ux_spec.md`, `docs/architecture.md`, `docs/implementation_plan.md`, `docs/progress.md`, and `agents/routing.toml` before non-trivial work.

## Planned stack

- Swift
- SwiftUI
- Feature-oriented MVVM
- Firebase Authentication
- Cloud Firestore with offline persistence
- Firebase Analytics
- Firebase Crashlytics
- GitHub Actions on macOS for build/test verification

## Current status

The original MVP feature set is implemented on `dev` and is in pre-payment functional acceptance/hardening.

Current rules:
- fix confirmed product defects and keep the final authoritative macOS CI fully green;
- validate every supported no-cost Firebase path on a non-production Spark project;
- test the exact candidate on the user's physical iPhone before paying for distribution;
- Apple Developer membership, TestFlight/App Store release work, Firebase Blaze/billing, and other paid-only steps remain deferred until explicit user approval.

See `docs/progress.md` for the exact current blocker and next action.
