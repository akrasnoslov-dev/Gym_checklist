# Firestore security rules

`firestore.rules` is the deployable owner-isolation policy for the current
Firestore schema:

- `users/{uid}/workouts/{yyyy-MM-dd}`
- `users/{uid}/customExercises/{uuid}`
- `users/{uid}/settings/default`
- `users/{uid}/bodyWeightMeasurements/{uuid}`

Every allowed operation requires an authenticated user whose Firebase Auth UID
matches the enclosing `{uid}`. Workout/custom-exercise collection queries are
allowed only within that user's own collection. The settings rule permits only
the fixed `default` document (and does not grant settings collection queries).
Unauthenticated and cross-user requests are denied.

## Write validation

`create`/`update` additionally validate the resulting document against the
payloads in `GymChecklist/Data/Firebase/FirestoreMapping.swift`
(`keys().hasOnly`, field types, string lengths, array sizes):

| Path | Rules |
| --- | --- |
| `workouts/{workoutDate}` | doc ID matches `^\d{4}-\d{2}-\d{2}$`; keys exactly `workout`, `exercises`; `workout` has exactly `id` (UUID string), `localDate` (== doc ID), `createdAt`/`updatedAt` (timestamps); `exercises` is a list of at most 100 entries |
| `customExercises/{id}` | keys within `id`, `name`, `category`; `id == {id}`; `name` 1–200 chars; `category` absent/null or string up to 100 chars |
| `settings/default` | keys within `appearance`, `weightUnit`, `sex`, `dateOfBirth`, `heightCentimeters`; every key optional (merge writes); enums `system/light/dark`, `kg/lb`, `female/male/preferNotToSay`; profile fields may be explicit `null`; `dateOfBirth` is `yyyy-MM-dd`; height 0–1000 |
| `bodyWeightMeasurements/{id}` | exactly `id`, `localDate`, `weightInKilograms`, `measuredAt`, `updatedAt`; `id == {id}`; `localDate` is `yyyy-MM-dd`; weight in (0, 1000]; timestamps |

Swift `Date` is encoded as a Firestore timestamp; `nil` optionals are omitted
(except settings, which writes explicit nulls). Rules cannot loop over list
elements, so nested exercise/set entries inside a workout are bounded only by
list size; the client decoder discards malformed nested entries.

When a payload in `FirestoreMapping.swift` changes, update `firestore.rules`
and `firestore-tests/rules.test.js` in the same change, or app writes will be
denied.

## Deploy

Use a non-production Firebase **Spark** project with billing disabled for current local/live validation first.
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

Run the emulator tests (Node, Java 21+; also run by the `firestore-rules-tests`
job in `.github/workflows/linux-checks.yml`):

```text
npm ci --prefix firestore-tests
npm test --prefix firestore-tests
```

They cover two users, a valid and invalid payload per path, cross-user and
unauthenticated access. Before production use, also run an emulator or non-production-project validation
with two authenticated test users and confirm all of the following:

1. User A can create, read, update, delete, and query only A's workout,
   custom-exercise, and body-weight measurement documents, plus A's
   `settings/default` document.
2. User A cannot read, query, create, update, or delete User B's documents.
3. An unauthenticated client cannot read or write any of those documents.
4. A user cannot access a settings document with an ID other than `default`.

This validation must be recorded in `docs/progress.md` before live Firestore
behavior or release readiness is claimed.
