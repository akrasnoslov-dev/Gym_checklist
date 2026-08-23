# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 5 — Authentication and account routing.

Earlier implementation checkpoints may remain pending authoritative macOS/live verification under the no-cost CI continuation policy.

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

The included GitHub Actions macOS quota is currently exhausted. Treat this as `CI UNAVAILABLE — FREE QUOTA EXHAUSTED`, not as a code failure. Paid GitHub Actions usage is not approved.

When free capacity returns, run one consolidated authoritative macOS verification against the latest coherent checkpoint, fix any real failures, and reconcile pending CI checkpoints before marking them `DONE`.

## USER ACTION REQUIRED
None for current M5.1 implementation.

Later genuine external checkpoints may still require batched user action for Google authentication configuration, Firebase deployment/validation, Apple Developer/App Store Connect, signing, or release secrets.

## Blockers
No current product or implementation blocker is known.

Authoritative macOS CI and some live Firebase verification remain pending, but these do not block safe M5 implementation under the no-cost CI policy.

## Exact next action
Start `M5.1` email/password registration with the required authentication/privacy reviews.

Preserve the M4 privacy requirement: repository/session teardown and user-scoped UI state clearing must be part of authentication composition, not deferred beyond M5.

For routine checkpoints, rely on Linux CI and deterministic checks. Trigger macOS only at the next meaningful authoritative checkpoint or earlier if a real Xcode-dependent risk makes continuation unsafe.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
