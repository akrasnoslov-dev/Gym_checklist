# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 5 — Authentication and account routing.

Earlier implementation checkpoints remain pending authoritative macOS/live verification. Consolidated CI run `32705517082` reached Xcode but failed at compile time; its fix awaits authoritative re-verification.

## Active task
`M5.1` — Email/password registration (`TODO`).

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

M3.9 is additionally `IN PROGRESS (REAL CI FAILURE)`: macOS run `32705517082` identified an unterminated interpolation in `TodayView.swift` and a `set`-accessor parse collision in `TodaySetEditorRoute`. Commit `6592990` corrected both, and commit `a9b326c` corrected the next main-actor observation teardown failure. Commit `45ff91c` then corrected three Firestore workout repository compiler errors. Commit `8c3ff39` corrected a malformed mutation loop; commit `a361099` added Firestore document fixtures and main-actor isolation to local-repository test classes. The next run then exposed one missing explicit return in a Today view helper; that correction is staged locally and must pass the next macOS run before any dependent CI acceptance can be reconciled.

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

Consolidated authoritative verification against `dev` commit `de536f23ac63d68cef5cf4a39cd7dd2c15f3b0c7` ran successfully through checkout, Xcode discovery, Firebase package resolution, and compilation startup, proving capacity is available. [Run 32705517082](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32705517082) failed with Xcode exit 65 on two `TodayView.swift` parser errors; commit `6592990` corrected them. [Replacement run 32705910252](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32705910252) then failed because a `@MainActor` observation called `cancel()` directly from nonisolated `deinit`; commit `a9b326c` corrected all equivalent observation/listener teardown paths. [Run 32706439792](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32706439792) then failed in `FirestoreWorkoutRepository.swift`: it omitted the required workout ID, shadowed `workout(on:)` with its `save` parameter, and left the snapshot decode type ambiguous; commit `45ff91c` corrected all three. [Run 32706761999](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32706761999) then compiled the app and failed in `DomainRulesTests.swift:1579` on a malformed loop over existing stale-date mutation cases; commit `8c3ff39` corrected that loop without changing test intent. [Run 32707131118](https://github.com/akrasnoslov-dev/Gym_checklist/actions/runs/32707131118) then reached the test target and exposed missing fixture initializers for invalid Firestore payloads plus nonisolated local-repository tests. The current worktree adds only the needed `Codable` fixture initializers and marks the two local-repository test classes `@MainActor`. These are real code failures, not quota failures, and pending CI work cannot yet be marked `DONE`. A corrective commit will trigger the next consolidated macOS build, package resolution, unit-test, and UI-test run. Even a green run cannot satisfy M4.3–M4.7 live Firestore, deployed-rules, emulator, or offline-reconnect acceptance checks; those remain separately pending.

## USER ACTION REQUIRED
None for current M5.1 implementation.

Later genuine external checkpoints may still require batched user action for Google authentication configuration, Firebase deployment/validation, Apple Developer/App Store Connect, signing, or release secrets.

## Blockers
No current product or implementation blocker is known.

MacOS capacity is available, but a real compile failure blocks CI reconciliation until the local correction is verified. Some live Firebase verification also remains pending.

## Exact next action
Commit the Today helper return correction, then rerun consolidated authoritative macOS CI. If it passes, reconcile M2.9–M3.9 and the CI portions of M4.1–M4.8 in order; otherwise fix the reported real failure before starting dependent implementation.

Preserve the M4 privacy requirement: repository/session teardown and user-scoped UI state clearing must be part of authentication composition, not deferred beyond M5.

For routine checkpoints, rely on Linux CI and deterministic checks. Use public-repository macOS CI at meaningful authoritative checkpoints or earlier when a real Xcode-dependent risk makes continuation unsafe.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
