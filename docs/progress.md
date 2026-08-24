# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 5 — Authentication and account routing.

Earlier implementation checkpoints remain pending authoritative macOS/live verification. Public-repository macOS capacity is available; failure verification now uses build, unit, and UI layers before a consolidated full suite.

## Active task
`M6.4` — kg/lb setting (`IN PROGRESS (PENDING CI)`); M6.3 appearance setting is `IN PROGRESS (PENDING CI)`. M5.4 Google Sign-In remains `IN PROGRESS (PENDING EXTERNAL)` pending local Firebase OAuth configuration; M5.1–M5.3 are implementation-complete and `IN PROGRESS (PENDING CI)`.

## Current branch
`dev`

## Completed and verified
- Milestone 0 (`M0.1`–`M0.6`): `DONE`; authoritative macOS CI passed.
- Milestone 1 (`M1.1`–`M1.6`): `DONE`; authoritative macOS CI passed.
- Milestone 2 `M2.1`–`M2.8`: `DONE`; authoritative macOS CI passed.
- M2.6 CI: PASS for `4c956ac`, run `32503808413`.
- M2.7 CI: PASS for `000f798`, run `32506833516`.
- M2.8 CI: PASS for `ff2377a`, run `32528720383`.

## Implementation-complete work pending authoritative verification
### Milestone 2
- `M2.9` Copy Workout — `IN PROGRESS (PENDING CI)`.
- `M2.10` Repeat Workout — `IN PROGRESS (PENDING CI)`.
- `M2.11` Program UX checkpoint — `IN PROGRESS (PENDING CI)`.

### Milestone 3
`M3.1`–`M3.9` are implementation-complete and remain `IN PROGRESS (PENDING CI)` solely for authoritative macOS verification.

The completed Today flow includes:
- active Today workout layout;
- one-tap complete/undo;
- long-press planned/actual editing;
- skip/restore exercise;
- no-program and rest-day states;
- completion popup;
- accessibility/interaction identifiers;
- current-local-date refresh and stale-date mutation protection;
- neutral mutation failure feedback and snapshot reconciliation.

Required M3.9 reviews passed with no blocking findings from `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`, `code_quality_agent`, and `test_ci_agent`. Simulator lifecycle execution remains pending macOS CI.

M3.9 is additionally `IN PROGRESS (REAL CI FAILURE)`: macOS run `32705517082` identified an unterminated interpolation in `TodayView.swift` and a `set`-accessor parse collision in `TodaySetEditorRoute`. Commit `6592990` corrected both, and commit `a9b326c` corrected the next main-actor observation teardown failure. Commit `45ff91c` then corrected three Firestore workout repository compiler errors. Commit `8c3ff39` corrected a malformed mutation loop; commit `a361099` added Firestore document fixtures and main-actor isolation to local-repository test classes; and commit `7606174` added a missing explicit Today view return. Commit `5800bc6` added the existing `UITESTING=1` Firebase-bootstrap marker to every UI-test app launch, eliminating the launch crashes. [Run 32709225015](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32709225015) then reached the UI suite but could not find `todayScreen` through the Xcode-specific `otherElements` query. Commit `3f0c1ce` replaces all equivalent root queries with an identifier-role-agnostic descendant query. The superseded full rerun `32710615404` was canceled before completion. [Build run 32711661052](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32711661052) passed `build-for-testing` for the app and both test bundles. Focused UI run [32712244156](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32712244156) confirmed the root-query fix and passed all Today interaction tests, then exposed one shared SwiftUI accessibility-grouping defect: state/popup container identifiers replaced their child controls' identifiers. It also exposed a stale end-to-end assertion that assumed a new `WorkoutExercise` reused the catalog exercise UUID and had a placeholder set. Commit `af447d2` preserves child accessibility elements, retains role-agnostic container queries, and asserts the actual empty-set exercise label. [Build run 32713654840](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32713654840) passed all-target `build-for-testing`; next run focused `ui`.

### Milestone 4
- `M4.1` Firebase dependency/configuration bootstrap — implementation-complete, `IN PROGRESS (PENDING CI)`.
- `M4.2` repository protocols and Firestore mapping — implementation-complete, `IN PROGRESS (PENDING CI)`.
- `M4.3` Firestore workout repository — implementation-complete, pending authenticated app composition/live verification/CI.
- `M4.4` Firestore custom exercise persistence — implementation-complete, pending authenticated app composition/live verification/CI.
- `M4.5` Firestore UserSettings persistence — implementation-complete, pending authenticated app composition/live verification/CI.
- `M4.6` offline/reconnect contract — implementation-complete, `IN PROGRESS (PENDING M5/LIVE/CI)`.
- `M4.7` owner-only Firestore rules — implementation-complete, `IN PROGRESS (PENDING DEPLOYMENT/EMULATOR/CI)`.
- `M4.8` Firebase/offline checkpoint — implementation-complete, `IN PROGRESS (PENDING CI/LIVE)`.

M4 uses owner-scoped paths, date-keyed workout aggregates, optimistic/local-first writes, bundled system exercises, user-scoped custom exercises/settings, and owner-only Firestore rules. App-level Firestore repository composition remains intentionally deferred until M5 owns authentication/session lifetime.

M5 must atomically dispose user-scoped repositories/observations and clear user-scoped UI snapshots on every auth transition. This is a required privacy boundary, not optional cleanup.

## Latest M4.8 verification
- `git diff --check`: PASS.
- `scripts/verify_firestore_rules.ps1`: PASS.
- `scripts/verify_offline_contract.ps1`: PASS.
- `scripts/verify_security_hygiene.ps1`: PASS; no tracked Firebase plist or service-account material.
- Required reviews: PASS with no critical/high source finding from `firebase_data_guardian`, `security_privacy_agent`, `architecture_guardian`, and `test_ci_agent`.

Still pending before live/offline claims can be finalized:
- authoritative macOS/Xcode CI;
- deployed-rules two-user and unauthenticated validation;
- Firestore cache/reconnect execution after M5 composes authenticated repositories.

These verification gaps do not block safe M5 implementation under `docs/ci_free_quota_policy.md`.

## Latest M5.1 implementation
- Email/password registration is implemented through an injectable Firebase Auth boundary with email, password, and confirmation validation; raw provider errors are mapped to fixed English messages and credentials remain transient `SecureField` state.
- Successful registration routes directly to the authenticated Today tab state. UI-test auth is deterministic and never registers Firebase accounts; existing Today tests continue with an explicit test session.
- Production workout, custom-exercise, and settings repositories are created only after authentication and are explicitly bound to the UID supplied by the auth session. UID-keyed content replacement releases prior user-scoped view models, snapshots, and listeners before the next UI state is retained.
- New coverage: unit validation/success/sanitized-error tests plus registration UI tests for invalid email, mismatch, and direct Today empty-state routing.
- Local verification: `git diff --check`, `scripts/verify_firestore_rules.ps1`, `scripts/verify_offline_contract.ps1`, and `scripts/verify_security_hygiene.ps1` all PASS. Xcode unit/UI verification remains pending macOS CI.
- Required reviews: `product_spec_guardian` PASS; `security_privacy_agent` PASS after explicit UID binding; `test_ci_agent` PASS after validation coverage additions.

## Latest M5.2 implementation
- Auth root now remains resolving until Firebase reports an initial session, preventing cached workout UI from rendering during session resolution.
- The auth screen supports email/password sign-in and a compact switch back to registration. Sign-in errors remain fixed, English, and credential-nonrevealing.
- Settings exposes Account → Log out. Auth-state callbacks, rather than optimistic routing, remove the active UID-bound content; successful sign-out returns to the auth screen.
- Unit and UI coverage includes sign-in validation/credential failure, sign-in/logout routing, and an A → logout → B test ensuring A's seeded workout does not appear in B's empty Today state.
- Local static verification remains PASS; macOS unit/UI verification is pending.

## Latest M5.3 implementation
- Sign-in exposes a compact Forgot password? flow that submits only a validated email through Firebase Auth’s password-reset API. It stays unauthenticated and gives non-enumerating success feedback.
- Reset errors are fixed English messages; no reset URL, token, or provider detail is displayed or logged. Unit coverage validates input, trims a valid email, and confirms the session is unchanged.

## Latest M6.3 implementation
- Authenticated content now owns one UID-bound `SettingsViewModel`, observes the existing UserSettings repository, applies its System/Light/Dark value at the authenticated app root, and passes it to Settings. The authenticated view is UID-identified, so an auth transition disposes the prior settings observation with the rest of that user-scoped UI state.
- Settings adds only the approved native Appearance segmented control: System, Light, and Dark. Selecting it saves through the repository (including Firestore's local/offline cache path); save failures remain a fixed English message.
- UI-test composition now uses an owner-bound in-memory settings repository instead of bypassing settings behavior.
- Settings mapping accepts missing legacy fields as the documented defaults and writes with Firestore merge semantics, avoiding accidental loss of future settings fields.
- New coverage exercises all appearance mapping values, default migration, view-model save/observation behavior, selection retention, and Today availability after a theme switch.
- Local verification: `git diff --check`, Firestore rules, offline-contract, and security-hygiene checks plus Xcode-scheme XML and merge-marker scans PASS. Required reviews: `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`, `code_quality_agent`, `firebase_data_guardian`, `security_privacy_agent`, and `test_ci_agent` found no high/critical blocker; the settings migration/merge feedback is implemented. Authoritative macOS build, unit, and focused UI verification remain pending.

## Latest M6.4 implementation
- Workout set planned and actual weights retain the established canonical-kilogram storage contract. The kg/lb setting is a user-scoped display/input preference only, so switching it never rewrites workouts, actual results, copies, or history.
- One conversion boundary uses 2.20462262185 lb per kg. Today and Program rows (including accessibility values) render through it; both program-plan and Today planned/actual editors show the selected unit and convert submitted values back to canonical kilograms.
- Settings adds the approved native kg/lb segmented control. Field-specific repository writes preserve a concurrent appearance or unit setting rather than resending a stale full settings object. Existing Firestore optimistic/offline cache behavior remains in use.
- Architecture documents the canonical storage and two-decimal presentation precision. New deterministic unit/UI coverage checks conversion, formatter rules, no-mutation unit switching, settings observation, and Today/Program propagation.
- Required reviews: `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`, `code_quality_agent`, `firebase_data_guardian`, `security_privacy_agent`, and `test_ci_agent` found no high/critical blocker; field-specific settings writes implement the concurrent-field safeguard. Local static verification is PASS; authoritative macOS verification remains pending.

## Firebase/configuration state
The Firebase development project, local plist, production-mode Firestore database, and non-production test account are available. Local Firebase configuration remains untracked and must not be printed or committed.

The full transitive `Package.resolved` lockfile is intentionally not hand-authored on Windows. Xcode’s resolver must generate and commit it when authoritative macOS capacity is available.

## CI state
The repository uses tiered CI permanently:
- `.github/workflows/linux-checks.yml` runs low-cost platform-independent checks on normal code pushes to `dev` and relevant PRs;
- `.github/workflows/ios-ci.yml` remains authoritative for Xcode build/unit/UI tests;
- routine commits must not include `[macos-ci]`;
- macOS CI is reserved for meaningful checkpoints, manual dispatch, release PRs to `main`, or Xcode-dependent risk;
- both workflows use `cancel-in-progress: true`;
- docs-only changes do not trigger automatic CI.

The repository is public as of 2026-08-24 and free GitHub-hosted macOS Actions capacity has been restored. The former `CI UNAVAILABLE — FREE QUOTA EXHAUSTED` state is stale and no longer applies.

Consolidated authoritative verification against `dev` commit `de536f23ac63d68cef5cf4a39cd7dd2c15f3b0c7` ran successfully through checkout, Xcode discovery, Firebase package resolution, and compilation startup, proving capacity is available. [Run 32705517082](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32705517082) failed with Xcode exit 65 on two `TodayView.swift` parser errors; commit `6592990` corrected them. [Replacement run 32705910252](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32705910252) then failed because a `@MainActor` observation called `cancel()` directly from nonisolated `deinit`; commit `a9b326c` corrected all equivalent observation/listener teardown paths. [Run 32706439792](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32706439792) then failed in `FirestoreWorkoutRepository.swift`: it omitted the required workout ID, shadowed `workout(on:)` with its `save` parameter, and left the snapshot decode type ambiguous; commit `45ff91c` corrected all three. [Run 32706761999](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32706761999) then compiled the app and failed in `DomainRulesTests.swift:1579` on a malformed loop over existing stale-date mutation cases; commit `8c3ff39` corrected that loop without changing test intent. [Run 32707131118](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32707131118) then reached the test target and exposed missing fixture initializers for invalid Firestore payloads plus nonisolated local-repository tests; commit `a361099` corrected those. [Run 32707552655](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32707552655) exposed a missing opaque-view return; commit `7606174` corrected it. [Run 32707930264](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32707930264) then reached UI tests, where Firebase bootstrap crashed because the tests had not supplied the existing `UITESTING=1` marker; commit `5800bc6` supplied it. [Run 32709225015](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32709225015) launched successfully but failed all Today UI scenarios at their `otherElements["todayScreen"]` root lookup. Commit `3f0c1ce` changes only that query to a role-agnostic descendant lookup. The superseded full rerun [32710615404](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32710615404) was canceled on 2026-08-24 to avoid unnecessary full-suite cost. The workflow now offers manual `build`, `unit`, `ui`, and `full` verification scopes. [Build run 32711661052](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32711661052) passed `build-for-testing` for the app and both test bundles. [Focused UI run 32712244156](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32712244156) passed all 13 Today interaction tests and confirmed that `todayScreen` is fixed, but failed completion/empty-state tests because SwiftUI collapsed their identifiers onto the only button; it also surfaced one stale Program-to-Today test assumption about generated workout-exercise IDs. Commit `af447d2` corrects that shared grouping and stale assertion, and [build run 32713654840](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32713654840) passed all-target `build-for-testing`. The next narrow verification is focused `ui`; unchanged unit tests are not rerun. These are real code failures, not quota failures, and pending CI work cannot yet be marked `DONE`. Even a green run cannot satisfy M4.3–M4.7 live Firestore, deployed-rules, emulator, or offline-reconnect acceptance checks; those remain separately pending.

Focused UI run [32714126343](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32714126343) passed all completion and interaction tests. Its three remaining failures are stale test selectors: the Program root is queried as `Other`, and an empty-set Program-to-Today smoke assertion assumes a generated workout-exercise ID. The current test-only correction makes the Program root role-agnostic and removes the non-behavioral empty-set assertion. Build, then focused UI verification remain required.

M6.3 build run [32727119669](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32727119669) reached the unit-test target but failed before tests ran: Xcode rejects six `await` calls embedded directly in XCTest autoclosures in pre-existing M5 auth tests. The local checkpoint replaces each with an awaited result variable before the assertion; macOS build/unit/UI verification must be rerun after it is pushed.

## USER ACTION REQUIRED
None for current M5.1 implementation.

Later genuine external checkpoints may still require batched user action for Google authentication configuration, Firebase deployment/validation, Apple Developer/App Store Connect, signing, or release secrets.

## Blockers
`USER_ACTION_REQUIRED` for M5.4 live Google Sign-In: the local workspace has
no `GoogleService-Info.plist` and cannot safely derive the Google OAuth client
or URL scheme. See `docs/google_signin_setup.md` for the required Firebase and
Google Console setup. Do not commit the plist or OAuth credentials.

Focused UI verification for the selector-only correction is active. It has not reported a real failure and does not block safe M5.1 implementation. Some live Firebase verification also remains pending.

## Exact next action
Push the combined M6.3 compiler correction/M6.4 checkpoint, request the
narrow macOS build, unit, and UI verification layers, then reconcile both
settings tasks. M5.4 resumes when the local Google Sign-In configuration is
supplied.

## Stop condition
None while M6.3/M6.4 authoritative verification remains available.

Preserve the M4 privacy requirement: repository/session teardown and user-scoped UI state clearing must be part of authentication composition, not deferred beyond M5.

For routine checkpoints, rely on Linux CI and deterministic checks. Use public-repository macOS CI at meaningful authoritative checkpoints or earlier when a real Xcode-dependent risk makes continuation unsafe.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
