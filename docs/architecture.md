# Gym Checklist — Architecture

## 1. Goals
- Native iOS MVP.
- Fast Today startup and one-tap local responsiveness.
- Offline-first workout execution.
- Simple codebase suitable for AI-assisted development.
- Minimal backend/ops burden.

## 2. Proposed stack
The MVP targets iPhone on iOS 17.0 or later. This baseline is supported by current GitHub Actions macOS/Xcode runners and keeps the bootstrap project focused on modern SwiftUI APIs.

- Swift
- SwiftUI
- Feature-oriented MVVM
- Firebase Authentication
- Cloud Firestore
- Firestore offline persistence
- Firebase Analytics
- Firebase Crashlytics
- GitHub Actions Linux + macOS runners

## 3. Module layout
Recommended source structure once the Xcode project is created:

```text
GymChecklist/
  App/
  Features/
    Auth/
    Today/
    Program/
    Exercises/
    Settings/
  Core/
    Models/
    UI/
    Utilities/
  Data/
    Repositories/
    Firebase/
    Local/
  Services/
```

Tests:

```text
GymChecklistTests/
GymChecklistUITests/
```

## 4. Boundaries
Views render state and emit user intent.
ViewModels coordinate feature state and use repositories/services.
Repositories own persistence/query contracts.
Firebase-specific types should not leak deeply into feature UI code.

Avoid introducing extra layers unless a real testing or separation problem appears.

## 5. Core logical entities
### UserSettings
- userId
- theme: system/light/dark
- weightUnit: kg/lb

### Exercise
- id
- name
- category optional
- isSystem
- createdByUserId optional

### Workout
- id
- userId
- localDate
- status: planned/partial/completed/incomplete

### WorkoutExercise
- id
- workoutId
- exerciseId/customName
- order
- isSkipped

### WorkoutSet
- id
- workoutExerciseId
- order
- reps
- weight
- timeSeconds
- isCompleted
- actualReps optional
- actualWeight optional
- actualTimeSeconds optional
- completedAt optional

## 6. Date handling
Workout identity is based on local calendar date, not UTC day.
Operation timestamps use absolute timestamps.
Date conversion must be isolated and tested around timezone/day-boundary cases.

## 7. Planned/actual behavior
Before completion, base set values are the current plan.
Completing a set initializes actual fields from those values.
Completed actual fields may be edited.
Program edits affect non-completed set values immediately.
Do not preserve an immutable original-plan snapshot for MVP analytics.
Do not silently overwrite completed actual values.

## 8. Offline strategy
Firestore client persistence is the primary offline mechanism for cloud-backed user data.
The app must use optimistic/local writes so Today responds without waiting for network acknowledgement.

System exercise catalog should be bundled with the application for instant offline search.
Custom exercises are user-owned cloud data and should remain locally cached after use.

## 9. Firestore shape
A practical starting point:

```text
users/{userId}/settings/default
users/{userId}/workouts/{yyyy-MM-dd}
users/{userId}/customExercises/{exerciseId}
```

Each workout date document contains its ordered exercise/set aggregate. This
refinement preserves simple per-date reads and Firestore cache behavior without
requiring independent exercise/set writes. Changes must preserve owner
isolation, offline behavior, and the local-date uniqueness invariant.

MVP sync supports a single active editor for a workout date. Concurrent edits
to the same aggregate from multiple devices can be last-write-wins and are not
an approved merge feature; do not claim conflict-free multi-device editing.

## 10. Security
- Firebase Auth UID is the user ownership boundary.
- Firestore rules must enforce owner-only access.
- Do not store raw passwords.
- Do not commit signing materials, service-account keys, or secret configuration.
- Use environment/repository secrets for CI release credentials.

## 11. Authentication
MVP implementation target:
- email/password
- Google Sign-In
- reset password

Before App Store release, verify current Apple requirements and implement Sign in with Apple if required.

## 12. Analytics
Keep event set intentionally small:
- sign_up
- login
- workout_created
- workout_copied
- workout_repeat_created
- exercise_added
- custom_exercise_created
- set_completed
- set_uncompleted
- set_actual_edited
- exercise_skipped
- workout_completed

Do not log detailed workout content as analytics parameters unless explicitly approved.

## 13. CI
The project uses two CI tiers to preserve the included GitHub Actions quota while keeping macOS/Xcode authoritative for iOS verification.

### Linux checkpoint CI
`.github/workflows/linux-checks.yml` runs on normal code pushes to `dev` and relevant PRs. It provides fast, low-cost platform-independent checks such as repository consistency, conflict-marker detection, Xcode scheme XML validation, whitespace checks, and Linux-compatible Swift package tests when available.

Linux CI is non-authoritative for iOS compilation and simulator behavior.

### macOS authoritative CI
`.github/workflows/ios-ci.yml` runs the real Xcode simulator build/unit/UI test path on `macos-latest`.

A normal push to `dev` does not allocate a macOS runner. macOS CI is reserved for:
- milestone/checkpoint commits explicitly marked `[macos-ci]`;
- manual `workflow_dispatch` runs;
- release-oriented pull requests targeting `main`;
- earlier risk-driven verification when continuing without Xcode evidence would be unsafe.

Both workflows cancel obsolete in-progress runs for the same ref. Docs-only changes are excluded from automatic CI.

Required macOS verification remains mandatory before a checkpoint that explicitly requires it can be marked `DONE`. Quota exhaustion follows `docs/ci_free_quota_policy.md`.

## 14. Distribution
Development stages:
1. CI-only simulator build/tests.
2. Apple Developer account/configuration.
3. Code signing/provisioning setup.
4. TestFlight beta upload from macOS CI or another Apple-supported release path.
5. App Store submission only after explicit release approval.

## 15. Architecture guardrails
Do not add:
- custom server/API without demonstrated need,
- separate sync engine when Firestore behavior is sufficient,
- complex recurrence engine,
- immutable plan-version history,
- reactive/event frameworks beyond what Swift/SwiftUI provides unless justified,
- third-party UI frameworks for basic screens.
