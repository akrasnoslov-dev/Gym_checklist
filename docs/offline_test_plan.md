# Offline and reconnect verification plan

This plan verifies the approved Firestore-cache path after M5 authenticates and
composes the Firestore repositories. It does not add a custom sync engine or a
manual Sync control.

The explicit availability banner covers workout snapshot availability because
Today execution is the protected offline path. Workout, settings,
custom-exercise, and body-weight writes remain optimistic while Firestore marks
them pending. A permanently rejected current mutation restores the last
confirmed document value and presents a retry that retains the attempted value.

## Preconditions

1. Use a non-production Firebase **Spark** project with billing disabled and `firestore.rules` deployed.
2. Sign in as a dedicated test user and create a Today workout containing at
   least two exercises and multiple sets.
3. Keep the app open until Firestore's local cache has received the workout;
   then force-quit and relaunch once while online to confirm cached startup.
4. Capture the workout date, exercise IDs, set IDs, and planned values before
   going offline.

## Auth-session boundary

Firebase Auth restores only its own cached authenticated session. Until that
session resolves, the app shows no user-scoped workout content. If no valid
cached session is available offline, show the sign-in screen; never infer an
authenticated user from cached Firestore data. On sign-out or a UID change,
dispose the prior user-scoped repository/view-model state before showing the
next user's Today content.

## Airplane-mode flow

1. Disable both Wi-Fi and cellular networking.
2. Relaunch the app. Confirm cached Today opens for the concrete local date
   with no Start Workout or manual Sync action.
3. Complete one set, undo it, then complete it again. Confirm each change is
   immediate and does not navigate away.
4. Long-press a completed set and edit its actual values. Confirm the actual
   values remain visible after relaunching while still offline.
5. Skip a different exercise, relaunch while offline, then restore it.
   Confirm skipped/restore state and set ordering are retained.
6. In Program, edit a cached incomplete set and add/remove a cached set.
   Confirm the Today representation updates from the local snapshot.

Expected result: all changes apply against the local Firestore cache without a
blocking network error. Any retry feedback must be neutral and must not prevent
continued workout interaction when cached data exists.

## First-load and unavailable states

1. Launch online with a signed-in test user before their first workout snapshot
   arrives. Confirm Today and Program show only their compact loading state, not
   an empty-program or rest-day conclusion.
2. With no usable cached workout snapshot, disable networking before launch.
   Confirm both screens say the workout is unavailable and that they retry
   automatically; neither screen must expose Firebase/provider error text or a
   manual Sync action.
3. After cache priming, induce a listener failure. Confirm cached rows remain
   usable and the availability message is visible. Set completion, actual
   editing, skip/restore, and Program changes must remain available while
   Firestore reconnects.
4. Reconnect and confirm the availability message clears after a valid snapshot.

## Reconnect and duplicate-safety flow

1. Re-enable connectivity, leave the app foregrounded for a documented waiting
   interval, then force-quit and relaunch online.
2. Confirm the final offline completion,
   actual-value, skip/restore, and Program edits are present exactly once.
3. Compare the stored workout document's exercise/set identifiers to the
   identifiers captured before going offline. Existing sets must retain their
   IDs; no duplicate workout document exists for the same `yyyy-MM-dd` key.
4. After the first session has completed the preceding relaunch check, repeat
   the read-only reconnect check from a second signed-in device/session for the
   same test user. Confirm the converged workout has one document per date, no
   duplicate set rows, and the final actual values from step 2.
5. While the first user is offline, complete a set, force-quit, relaunch still
   offline, and confirm the completion remains visible. Reconnect with the
   original permission and confirm it persists without an error.
6. Repeat the offline/relaunch flow, but before reconnecting deploy a temporary
   non-production rule that denies this test user's write. Reconnect and confirm
   the completion returns to its server state and a concise offline-change
   review banner retains the unconfirmed completed workout. Restore the rule,
   deliberately choose Save Offline Change, and verify the completion persists
   after relaunch. The post-restart mismatch must not be described as a proven
   rejection because a later edit from another device is indistinguishable.
7. Queue changes for two different workout dates, deny the first document and
   allow the second, then reconnect. Confirm the allowed date persists and the
   rejected date restores and reports its own retry. A successful unrelated
   write must not clear or replace that failure.
8. On one workout date, rapidly complete then undo the same set before
   reconnecting. Confirm the final full-document mutation wins; an older
   callback must neither roll back nor report a stale failure.
9. Repeat the permission-denied/retry sequence for appearance or weight unit,
   a custom-exercise create/rename/delete, and a body-weight save/delete.
   Confirm each current rejection restores the confirmed value, preserves the
   attempted value for retry, and never labels the failure as invalid input.
10. Sign out, then sign in as a different test user while offline and after
   reconnect. Confirm the first user's cached workout, custom exercises, and
   settings are cleared before the second user's Today is shown.
11. Sign in as a different test user and confirm none of the first user's
   workout/custom-exercise/settings documents are visible.

Expected result: Firestore automatically drains allowed queued local writes on
reconnect. Rejected writes restore confirmed state and remain retryable; writes
to another document never suppress them. The date-keyed aggregate repository
preserves a single workout per local date, and ordered set IDs prevent duplicate
set creation.

## Required evidence

Record the app build/commit, Firebase project type (never its credentials),
device/simulator OS, the exact timestamps for offline/reconnect transitions,
and pass/fail outcomes in `docs/progress.md`. A real failure blocks dependent
live-data claims until fixed.
