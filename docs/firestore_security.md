# Firestore security rules

`firestore.rules` is the deployable owner-isolation policy for the current
Firestore schema:

- `users/{uid}/workouts/{yyyy-MM-dd}`
- `users/{uid}/customExercises/{uuid}`
- `users/{uid}/settings/default`

Every allowed operation requires an authenticated user whose Firebase Auth UID
matches the enclosing `{uid}`. Workout/custom-exercise collection queries are
allowed only within that user's own collection. The settings rule permits only
the fixed `default` document (and does not grant settings collection queries).
Unauthenticated and cross-user requests are denied.

## Deploy

Use a non-production Firebase project for local/emulator validation first.
After authenticating the Firebase CLI for the intended project, deploy only
these rules:

```text
firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
```

The project mapping is intentionally not committed because this repository does
not contain Firebase project credentials or a production project identifier.

## Verify

Run the repository contract check on any host with PowerShell:

```text
pwsh -File scripts/verify_firestore_rules.ps1
```

Before production use, run an emulator or non-production-project validation
with two authenticated test users and confirm all of the following:

1. User A can create, read, update, delete, and query only A's workout,
   custom-exercise, and `settings/default` documents.
2. User A cannot read, query, create, update, or delete User B's documents.
3. An unauthenticated client cannot read or write any of those documents.
4. A user cannot access a settings document with an ID other than `default`.

This validation must be recorded in `docs/progress.md` before live Firestore
behavior or release readiness is claimed.
