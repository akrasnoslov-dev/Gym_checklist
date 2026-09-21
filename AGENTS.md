# Agent Instructions

## Product Boundary
- Native SwiftUI iOS app. Core loop: `Open app -> Today -> one tap per completed set -> close app`.
- Today stays frictionless: no unapproved dashboards, stats, timers, coaching, social, calories, PRs, recommendations, or exercise media.
- MVP rules: Today / Program / Settings; Today first after auth; tap toggles set completion; any order; long-press edits sets; skip/restore stays available; one workout per local date; copy/repeat creates independent workouts; history in Program; offline execution; kg/lb; system/light/dark; completion overlay only after full workout.
- English MVP only. Freeze scope; no opportunistic refactors or feature work.

## Start Here
- Read: `docs/progress.md`, relevant `docs/implementation_plan.md`, `docs/product_spec.md`, `docs/ux_spec.md`, `docs/architecture.md`, `agents/routing.toml`.
- For UI/UX or design-prototype work also read `docs/ui_redesign_plan.md`, `docs/ui_research_phase4.md`, and `docs/ui_ux_design_rules.md`.
- Until Phase 5 design approval/freeze, UI redesign stays in deterministic HTML/CSS prototype/docs; do not change production SwiftUI, tests, CI, Firebase, or product behavior.
- Do not preload all `docs/`; open setup, Firebase, security, offline, acceptance, or release docs only when needed.
- Then inspect Git/worktree, recent diffs, relevant source/tests, and CI. `docs/progress.md` plus actual code/tests outrank stale plan history.
- Source priority: current user request, product spec, UX spec, architecture, implementation plan, then runtime state.

## Current Acceptance Boundary
- Pre-payment functional MVP. Use zero-cost paths only; do not attach billing, upgrade Firebase to Blaze, buy Apple membership, activate paid services, or merge `dev` to `main` without explicit approval.
- Runnable: fix MVP defects; verify Spark auth (email/password, Google), Firestore persistence/owner isolation, offline cache/reconnect, Analytics, Crashlytics, accessibility, and physical-iPhone acceptance.
- Deferred: App Store/TestFlight, paid signing/release automation, distribution metadata, paid Sign in with Apple, billing-required Firebase deployment, and `dev -> main`.
- Real architecture and free live services required; `MVP_DEMO`/in-memory preview is not acceptance.

## External Handoff
- Before stopping for user/external access, finish all runnable implementation, tests, static checks, scripts, docs, and diagnostics.
- Batch Firebase, Xcode/signing, device, accessibility, and live-service prerequisites into one handoff with exact actions, paths, commands, evidence, and minimum interactions.

## CI Gate
- Linux CI is routine. macOS/Xcode is authoritative and intentionally not push-triggered.
- Production/test/project changes require Pass A: locally exhaust implementation, review, regression tests, static/security/offline checks, docs, then commit/push and record `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>` in `docs/progress.md`; do not dispatch macOS in same task.
- Separate Pass B audits exact SHA. Only a clean audit with no code changes may record `REMOTE_GATE_APPROVED <SHA>` and dispatch one justified candidate/full run. Any code change or red run revokes approval and restarts Pass A.
- Do not use macOS as routine compiler oracle, poll CI, or dispatch redundant runs. Candidate is for implementation-complete acceptance; never hand off red final verification.
- UI flake budget: at most two focused reruns absent product evidence; then record `KNOWN_UI_TEST_HARNESS_FLAKE` and continue. Never change production only to satisfy XCTest discovery.

## Engineering Rules
- Use Swift/SwiftUI feature MVVM, repository/service boundaries, Firebase Auth/Firestore/Analytics/Crashlytics, and bundled system catalog.
- Cloud data owner-scoped. Never log or commit passwords, tokens, signing secrets, service-account material, `GoogleService-Info.plist`, or unnecessary private workout content. Never weaken security for tests.
- Preserve coherent user work; never reset, overwrite, or discard uncommitted changes. Keep edits minimal, add focused tests, and update `docs/progress.md` at meaningful checkpoints.

## Branching
- `main`: stable/release. `dev`: integration/default. `feature/*`: optional. PRs target `dev`.
- No auto-merge or `dev -> main` without explicit instruction.
