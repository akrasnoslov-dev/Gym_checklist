# Gym Checklist — Progress Checkpoint

## Current milestone
Milestone 3 — Today implementation may proceed provisionally while the Milestone 2 checkpoint remains pending authoritative macOS CI.

## Active task
`M4.2` — Define repository protocols and Firestore mapping (`IN PROGRESS`).

M3.9 is implementation-complete and `IN PROGRESS (PENDING CI)` solely for
authoritative macOS verification. M4.1 is implementation-complete except for
authoritative macOS resolution/build verification, and therefore remains
`IN PROGRESS (PENDING CI)` under the no-cost CI continuation policy. It:
- pins the official Firebase Apple SDK at exact version `11.15.0`, compatible
  with the project’s Xcode-16-era configuration;
- links FirebaseCore, FirebaseAuth, and FirebaseFirestore only. Analytics and
  Crashlytics runtime linkage/collection are deferred to M7.1/M7.2;
- validates the local plist before configuration, fails ordinary Debug launches
  with fixed setup guidance, and allows only XCTest/UI-test processes to launch
  config-free;
- keeps all `GoogleService-Info*.plist` variants ignored, documents Firestore
  production-mode setup, and makes macOS CI resolve SwiftPM before tests.

The full transitive `Package.resolved` lockfile is intentionally not
hand-authored on Windows. Xcode’s resolver must generate and commit it before
the CI lockfile-diff check can enforce it. No Firebase console setup or
cloud-data behavior is claimed.

Required M4.1 reviews completed with no blocking findings from
`firebase_data_guardian`, `security_privacy_agent`, and `test_ci_agent`.

M4.2 is implementation-complete and `IN PROGRESS (PENDING CI)` solely for
authoritative macOS verification. It establishes Foundation-only, domain-facing
repository contracts for workouts, custom exercises, and user settings; shared
repository snapshot publication; strict user-scoped Firestore path/mapping DTOs;
and in-memory implementations for the new user-data contracts. Mapping keeps
local dates as canonical `yyyy-MM-dd` path keys and rejects malformed UUIDs,
dates, set values, or completion state. No Firebase types or Firestore queries
reach ViewModels or views, and system exercises cannot be persisted as custom
user data.

Required M4.2 reviews completed with no blocking findings from
`firebase_data_guardian`, `security_privacy_agent`, `architecture_guardian`,
`test_ci_agent`, and `code_quality_agent`. The code-quality review required
main-actor, cancellable multi-observer repository delivery before M4.3; M4.2
now has an actor-isolated observation contract, immediate local snapshots, and
automatic cancellation when a view model releases its observation.

M3.9 is implementation-complete and pending only authoritative macOS CI:
- Today now refreshes its concrete local date on foreground activation and
  significant system time changes. Date changes dismiss date-bound editor,
  popup, and error state; Program selection is intentionally unchanged.
- All Today-only mutations reject a stale date. A failed save refreshes the
  published snapshot before user feedback, including post-write throws, then
  uses neutral manual-retry copy: `Couldn't confirm this change`.
- Debug-only UI-test fixture hooks and focused unit/UI coverage exercise failed
  completion, skip, restore, and editor writes; retry behavior; post-write
  reconciliation; and stale-date rejection.
- Required M3.9 reviews passed with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`, and
  `code_quality_agent`. `test_ci_agent` found the lifecycle notification wiring
  source-reviewed only; the view-model refresh and date-switch safety are
  covered, while simulator lifecycle execution remains pending macOS CI.

M3.9 has started. It will consolidate deterministic local/mock coverage and
the required UX, product, architecture, quality, and test/CI reviews across
the completed Today flow. M3.1–M3.8 remain implementation-complete and
`IN PROGRESS (PENDING CI)` solely for authoritative macOS verification.

The M3.9 review added a direct all-required-sets completion-popup UI test and
made the completion overlay accessibility-modal, hiding the background Today
content from VoiceOver until dismissal. Local source checks pass. Before M3.9
can be finalized, resolve the code-quality finding that Today mutation errors
are silent in release builds and the architecture finding that Today’s local
date does not refresh after the app remains open across midnight.

### M3.8 implementation status

`M3.8` — Add Today accessibility and interaction identifiers (`IN PROGRESS (PENDING CI)`).

M3.8 is implementation-complete and pending only authoritative macOS
verification:
- Today set rows expose stable exercise/set identifiers, clear VoiceOver
  exercise/set/value labels, an explicit Completed/Incomplete value, and a
  selected trait when complete. The checkmark/circle icon and semantic state
  mean completion is not conveyed by color alone.
- VoiceOver Actions expose `Skip exercise` plus contextual `Edit set` or
  `Edit actual`, using the existing skip/editor paths without adding visible
  Today controls or changing the one-tap flow.
- Set rows retain a 48pt minimum target and use multiline, vertically fixed
  text so common accessibility sizes remain usable.
- Focused UI coverage asserts stable identifiers, labels/state, touch-target
  size, completion at Accessibility XXXL, and migration of critical exercise
  lookups away from display-copy-dependent queries.
- Required M3.8 reviews completed without blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent`.

M3.7 remains implementation-complete and `IN PROGRESS (PENDING CI)` solely
for authoritative macOS verification.

M3.7 is implementation-complete and pending only authoritative macOS
verification:
- Today compares completion status before and after a successful set toggle or
  exercise skip, presenting the overlay only for a non-completed → completed
  transition. It therefore does not appear on an already-completed app launch.
- The overlay is a compact, non-navigating Today surface with one small
  checkmark illustration, `Another one done.`, and a single `Done` action.
- Dismissal returns directly to unchanged Today. Undo does not trigger it;
  undo then a fresh completion transition does.
- Unit coverage verifies the transition predicate. Focused UI coverage verifies
  last-set completion, direct skip-to-complete, in-place dismissal, exact copy,
  re-completion behavior, and no popup on a pre-completed launch.
- Required M3.7 reviews completed without blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`,
  `code_quality_agent`, and `test_ci_agent`.

M3.6 remains implementation-complete and `IN PROGRESS (PENDING CI)` solely
for authoritative macOS verification.

M3.6 is implementation-complete and pending only authoritative macOS
verification:
- A pure Today state classifier uses concrete current-date workout presence:
  no workouts is first-use, another-date program data is a rest day, and any
  current-date workout (including empty or fully skipped) remains active.
- First use shows only `No workout planned yet.` with `Create workout`; rest
  day shows only `Rest day.`, `See you tomorrow.`, and `View program`.
- Both CTAs select the concrete current local date and switch to Program,
  without implicitly creating a workout or adding another navigation layer.
- Unit coverage verifies all state classifications. Focused UI coverage
  verifies the exact copy, each CTA, and Program landing at the fixed current
  date with its existing create-workout affordance.
- Required M3.6 reviews completed without blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`,
  `code_quality_agent`, and `test_ci_agent`.

M3.5 remains implementation-complete and `IN PROGRESS (PENDING CI)` solely
for authoritative macOS verification.

M3.5 is implementation-complete and pending only authoritative macOS
verification:
- Today shows a low-prominence `Skipped exercises` footer menu only when one
  or more exercises are skipped; selecting an entry restores it in its retained
  planned order.
- Restore is restricted to the concrete current local date and only clears
  `isSkipped`; set IDs/order, planned values, actual values, completion state,
  and completion timestamps remain unchanged.
- Unit coverage verifies same-day round trip, mixed completed/incomplete set
  preservation, original multi-exercise position, snapshot refresh,
  idempotence, and non-current-date rejection. Focused UI coverage verifies a
  completed set survives skip/restore, remaining work remains usable, and the
  conditional restore menu disappears after the final restore.
- Required M3.5 reviews completed without blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent`.

M3.4 remains implementation-complete and `IN PROGRESS (PENDING CI)` solely
for authoritative macOS verification.

M3.1–M3.3 are implementation-complete and remain `IN PROGRESS (PENDING CI)`
solely for authoritative macOS verification. M3.4 is implementation-complete
under the same policy:
- A secondary exercise-header context menu exposes `Skip exercise`; no set-row
  or permanent Today control was added.
- Skip only persists the exercise `isSkipped` flag. It preserves every set,
  actual value, completion state, and ordering, and active Today immediately
  removes the exercise while remaining work stays executable.
- Unit and focused UI coverage verify persistence, unchanged incomplete sets,
  removal from active Today, and remaining-work availability.
- Same-day restore remains the distinct M3.5 task.

Required M3.4 UX and product-scope reviews found no blocking scope conflict.

M3.1 and M3.2 are implementation-complete and remain `IN PROGRESS (PENDING
CI)` solely for authoritative macOS verification. M3.3 is likewise
implementation-complete under the no-cost CI continuation policy:
- Long-pressing a full Today set row opens a compact sheet without triggering
  the one-tap completion action.
- The editor initializes from displayed values and keeps all draft, validation,
  Save, and Cancel state local to Today.
- Incomplete sets save planned values; completed sets save actual values while
  preserving completion and its timestamp. Validation is atomic and skipped
  exercises remain non-editable from active Today.
- Unit coverage verifies plan/actual routing and invalid-edit non-mutation.
- Focused UI coverage verifies long-press no-toggle, Cancel, plan edit,
  completed actual edit, Save/dismiss, and remaining on Today.

Required M3.3 reviews completed with no blocking findings from
`ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`, and
`test_ci_agent`.

M3.1 is implementation-complete and `IN PROGRESS (PENDING CI)` solely for
authoritative macOS verification. M3.2 is implementation-complete under the
same no-cost CI continuation policy:
- The app owns one `WorkoutViewModel`, observed by Program and Today, so both
  tabs share one published local/mock workout snapshot.
- Every full 48pt set row is a plain button: tap immediately toggles only that
  set, saves locally, refreshes published state, and neither navigates nor
  prompts. Planned exercise/set order is preserved.
- Completion uses the existing actual-value semantics and an injected absolute
  timestamp; undo clears actual values and its completion timestamp.
- Skipped exercises are excluded from active Today and cannot be toggled.
- Deterministic unit coverage checks persistence, actual initialization/undo,
  timestamping, published refresh, and arbitrary cross-exercise order.
- Focused UI coverage checks complete/undo, arbitrary cross-exercise order,
  and a lower-row tap retaining its scroll position.

Required M3.2 reviews completed with no remaining blocking findings:
- `ios_ux_guardian`: full-row interaction, no clutter/navigation, completion
  signal, and scroll behavior are acceptable.
- `product_spec_guardian`: completion preserves planned order; skipped state is
  now protected from active Today interaction.
- `architecture_guardian`: app-owned shared coordinator is explicit at
  `GymChecklist/App/WorkoutViewModel.swift`; no duplicate state or extra layer.
- `test_ci_agent`: required unit/UI coverage is present, including lower-row
  scroll-position coverage.

Implementation is complete against the available local/mock model:
- Today now receives the app-owned workout state and concrete local current date.
- It presents a quiet date header plus vertically scrollable, ordered exercise
  sections and one readable row per set.
- Rows use `SetDisplayFormatter` with the displayed planned/actual values and
  native semantic colors that support system Light/Dark appearance.
- The layout intentionally adds no Start Workout action, secondary metrics, or
  controls reserved for later Today tasks.

Required reviews completed without blocking findings:
- `ios_ux_guardian` and `product_spec_guardian`: layout matches the protected
  Today scope; later completion, editing, skip/restore, popup, and empty states
  remain deferred.
- `architecture_guardian`: the single app-owned `ProgramViewModel` is an
  acceptable temporary source of truth for the layout-only task; introduce a
  focused Today coordinator before adding Today mutation commands in M3.2.
- `test_ci_agent`: coverage and source wiring are appropriate for M3.1, with
  richer multi-section/scroll interaction coverage to follow alongside the
  relevant Today interaction work.

## Verification-deferred state
The user explicitly chose **no paid GitHub Actions usage**. The included GitHub Actions quota is exhausted for the current billing cycle, so GitHub-hosted macOS jobs cannot currently provide authoritative Xcode verification.

`docs/ci_free_quota_policy.md` is active. It allows safe implementation to continue across milestone boundaries when the **only** unsatisfied requirement is macOS CI unavailable because the included quota is exhausted. This does not change acceptance criteria and does not allow unverified tasks/checkpoints to be marked `DONE`.

## Completed and verified
- Milestone 0 (`M0.1`–`M0.6`): `DONE`; authoritative macOS CI passed.
- Milestone 1 (`M1.1`–`M1.6`): `DONE`; authoritative macOS CI passed.
- Milestone 2 `M2.1`–`M2.8`: implementation complete and authoritative macOS CI passed.
- M2.6 CI: PASS for `4c956ac`, run `32503808413`.
- M2.7 CI: PASS for `000f798`, run `32506833516`.
- M2.8 CI: PASS for `ff2377a`, run `32528720383`.

## Milestone 2 pending CI
### M2.9 — Copy Workout
Implementation is complete.
- Plan-only copy with fresh workout/exercise/set identities.
- Completion, actual values, skipped state, and history are reset.
- Source/destination remain independent.
- Occupied destinations are not silently overwritten.
- Deterministic/local checks passed.

The attempted macOS run `32530423499` did not execute workflow steps and produced no job logs. This is treated as CI infrastructure/quota unavailability, not as an observed code/test failure.

### M2.10 — Repeat Workout
Implementation is complete.
- Fixed weekly cadence.
- 4 weeks / 8 weeks / Until date.
- Occupied dates are explicitly skipped.
- Generated workouts are independent plan-only copies with fresh identities.
- Deterministic/local checks and required agent reviews passed.

### M2.11 — Program UX checkpoint
Required Program reviews are provisionally satisfied with no blocking findings. The checkpoint remains `IN PROGRESS (PENDING CI)` because the consolidated authoritative macOS run has not yet been possible.

## Current Program capability
With local/mock persistence, Program currently supports:
- week/date navigation;
- create workout for a concrete date;
- bundled exercise catalog and search;
- custom exercises;
- add/delete/reorder exercises;
- arbitrary set add/edit/delete/reorder with reps/weight/time;
- workout editing/deletion;
- copy workout;
- weekly repeat generation.

## GitHub Actions quota
The current billing/usage report shows Actions usage fully covered by included usage so far (`net_amount = 0`). Paid Actions usage is not approved. Do not ask the user to enable billing merely to continue development.

When included GitHub Actions capacity becomes available again, run one consolidated authoritative macOS build/unit/UI test against the latest coherent checkpoint, fix real failures, and reconcile all affected `PENDING CI` tasks/checkpoints before marking them `DONE`.

The latest attempted macOS run `32599368749` (job `97095229980`) started and
failed before any workflow step ran; GitHub reports no failed-step log. This is
treated as the same quota/infrastructure unavailability, not as an observed
build or test failure.

## Latest M3.1 verification
- `git diff --check`: PASS.
- Deterministic Today source checks: PASS (scrollable layout, displayed-value
  formatter use, semantic system background, no prohibited Today scope).
- UI-test source checks: PASS (Today screen, fixed local date, exercise, set
  row, and no Start Workout assertion).
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification is pending free quota.

## Latest M3.2 verification
- `git diff --check`: PASS.
- Deterministic app/model, interaction/test-source, and Xcode project
  source/group checks: PASS.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.3 verification
- `git diff --check`: PASS.
- Deterministic app/model, interaction/test-source, and Xcode project
  source/group checks: PASS.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.4 verification
- `git diff --check` and deterministic skip implementation/test source checks: PASS.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.5 verification
- `git diff --check`: PASS.
- Deterministic restore implementation and focused unit/UI test-source checks:
  PASS (conditional menu, current-date guard, only-flag mutation, state/order
  preservation, and UI round trip).
- Shared Xcode scheme XML and project references for app/unit/UI targets: PASS.
- Required M3.5 reviews: PASS with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent`.
- Latest GitHub Actions run `32599368749` remains the documented
  quota/infrastructure failure before workflow steps; no new macOS CI run was
  triggered while the included quota is exhausted.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.6 verification
- `git diff --check`: PASS.
- Deterministic empty-state implementation and focused unit/UI test-source
  checks: PASS (date-presence classification, approved copy, current-date
  Program routing, test coverage for both states and exact Program context).
- Shared Xcode scheme XML and project references for app/unit/UI targets: PASS.
- Required M3.6 reviews: PASS with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`,
  `code_quality_agent`, and `test_ci_agent`.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.7 verification
- `git diff --check`: PASS.
- Deterministic completion implementation and focused unit/UI test-source
  checks: PASS (transition-only trigger, skip-aware completion, overlay
  dismissal/copy, direct skip completion, and no pre-completed launch popup).
- Shared Xcode scheme XML and project references for app/unit/UI targets: PASS.
- Required M3.7 reviews: PASS with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`,
  `code_quality_agent`, and `test_ci_agent`.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.8 verification
- `git diff --check`: PASS.
- Deterministic Today accessibility and UI-test source checks: PASS (stable
  IDs, labels, explicit semantic completion state, named VoiceOver actions,
  non-color icon state, 48pt target, and Dynamic Type coverage).
- Shared Xcode project UI-test source reference check: PASS.
- Required M3.8 reviews: PASS with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent`.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M3.9 verification
- `git diff --check`: PASS.
- Deterministic source checks: PASS (project source references, user-visible
  neutral retry feedback, snapshot reconciliation, current-date guards,
  foreground/significant-time refresh wiring, and focused unit/UI test sources).
- Required M3.9 reviews: PASS with no blocking findings from
  `ios_ux_guardian`, `product_spec_guardian`, `architecture_guardian`,
  `code_quality_agent`, and `test_ci_agent`. The test/CI review records only
  that notification-event execution itself is source-reviewed pending a real
  simulator; it found no code defect.
- Xcode/macOS build, unit tests, UI tests: unavailable on the Windows host;
  authoritative GitHub Actions verification remains pending free quota.

## Latest M4.1 verification
- `git diff --check`: PASS.
- Deterministic integration checks: PASS (official Firebase URL, exact 11.15.0
  requirement, Core/Auth/Firestore app linkage, no premature Analytics or
  Crashlytics linkage, config-free XCTest detection, and no tracked Firebase
  configuration/signing material).
- CI workflow source review: PASS (package resolution precedes simulator test
  and uses the same temporary source-package directory).
- Local XML/YAML parser verification is unavailable because no usable Python
  runtime is installed on this Windows host.
- Xcode/macOS dependency resolution, generated `Package.resolved`, build,
  unit tests, and UI tests: pending available free GitHub Actions capacity.

## Latest M4.2 verification
- `git diff --check`: PASS.
- Deterministic repository/mapping source checks: PASS (user-scoped paths,
  canonical date key, explicit completion fields, Foundation-only mapping,
  project source references, cancellable main-actor snapshot contract, and no
  Firebase types outside `Data/Firebase`).
- Focused XCTest source coverage: added mapping round-trip/rejection,
  custom/settings ownership, and local snapshot-publication cases.
- Xcode/macOS build, unit tests, and UI tests: pending available free GitHub
  Actions capacity.

## USER ACTION REQUIRED
None for the current implementation work.

Later genuine external checkpoints may still require batched user action for Firebase configuration, Apple Developer/App Store Connect, signing, or release secrets.

## Blockers
No product or implementation blocker is currently known.

Authoritative macOS CI is temporarily unavailable because the free GitHub Actions quota is exhausted. Under `docs/ci_free_quota_policy.md`, this is a verification deferral rather than a development stop.

## Exact next action
After the required M4.2 code-quality review, checkpoint M4.2 and begin M4.3 —
implement user-scoped Firestore workout persistence with local-first writes and
repository-owned observation. M4.1 and earlier pending checkpoints are
provisionally satisfied for scheduling only under `docs/ci_free_quota_policy.md`;
do not claim their CI passed.

If a task exposes a real dependency that cannot be validated safely without macOS/Xcode, stop at that specific dependency and record it. Do not stop merely because an earlier milestone checkpoint is `PENDING CI` for quota reasons.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
