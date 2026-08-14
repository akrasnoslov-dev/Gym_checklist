# Gym Checklist — Autonomous Implementation Plan

This plan is ordered. Codex should normally take the first incomplete task whose dependencies are complete and continue without asking the user between tasks.

Status legend: `TODO`, `IN PROGRESS`, `DONE`, `BLOCKED`.

## Milestone 0 — Repository/bootstrap
- M0.1 `TODO` Create Xcode iOS SwiftUI project named `GymChecklist` with unit/UI test targets.
- M0.2 `TODO` Establish feature-oriented MVVM folder structure from `docs/architecture.md`.
- M0.3 `TODO` Add initial app shell with Today / Program / Settings tabs and placeholder screens.
- M0.4 `TODO` Make macOS GitHub Actions build/test workflow strict for the created project.
- M0.5 `TODO` Add base Swift formatting/lint strategy only if it is low-friction and CI-friendly.

Exit: clean simulator build and basic tests pass in macOS CI.

## Milestone 1 — Domain model and local behavior
- M1.1 `TODO` Implement UserSettings, Exercise, Workout, WorkoutExercise, WorkoutSet models.
- M1.2 `TODO` Implement local calendar date abstraction and timezone/day-boundary tests.
- M1.3 `TODO` Implement set display formatting rules for reps/weight/time and kg/lb.
- M1.4 `TODO` Implement planned/current -> actual completion behavior and undo semantics.
- M1.5 `TODO` Add model/business-rule tests.

Exit: domain logic is test-covered and independent from Firebase UI plumbing.

## Milestone 2 — Exercise catalog and Program editor (local/mock data first)
- M2.1 `TODO` Add bundled exercise catalog with search.
- M2.2 `TODO` Add custom exercise model/repository interface.
- M2.3 `TODO` Build Program week/date navigation.
- M2.4 `TODO` Build create/edit/delete workout flow.
- M2.5 `TODO` Build add/search/custom exercise flow.
- M2.6 `TODO` Build arbitrary set add/edit/delete/reorder behavior.
- M2.7 `TODO` Implement copy workout to another date.
- M2.8 `TODO` Implement simple weekly repeat generation (4 weeks / 8 weeks / until date).

Exit: a workout can be fully planned using local/mock repository data.

## Milestone 3 — Today core UX
- M3.1 `TODO` Implement active Today workout layout: exercise sections + one row per set.
- M3.2 `TODO` Implement one-tap complete/undo without navigation and preserve scroll position.
- M3.3 `TODO` Implement long-press compact set editor.
- M3.4 `TODO` Implement Skip Exercise and restore skipped exercises.
- M3.5 `TODO` Implement no-program and Rest Day states.
- M3.6 `TODO` Implement workout completion detection and motivational popup.
- M3.7 `TODO` Add Today unit/UI tests for critical flows and accessibility identifiers.

Exit: main product flow works end-to-end against local/mock data.

## Milestone 4 — Firebase foundation
- M4.1 `TODO` Add Firebase dependencies/configuration hooks without committing secrets.
- M4.2 `TODO` Implement repository interfaces and Firestore-backed user workout persistence.
- M4.3 `TODO` Implement custom exercise cloud persistence.
- M4.4 `TODO` Implement UserSettings cloud persistence.
- M4.5 `TODO` Verify Firestore offline persistence and optimistic Today writes.
- M4.6 `TODO` Add Firestore Security Rules with owner-only access and tests/emulator validation where practical.

External configuration may be required here. Batch all required Firebase Console user actions into one checkpoint.

Exit: Program and Today use persistent user data and remain functional offline after cache priming.

## Milestone 5 — Authentication
- M5.1 `TODO` Email/password registration.
- M5.2 `TODO` Email/password sign-in/sign-out.
- M5.3 `TODO` Password reset.
- M5.4 `TODO` Google Sign-In.
- M5.5 `TODO` Authentication routing to Today and empty state.
- M5.6 `TODO` Auth error/loading UX and tests.

External Firebase/Google configuration may be required; consolidate instructions.

Exit: authenticated user owns isolated workout data.

## Milestone 6 — History and settings
- M6.1 `TODO` Past week/date navigation displays historical completed/incomplete/skipped data.
- M6.2 `TODO` Allow historical actual editing.
- M6.3 `TODO` Appearance: System / Light / Dark.
- M6.4 `TODO` Weight unit: kg / lb.
- M6.5 `TODO` Account/settings shell and logout.

Exit: all approved MVP product surfaces are functional.

## Milestone 7 — Quality, analytics, privacy
- M7.1 `TODO` Add minimal Firebase Analytics events from architecture spec without logging sensitive workout content.
- M7.2 `TODO` Add Crashlytics.
- M7.3 `TODO` Accessibility pass: VoiceOver labels, non-color-only state, touch targets, Dynamic Type resilience.
- M7.4 `TODO` Offline/error-state pass.
- M7.5 `TODO` Broad architecture/code-quality/security/product-spec review using routed subagents.
- M7.6 `TODO` Expand unit/UI regression coverage for critical scenarios.

Exit: MVP quality gate passes CI and agent review.

## Milestone 8 — TestFlight readiness
- M8.1 `TODO` Verify current App Store login requirements; add Sign in with Apple if required before public submission.
- M8.2 `TODO` Define bundle identifier, version/build numbering, app icon/metadata placeholders.
- M8.3 `TODO` Configure Apple Developer signing/provisioning (USER ACTION REQUIRED).
- M8.4 `TODO` Configure GitHub secrets for signing/App Store Connect API (USER ACTION REQUIRED).
- M8.5 `TODO` Add automated archive/export/TestFlight upload workflow.
- M8.6 `TODO` Produce first internal TestFlight build and document install/update workflow for the user's iPhone.

Exit: user can install current beta from TestFlight without App Store publication.

## Milestone 9 — MVP acceptance
- M9.1 `TODO` Run full acceptance checklist from `docs/product_spec.md`.
- M9.2 `TODO` Fix blockers/regressions.
- M9.3 `TODO` Produce release notes and known limitations.
- M9.4 `TODO` Prepare `dev -> main` release PR only when user explicitly approves.

## Future candidates — do not implement automatically
- Exercise media/instructions.
- Rest timer.
- Progress/PR analytics.
- Apple Watch / HealthKit.
- AI recommendations/coaching.
- Social/sharing.
- Subscription/payments.
