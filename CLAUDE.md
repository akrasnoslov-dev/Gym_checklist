@AGENTS.md

# Claude Code notes

Everything in `AGENTS.md` applies (single checkout, no worktrees, no auto-merge, `dev -> main` only with explicit user approval, update the canonical doc owner instead of adding new policy files).

## Project at a glance

- Native SwiftUI iOS app, Firebase (Auth, Firestore with offline cache, Functions, Analytics, Crashlytics), Google/Apple sign-in.
- `GymChecklist/App` — root (`ContentView`, `WorkoutViewModel`), `Core` — domain models/rules/theme, `Data/Firebase` — Firestore repositories + mapping + pending-write journal, `Data/Local` — in-memory repos (tests/demo) and exercise catalog, `Features/*` — Today / Program / Settings / Auth / Exercises screens.
- `firestore.rules` — owner isolation (`users/{uid}/...`). `functions/index.js` — `deleteAccount` callable.
- Tests: `GymChecklistTests` (unit), `GymChecklistUITests` (XCUITest, in-memory repos via `UITESTING=1`).

## Host constraints

- This Windows host has no Xcode: Swift cannot be compiled or tested locally. macOS CI (`.github/workflows/ios-ci.yml`) is the only compile/test evidence. Never claim a Swift change works without a green CI run on the exact SHA.
- Local checks that do run here (PowerShell):
  - `pwsh -File scripts/verify_security_hygiene.ps1`
  - `pwsh -File scripts/verify_firestore_rules.ps1`
  - `pwsh -File scripts/verify_offline_contract.ps1`
  - `pwsh -File scripts/verify_ios_ci_contract.ps1`
  - other `scripts/verify_*.ps1` contracts, plus `git diff --check`
- Physical-iPhone preview IPA: `mvp-acceptance-ipa.yml` (see `docs/codex_instructions.md`, "Fast physical-iPhone preview IPA").

## Where things are tracked

- Live checkpoint: `docs/progress.md`. Product/UX/architecture owners are listed in `docs/source_of_truth.md`.
- Work backlog from the 2026-11-18 audit: Linear team "Gym Checklist".
