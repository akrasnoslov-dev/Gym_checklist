# AGENTS.md

## Project
Gym Checklist (`akrasnoslov-dev/Gym_checklist`). Native iOS application for executing pre-planned gym workouts with minimal interaction.

Core product invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

Do not add friction, analytics, coaching, timers, social features, or other scope to the workout flow unless explicitly requested.

## Mandatory context
Before any non-trivial task, read:
- `AGENTS.md`
- `docs/codex_instructions.md`
- `docs/product_spec.md`
- `docs/ux_spec.md`
- `docs/architecture.md`
- `docs/implementation_plan.md`
- `docs/progress.md`
- `agents/routing.toml`

Then inspect relevant source/tests and applicable agent instructions under `agents/*.toml`.

## Autonomous implementation contract
`docs/product_spec.md` is the source of truth for approved product behavior.
`docs/ux_spec.md` is the source of truth for approved UX principles and screen behavior.
`docs/architecture.md` defines the intended technical boundaries.
`docs/implementation_plan.md` is the ordered execution backlog.
`docs/progress.md` is the continuity checkpoint between Codex sessions.

Never implement a task from `docs/implementation_plan.md` using only its title.
For every task:
1. Read the entire task body.
2. Read all referenced sections of `docs/product_spec.md`, `docs/ux_spec.md`, and `docs/architecture.md`.
3. Inspect dependencies and confirm they are `DONE`.
4. Read required agent instructions from `agents/routing.toml`.
5. Mark the task `IN PROGRESS` before implementation.
6. Implement the smallest complete solution that satisfies the task.
7. Add/update the tests required by the task.
8. Run the strongest available verification.
9. Compare the result against every listed acceptance criterion.
10. Fix failures before marking the task `DONE`.
11. Mark the task `DONE` in `docs/implementation_plan.md`.
12. Update `docs/progress.md` with verification, agent reviews, blockers, and exact next task.
13. Continue automatically to the next eligible task unless a genuine blocker exists.

Do not mark a task `DONE` merely because code was written. `DONE` means the acceptance criteria are satisfied and required verification has passed.

Checkpoint/review tasks in `docs/implementation_plan.md` are mandatory gates. Do not proceed past a milestone checkpoint while it has blocking findings.

If implementation behavior conflicts with the Product Spec, do not silently reinterpret the spec. Preserve the approved behavior unless the user explicitly changes it.

## Default Codex workflow
1. Start from `dev` or a focused `feature/*` branch based on `dev`; never develop directly on `main`.
2. Read `docs/progress.md` and `docs/implementation_plan.md` and select the first `TODO` task whose dependencies are `DONE`.
3. Follow the Autonomous implementation contract above.
4. Apply required subagents from `agents/routing.toml` when delegation is available; otherwise apply their instructions manually and record this.
5. Keep changes focused on the active task and strictly necessary supporting changes.
6. Run the strongest available verification. On Windows, use static checks that are available; authoritative iOS build/test verification runs on GitHub Actions macOS runners.
7. Self-review the full diff for product drift, UX regressions, security/privacy issues, offline behavior, and unnecessary complexity.
8. Update task status and `docs/progress.md` after each meaningful completed task.
9. Commit/push and open a PR to `dev` when the environment supports it.
10. Continue sequentially without asking the user to approve routine engineering decisions.
11. If the user says `continue`, resume from repository state; do not restart planning or ask the user to restate context.

Only stop for a genuine blocker that requires user input, unavailable credentials/signing, external configuration, a destructive/irreversible product choice not covered by the specification, unavailable required tools, or exhausted tool/model limits.

When external configuration is required, batch related user actions into one checkpoint instead of interrupting repeatedly.

## Product rules
- Language: English only for MVP.
- Top-level navigation: Today / Program / Settings.
- Today opens first after authentication.
- A set is completed with one tap; tapping again undoes completion.
- No mandatory Start Workout button.
- Sets and exercises can be completed in any order.
- Long press on a set opens compact editing for current/planned or actual values.
- Skip Exercise removes it from the active Today list but keeps it incomplete/skipped in history; restoration must be possible.
- One workout maximum per calendar date.
- Workouts belong to concrete local calendar dates, not abstract weekdays.
- Copy creates an independent workout copy.
- Weekly repeat generates independent future workouts; no complex recurring-template engine in MVP.
- History lives in Program calendar; historical actual results may be edited.
- No historical planned-vs-actual snapshot/analytics model in MVP.
- Offline workout execution is mandatory.
- `kg` and `lb` are supported.
- Light/Dark/System appearance uses one design system.
- Completion motivation appears only after the whole workout is finished, as a dismissible overlay/popup.

## Today UX invariant
Today must remain visually quiet. Do not add charts, statistics, progress dashboards, PRs, calories, timers, recommendations, muscle diagrams, feeds, or other secondary information.

Each set is one readable row, e.g.:
- `8 reps × 60 kg`
- `12 reps`
- `45 sec`

Display rules hide technical zero/placeholder values that do not help the user.

Any proposed Today UI change must answer: does this help the user execute the workout faster, or does it add interaction/noise? If it adds noise without being required for the approved core scenario, do not add it.

## Architecture
Target stack:
- Swift + SwiftUI
- Feature-oriented MVVM
- Repository/service boundaries for persistence/auth
- Firebase Authentication (email/password + Google for MVP; verify Sign in with Apple requirement before App Store release)
- Cloud Firestore
- Firestore offline persistence/cache
- Firebase Analytics
- Firebase Crashlytics
- Local bundled system exercise catalog

Avoid over-engineered Clean Architecture, custom backend services, dependency frameworks, or abstractions that are not justified by current requirements.

## Data rules
Core entities: User/UserSettings, Exercise, Workout, WorkoutExercise, WorkoutSet.
- Workout date is a local calendar date.
- Timestamps are absolute timestamps.
- Before completion, set values represent current planned values.
- On completion, actual values are created from current values.
- Actual values remain editable.
- Program edits affect Today immediately for not-yet-completed sets.
- Do not silently overwrite completed actual values from Program edits.
- Do not introduce a historical planned snapshot model unless the user explicitly changes scope.

## Offline rules
- Cached Today must remain usable without network.
- Completion, undo, actual editing, and skip/restore must write locally immediately.
- Sync should recover automatically when connectivity returns.
- No manual Sync button in MVP.
- Network errors should be non-blocking when local data is available.
- Do not report offline support as complete until the explicit offline acceptance task/checkpoint passes.

## Security/privacy
- User cloud data must be owner-scoped.
- Never log passwords, auth tokens, Firebase credentials, private user workout contents unnecessarily, or signing secrets.
- Secrets/config files that contain credentials must not be committed.
- Firestore Security Rules are required before production use.
- Treat auth, account deletion, privacy disclosures, and App Store login requirements as release-critical.
- Never weaken security rules to make tests pass without explicit review.

## Available agents
Agent instructions live in `agents/*.toml`; routing is defined in `agents/routing.toml`.
- `architecture_guardian`: SwiftUI/MVVM boundaries, data flow, simplicity, offline architecture.
- `ios_ux_guardian`: Today-first UX, iOS interaction conventions, accessibility, visual simplicity.
- `firebase_data_guardian`: Firestore model, offline sync, security rules, data integrity.
- `security_privacy_agent`: auth, secrets, privacy, account and App Store security concerns.
- `code_quality_agent`: Swift maintainability, concurrency, error handling, focused refactors.
- `test_ci_agent`: unit/UI tests, GitHub Actions, xcodebuild confidence.
- `release_appstore_agent`: signing, provisioning, TestFlight, App Store release gates.
- `product_spec_guardian`: prevents scope drift and checks implementation against approved MVP behavior.

## Agent workflow
- Before every non-trivial task, evaluate `agents/routing.toml`.
- Required milestone checkpoint agents must be run/applied before the checkpoint is marked `DONE`.
- Use real Codex subagent/delegation support when available.
- If delegation is unavailable, manually apply the corresponding TOML instructions and record that fact in `docs/progress.md` and PR notes.
- Do not silently skip required agents.
- Any high/critical finding must be fixed before continuing.
- Medium checkpoint findings must be fixed or explicitly documented with rationale if the task permits proceeding.

## Verification
Preferred macOS verification once an Xcode project exists:

```bash
xcodebuild -project GymChecklist.xcodeproj -scheme GymChecklist -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project GymChecklist.xcodeproj -scheme GymChecklist -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Codex may adjust project/scheme/destination names to actual repository values, but must record the exact commands used in `docs/progress.md`.

Verification rules:
- Never claim Xcode build/test passed on Windows unless it actually ran on macOS CI or another macOS environment.
- CI failure blocks completion of tasks whose acceptance criteria require green CI.
- New business rules require unit tests where practical.
- Critical Today flows require UI/regression tests by the relevant milestone checkpoint.
- Bug fixes for critical scenarios require regression tests where feasible.

## Branching and PR workflow
- `main`: stable/release only.
- `dev`: integration/default development branch.
- `feature/*`: normal implementation branches based on `dev`.
- PRs target `dev` by default.
- `dev -> main` only for an explicit release.
- Do not auto-merge unless explicitly requested.
- Do not delete or overwrite uncommitted user work.
- Keep one focused task or tightly coupled task set per feature branch/PR where practical.

## Documentation discipline
Update documentation when behavior, architecture, setup, configuration, build commands, Firebase contracts, CI, or release process changes.

`docs/progress.md` is the continuity checkpoint for autonomous work. Keep it short, factual, and current.

`docs/implementation_plan.md` is a living execution document. Codex must update statuses as work proceeds, but must not rewrite approved acceptance criteria merely to match an implementation shortcut.
