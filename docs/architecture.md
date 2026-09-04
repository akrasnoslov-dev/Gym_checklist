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
- optional profile: sex, local date of birth, canonical centimetres height

### BodyWeightMeasurement
- id, userId, localDate, measuredAt, updatedAt
- canonical kilograms, converted only at the UI boundary
- latest measurement is the current profile weight; BMI is derived locally and never stored

All `WorkoutSet.weight` and `WorkoutSet.actualWeight` values are stored as
canonical kilograms. `weightUnit` is only a user-scoped display/input
preference: conversion occurs at the view/formatter boundary using
2.20462262185 lb per kg, while persisted workout values are never rewritten
when the preference changes. Display and editor text use at most two decimal
places; the stored canonical value retains its full precision.

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
- type: weighted / reps-only / timed. Only relevant execution values are presented; legacy records infer this type safely.

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
users/{userId}/bodyWeightMeasurements/{measurementId}
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

Sign in with Apple is a required release companion to Google Sign-In under the
current App Review decision in `docs/app_store_auth_compliance.md`.

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

Required macOS verification remains mandatory before a checkpoint that explicitly requires it can be marked `DONE`. During current pre-payment acceptance, the final exact candidate SHA must have a green authoritative macOS `full` result; a red final run cannot be waived when the same behavior is observed in the product.

## 14. Current free validation and later distribution

Current pre-payment stages:
1. CI simulator/unit/UI development using free GitHub-hosted capacity.
2. Non-production Firebase **Spark** configuration with billing disabled.
3. Free live validation of email/password auth, Google Sign-In, Firestore persistence/owner isolation, offline/reconnect, Analytics, and Crashlytics where supported.
4. Free personal-device installation/testing on the user's iPhone.
5. User functional/UX acceptance.

Only after explicit user approval:
6. Paid Apple Developer account/configuration.
7. Release signing/provisioning and App Store Connect/TestFlight.
8. Paid/billing-dependent backend work, if still required for release.
9. App Store submission after explicit release approval.

Do not attach Firebase billing, upgrade to Blaze, or activate a paid Apple service during stages 1–5 without explicit user approval.

## 15. Architecture guardrails
Do not add:
- custom server/API without demonstrated need,
- separate sync engine when Firestore behavior is sufficient,
- complex recurrence engine,
- immutable plan-version history,
- reactive/event frameworks beyond what Swift/SwiftUI provides unless justified,
- third-party UI frameworks for basic screens.
