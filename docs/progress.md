# Gym Checklist — Progress Checkpoint

## Current execution position
Milestone 6 — History and Settings completion is in active implementation/verification while Milestone 5 Google Sign-In remains deferred on external configuration.

This is intentional: a blocked individual task does not block the whole run when independent safe backlog work exists.

## Current branch
`dev`

## Latest remote checkpoint
`8ebe053` — `Complete settings account surface`

Recent checkpoints:
- `7ca1c6f` — `Implement weight unit setting`
- `f9e5fcb` — `Implement appearance setting`
- `cfc8f5f` — `Record M5.4 continuation state`
- `443e62f` — `Document Google sign-in setup blocker`
- `708cf3a` — `Record M5.3 checkpoint`
- `717412a` — `Add password reset flow`
- `5c60a3c` — `Record M5 auth checkpoints`
- `b0b3cac` — `Add email sign-in and logout`
- `de39abf` — `Implement email registration routing`

## Runtime task status
### Verified DONE
- Milestone 0 (`M0.1`–`M0.6`)
- Milestone 1 (`M1.1`–`M1.6`)
- Milestone 2 `M2.1`–`M2.8`

### Implementation complete / pending authoritative verification
- `M2.9`–`M2.11` — `IN PROGRESS (PENDING CI)`
- `M3.1`–`M3.9` — `IN PROGRESS (PENDING CI)`
- `M4.1`–`M4.8` — implementation complete with CI/live/deployment/offline verification still pending as applicable
- `M5.1` email/password registration — `IN PROGRESS (PENDING CI)`
- `M5.2` sign-in/logout/account routing — `IN PROGRESS (PENDING CI)`
- `M5.3` password reset — `IN PROGRESS (PENDING CI)`
- `M6.3` appearance setting — `IN PROGRESS (PENDING CI)`
- `M6.4` kg/lb setting — `IN PROGRESS (PENDING CI)`
- `M6.5` Settings/Account surface — `IN PROGRESS (PENDING CI)`

### Deferred external work
- `M5.4` Google Sign-In — `IN PROGRESS (PENDING EXTERNAL)`

### Not yet complete
- `M5.5` auth loading/error/account isolation hardening — some requirements are already covered by M5.2 work, but the task is not accepted as complete
- `M5.6` auth/security checkpoint
- `M6.1` historical workout view
- `M6.2` historical actual editing
- `M6.6` product-surface checkpoint
- Milestones 7–9

If a status label in `docs/implementation_plan.md` disagrees with this runtime state, actual Git/code plus this file wins for current status. Task bodies and acceptance criteria in the implementation plan remain authoritative.

## Key implemented behavior
### Today / Program
- Program planning, exercise selection, arbitrary sets, copy, repeat, and date navigation are implemented.
- Today supports one-tap complete/undo, compact planned/actual editing, skip/restore, empty/rest states, completion popup, accessibility identifiers, local-date refresh, and stale-date mutation protection.

### Firebase / offline foundation
- Owner-scoped Firestore repositories exist for workouts, custom exercises, and settings.
- User data is scoped by Firebase Auth UID.
- Firestore rules and static security/offline checks exist.
- Live deployed-rules, emulator/two-user, cache/reconnect, and some macOS verification remain pending.

### M5.1–M5.3 auth
- Email/password registration, sign-in, logout, resolving-state routing, password reset, sanitized errors, and cross-account state isolation are implemented.
- Production repositories are created only for the active UID and user-scoped UI/repository state is disposed/replaced on auth transitions.
- Deterministic unit/UI coverage exists; authoritative macOS verification remains pending.

### M6.3 appearance
- System/Light/Dark is stored in user settings and applied at the authenticated app root.
- Settings uses the approved native control and user-scoped settings observation.

### M6.4 weight unit
- Workout weights remain canonically stored in kilograms.
- kg/lb is a display/input preference only.
- Conversion uses one shared boundary; Today/Program display and editors use the selected unit.
- Unit switching does not rewrite workout history.

### M6.5 Settings/Account
- Settings contains the approved MVP surface: Appearance, Weight unit, Account status, and Log out.
- Account summary is privacy-preserving (`Signed in`) and does not expose email or UID.

## CI / verification state
The repository is public and free GitHub-hosted macOS capacity is available.

CI strategy:
- routine checkpoints: Linux static/platform-independent checks;
- authoritative macOS: focused `build`, then `unit`, then `ui` while diagnosing;
- `full` only after lower layers are clean or at a meaningful reconciliation/release checkpoint;
- docs-only changes do not trigger routine CI;
- paid CI is not approved.

Important recent macOS evidence:
- run `32711661052`: all-target `build-for-testing` passed
- run `32712244156`: Today interaction tests passed; later accessibility/test-selector defects were exposed
- run `32713654840`: all-target `build-for-testing` passed after accessibility correction
- run `32714126343`: Today completion/interaction tests passed; remaining failures were stale Program selectors/assertions
- run `32727119669`: reached unit-test target but current Xcode rejected six `await` calls embedded in XCTest autoclosures; correction was implemented
- run `32728030697`: exposed two compile issues (`WorkoutViewModel` argument order and password-reset continuation type); both corrections are included in the current code checkpoint

These are real CI findings, not quota failures. Do not mark affected checkpoints `DONE` until required authoritative verification passes.

## Firebase / external configuration state
The Firebase development project exists.

`GoogleService-Info.plist` and OAuth configuration are intentionally not tracked in Git. Their presence is local-environment-specific and must never be inferred from the repository or printed/committed.

M5.4 still requires the remaining Google Sign-In integration/configuration/live-validation path described in `docs/google_signin_setup.md`.

## USER ACTION REQUIRED QUEUE
Deferred; **not currently a run-level stop** while other safe backlog work exists.

### M5.4 Google Sign-In
When this task is resumed, the local environment may require:
1. enable/configure the Google provider in Firebase/Google Console;
2. provide the refreshed untracked `GoogleService-Info.plist` locally;
3. configure the reversed-client-ID URL scheme;
4. complete/verify the official Google Sign-In SDK integration and Firebase credential exchange;
5. run the required live Google sign-in/cancel/failure validation.

Use `docs/google_signin_setup.md` for exact setup details. Never commit OAuth/Firebase credentials.

Later release work may also require Apple Developer/App Store Connect actions, signing, TestFlight configuration, and GitHub release secrets. Batch those actions when they become the actual blocker.

## Current blockers
- `M5.4` cannot be fully accepted without Google/Firebase external configuration and live verification.
- M4 live/deployed-rules/offline-reconnect verification remains pending.
- M6.3–M6.5 require authoritative macOS verification after the latest compiler corrections.

None of these currently proves that all remaining safe backlog work is blocked.

## Exact next safe action
1. Run/confirm local static checks for the current M6.3–M6.5 checkpoint.
2. Trigger the narrow authoritative macOS `build` scope.
3. If build is clean, run `unit`, then focused `ui`.
4. Batch/fix same-layer failures before rerunning; do not jump to repeated full-suite runs.
5. Reconcile M6.3–M6.5 when required verification passes.
6. Keep M5.4 deferred if external Google setup is still unavailable.
7. Continue the next technically safe backlog work instead of stopping — first inspect remaining M5.5 hardening, then M6.1/M6.2 where their implementation is safe without M5.4 live evidence.

## Stop condition
None currently established.

A final response from Codex is not appropriate merely because M5.4 is externally blocked or because a checkpoint/CI layer completed. Stop only under the run-level terminal rules in `AGENTS.md` and `docs/desktop_continuation_policy.md`.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
