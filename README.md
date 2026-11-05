# Gym Checklist

A native iPhone workout checklist for people who already have a training plan. It focuses on doing the workout, not planning one.

**Core flow:** Open app → Today → tap completed sets → close app.

## What the MVP does

- **Today:** check off or undo individual sets in one tap; edit planned or actual values, skip/restore exercises, see rest days.
- **Program:** manage workouts by date, copy a plan and repeat it across future weeks.
- **Settings:** adjust appearance, kg/lb display and a compact profile/body-weight history.
- **Account and persistence:** Firebase Authentication, owner-scoped Firestore data, offline persistence, Analytics and Crashlytics.

The product deliberately excludes AI coaching, social features, rest timers, nutrition, Android and a statistics dashboard. The intent is to keep gym-session interactions fast.

## Product decisions

- Start on Today after signing in.
- A completed set should require no navigation or confirmation.
- Store a workout for a **date**, not an abstract weekday.
- Preserve locally cached workout data when offline.
- Keep workout ownership under `users/{uid}` and require authenticated access.

See [product specification](docs/product_spec.md), [UX specification](docs/ux_spec.md) and [architecture](docs/architecture.md). The [PM case study](docs/case-study.md) explains the problem, trade-offs and acceptance goals.

## Technology

Swift, SwiftUI, feature-oriented MVVM, Firebase Authentication, Cloud Firestore, Analytics, Crashlytics, and GitHub Actions. The iOS deployment target is **iOS 17+**.

Key paths:

- `GymChecklist/` — app source (App, Features, Core, Data).
- `GymChecklistTests/` and `GymChecklistUITests/` — unit and UI tests.
- `functions/` — the callable account-deletion backend.
- `design/prototype/` — browser-based design prototype and review gallery.
- `docs/` — product, architecture, acceptance and delivery records.

## Run locally

1. On macOS, install Xcode **26.3** (or a compatible newer version) and open `GymChecklist.xcodeproj`.
2. Resolve Swift packages through Xcode and select the `GymChecklist` scheme.
3. For Firebase-backed sign-in and persistence, register your own non-production Firebase app and place a valid `GoogleService-Info.plist` in `GymChecklist/`. **Do not commit this file or any credentials.** See [Firebase setup](docs/firebase_setup.md).
4. Build and run on an iOS 17+ simulator or iPhone. Run the unit/UI tests with Xcode. CI on macOS is the authoritative iOS build check.

The unsigned/demo IPA workflow is a separate validation path and does not prove live Firebase behavior. Account-deletion Cloud Function deployment can require Firebase Blaze; billing, paid Apple distribution, TestFlight and release signing are **not enabled** as part of the free MVP acceptance.

## Project status

Implementation and automated checks do not equal physical-device acceptance. The remaining work includes full CI evidence, real-iPhone visual/gesture checks and live Firebase offline/error-path validation. See the [current checkpoint](docs/progress.md) for exact status. Do not infer release readiness from a green smoke run.

## Development workflow

PRs normally target `dev`; `main` is for stable/release code. No automatic merge. See [contributor/agent rules](AGENTS.md) and [source-of-truth guide](docs/source_of_truth.md).

## License

No open-source license has been selected yet. Until one is added, no permission to copy, modify or redistribute this code is granted by default.
