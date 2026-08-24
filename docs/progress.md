# Gym Checklist — Progress Checkpoint

## Current execution position
Autonomous implementation is active. The fresh master-prompt start superseded
the prior user-requested pause.

## Current branch
`dev`

## Repository checkpoints
Execution-policy baseline:
- `3854028` — `Make Desktop Codex CI execution work-first`

User pause checkpoint:
- `5eaa082` — `Record user-requested pause`

Latest code checkpoints:
- `8ebe053` — `Complete settings account surface`
- `7ca1c6f` — `Implement weight unit setting`
- `f9e5fcb` — `Implement appearance setting`

Recent auth checkpoints:
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
- `M4.1`–`M4.8` — implementation complete with CI/live/deployment/offline verification pending as applicable
- `M5.1` registration — `IN PROGRESS (PENDING CI)`
- `M5.2` sign-in/logout/account routing — `IN PROGRESS (PENDING CI)`
- `M5.3` password reset — `IN PROGRESS (PENDING CI)`
- `M5.5` auth loading/error/account-isolation hardening — `IN PROGRESS (PENDING CI)`
- `M6.3` appearance — `IN PROGRESS (PENDING CI)`
- `M6.4` kg/lb — `IN PROGRESS (PENDING CI)`
- `M6.5` Settings/Account — `IN PROGRESS (PENDING CI)`

### Deferred external work
- `M5.4` Google Sign-In — `IN PROGRESS (PENDING EXTERNAL)`

### Not yet accepted
- `M5.6` auth/security checkpoint
- `M6.1` historical workout view
- `M6.2` historical actual editing
- `M6.6` product-surface checkpoint
- Milestones 7–9

Actual Git/code plus this file is authoritative for runtime status. Task bodies and acceptance criteria remain in `docs/implementation_plan.md`.

## Key implemented behavior

### Today / Program
- Program planning, exercise selection, arbitrary sets, copy, repeat, and date navigation are implemented.
- Today supports one-tap complete/undo, compact planned/actual editing, skip/restore, empty/rest states, completion popup, accessibility identifiers, local-date refresh, and stale-date mutation protection.

### Firebase / offline foundation
- Owner-scoped Firestore repositories exist for workouts, custom exercises, and settings.
- User data is scoped by Firebase Auth UID.
- Firestore rules and static security/offline checks exist.
- Live deployed-rules, emulator/two-user, cache/reconnect, and some macOS verification remain pending.

### M5.1–M5.5 auth
- Email/password registration, sign-in, logout, resolving-state routing, password reset, sanitized errors, and cross-account state isolation are implemented.
- Production repositories are created only for the active UID and user-scoped state is disposed/replaced on auth transitions.
- Auth feedback clears at session/mode transitions; sign-out clears observable user state without waiting for an auth-listener callback.
- Deterministic unit/UI coverage exists; authoritative macOS verification remains pending.

### M6.3–M6.5 Settings
- System/Light/Dark is stored in user settings and applied at the authenticated app root.
- Workout weights remain canonically stored in kilograms; kg/lb is display/input preference only.
- Settings contains Appearance, Weight unit, privacy-preserving Account status, and Log out.

## CI / verification state

The repository is public and free GitHub-hosted macOS capacity is available.

CI execution rule is defined in `docs/desktop_continuation_policy.md`:
- CI runs asynchronously in the background;
- Codex must not wait/poll while runnable implementation exists;
- `build -> unit -> ui` is dispatch order, not a synchronous waiting sequence;
- `full` is for clean milestone/release reconciliation;
- a result verifies the checkpoint SHA it ran against.

Latest focused UI run:
- run `32729461891`
- checkpoint SHA: `0ea95f5069b700abd0594c6623c24b05c0d87f4c`
- final status: `completed / cancelled`
- the cancelled run provides no new pass/fail evidence and must not be treated as a code failure
- M6.3–M6.5 focused UI verification therefore remains `PENDING CI`

Important earlier macOS evidence:
- `32711661052`: all-target `build-for-testing` passed
- `32712244156`: Today interaction tests passed; later accessibility/test-selector defects were exposed
- `32713654840`: all-target `build-for-testing` passed after accessibility correction
- `32714126343`: Today completion/interaction tests passed; remaining failures were stale Program selectors/assertions
- `32727119669`: reached unit-test target; current Xcode rejected six `await` calls inside XCTest autoclosures; correction implemented
- `32728030697`: exposed two compile issues (`WorkoutViewModel` argument order and password-reset continuation type); both corrections are included in the current code checkpoint

Required acceptance remains pending until authoritative verification passes.

## Firebase / external configuration state

The Firebase development project exists.

`GoogleService-Info.plist` and OAuth configuration are intentionally untracked and local-environment-specific. Never print or commit them.

M5.4 still requires the Google Sign-In integration/configuration/live-validation path described in `docs/google_signin_setup.md`.

## USER ACTION REQUIRED QUEUE

Deferred; **not a technical run-level blocker** while other safe backlog work exists.

### M5.4 Google Sign-In
When resumed, the local environment may require:
1. enable/configure the Google provider in Firebase/Google Console;
2. provide the refreshed untracked `GoogleService-Info.plist`;
3. configure the reversed-client-ID URL scheme;
4. complete/verify official Google Sign-In SDK integration and Firebase credential exchange;
5. run live Google sign-in/cancel/failure validation.

Use `docs/google_signin_setup.md` for exact setup details. Never commit OAuth/Firebase credentials.

Later release work may require Apple Developer/App Store Connect actions, signing, TestFlight configuration, and GitHub release secrets. Batch them when they become the actual blocker.

## Current blockers
- M5.4 cannot be fully accepted without Google/Firebase external configuration and live verification.
- M4 live/deployed-rules/offline-reconnect verification remains pending.
- M6.3–M6.5 require authoritative macOS verification.

None of these establishes a technical run-level stop.

## Next runnable implementation

Do not turn CI back into the foreground task.

1. Do **not** make CI the first foreground task.
2. Continue M6.1 historical viewing and M6.2 historical actual editing where implementation is safe without M5.4/M5.6 live evidence; record provisional dependency scheduling.
3. At a natural checkpoint, dispatch one focused M5.5 unit rerun if no newer relevant macOS verification is queued; record it and immediately return to implementation.
5. At later natural checkpoints only, inspect pending CI once and react:
   - pass -> reconcile only the acceptance the run actually proves;
   - fail -> inspect once, fix narrowly, dispatch one relevant rerun, return to implementation;
   - queued/running -> keep `PENDING CI`, return to implementation.
6. If M5/M6 paths become blocked, scan the entire remaining plan for another independent safe implementation task before considering a final response.

## Future candidates
None approved beyond the explicit backlog in `docs/implementation_plan.md`.
