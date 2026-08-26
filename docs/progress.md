# Gym Checklist — Progress Checkpoint

## Current state
- Branch: `dev`
- Latest remote checkpoint before orchestration cleanup: `a366005` (`Update verification checkpoint`)
- Latest app-code checkpoint: `3c0af4c` (`Harden workout completion invariants`)
- Autonomous development remains active.

## Implemented product surface
The approved MVP implementation is broadly present across:
- Program planning, date/week navigation, arbitrary sets, copy/repeat, edit/delete, custom exercises;
- Today one-tap complete/undo, long-press edit, skip/restore, rest/empty states, completion popup;
- Firebase owner-scoped persistence and offline-oriented repositories;
- email/password auth, password reset, Google Sign-In code, Sign in with Apple code;
- appearance, kg/lb, Settings/Account, Program history and historical actual editing;
- privacy-safe Analytics, Crashlytics integration, accessibility hardening, offline/error/loading states;
- account deletion client/backend path and provider-bound reauthentication logic;
- broad deterministic unit/UI regression coverage.

`3c0af4c` additionally:
- hardens set persistence against malformed incomplete actual/completion data;
- prevents a workout-completion popup/event while an active exercise has zero sets.

Exact task bodies and acceptance criteria remain in `docs/implementation_plan.md`. Actual Git/code/tests plus this file define runtime state.

## Current CI evidence
- macOS build for the Google Sign-In correction passed.
- macOS unit tests for checkpoint `3495b93` passed in run `32960219106`.
- focused UI run `32983365190` for `3495b93` ended `cancelled` after the workflow's old 20-minute job timeout; it provides no UI pass/fail evidence.
- later app checkpoint `3c0af4c` therefore still needs authoritative current-head verification.

The CI workflow is being simplified so normal verification uses one `full` macOS run at a coherent checkpoint. Narrow `build`/`unit`/`ui` scopes are diagnostic tools after a failure, not a multi-stop foreground ladder.

## External development state
Known from user-confirmed setup:
- Firebase development project exists.
- Google provider is enabled in Firebase.
- the user has already downloaded/refreshed the local `GoogleService-Info.plist`; it must remain untracked and must never be printed or committed.

Still requiring later live/non-production evidence:
- Google sign-in/cancel/failure on a signed device;
- deployed Firestore rules/two-user owner-isolation proof where still outstanding;
- offline cache/reconnect behavior on a real configured environment;
- Crashlytics console proof;
- manual VoiceOver/accessibility review;
- account-deletion backend deployment/emulator or non-production proof;
- physical-iPhone validation.

These are acceptance/live-evidence items, not reasons to block unrelated repository work.

## Explicitly deferred release track
User decision on 2026-08-26: do **not** pay for Apple Developer Program yet. First finish the app and validate that it is useful/alive on the user's own iPhone.

Until the user explicitly reactivates release work, the following are deferred and are not current blockers/runnable backlog:
- paid Apple Developer membership;
- App Store Connect;
- TestFlight;
- distribution signing/profiles and GitHub release secrets;
- final App Store icon decision;
- live Sign in with Apple release configuration that depends on the paid Apple path;
- App Store submission/release PR work that depends on the items above.

Release reference documents may remain in the repository for later use; do not treat them as startup context or current work.

## Next action
1. Pull/reconcile the orchestration-policy cleanup checkpoint.
2. Dispatch one authoritative macOS `full` run for the latest coherent `dev` checkpoint.
3. While that run is active, continue any independent safe repository work discovered by the full active-backlog scan.
4. If no independent work exists, remain in the Codex task and use the low-frequency CI waiting rule in `AGENTS.md`; do not end merely because CI is running.
5. If `full` passes, reconcile M5–M7/current MVP acceptance evidence and continue any remaining safe fixes/reviews.
6. If `full` fails, diagnose only the failing surface with narrow `build`/`unit`/`ui` verification as useful, fix it, then return to `full`.
7. Stop only when `AGENTS.md` permits a genuine terminal condition or the platform/model/tool itself prevents continuation.
