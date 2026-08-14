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

## Default Codex workflow
1. Start from `dev` or a focused `feature/*` branch based on `dev`; never develop directly on `main`.
2. Read `docs/progress.md` and select the first incomplete task whose dependencies are complete.
3. Plan the focused change before editing.
4. Apply required subagents from `agents/routing.toml` when delegation is available; otherwise apply their instructions manually.
5. Implement only the selected task and required supporting changes.
6. Add/update tests.
7. Run the strongest available verification. On Windows, use static checks that are available; authoritative iOS build/test verification runs on GitHub Actions macOS runners.
8. Self-review the full diff for product drift, UX regressions, security/privacy issues, offline behavior, and unnecessary complexity.
9. Update `docs/progress.md` with completed work, verification, blockers, and exact next task.
10. Commit/push and open a PR to `dev` when the environment supports it.
11. If the user says `continue`, resume from `docs/progress.md`; do not restart planning from scratch.

Only stop for a genuine blocker that requires user input, unavailable credentials/signing, external configuration, or exhausted tool/model limits.

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

## Offline rules
- Cached Today must remain usable without network.
- Completion, undo, actual editing, and skip/restore must write locally immediately.
- Sync should recover automatically when connectivity returns.
- No manual Sync button in MVP.
- Network errors should be non-blocking when local data is available.

## Security/privacy
- User cloud data must be owner-scoped.
- Never log passwords, auth tokens, Firebase credentials, private user workout contents unnecessarily, or signing secrets.
- Secrets/config files that contain credentials must not be committed.
- Firestore Security Rules are required before production use.
- Treat auth, account deletion, privacy disclosures, and App Store login requirements as release-critical.

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

## Verification
Preferred macOS verification once an Xcode project exists:

```bash
xcodebuild -project GymChecklist.xcodeproj -scheme GymChecklist -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project GymChecklist.xcodeproj -scheme GymChecklist -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Codex may adjust project/scheme/destination names to actual repository values, but must record the exact commands used in `docs/progress.md`.

## Branching and PR workflow
- `main`: stable/release only.
- `dev`: integration branch.
- `feature/*`: normal implementation branches based on `dev`.
- PRs target `dev` by default.
- `dev -> main` only for an explicit release.
- Do not auto-merge unless explicitly requested.
- Do not delete or overwrite uncommitted user work.

## Documentation discipline
Update documentation when behavior, architecture, setup, configuration, build commands, Firebase contracts, CI, or release process changes.

`docs/progress.md` is the continuity checkpoint for autonomous work. Keep it short, factual, and current.
