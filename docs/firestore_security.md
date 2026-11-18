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
| `workouts/{workoutDate}` | doc ID matches `^\d{4}-\d{2}-\d{2}$`; keys exactly `workout`, `exercises`; `workout` has exactly `id` (UUID), `localDate` (== doc ID), `createdAt`/`updatedAt` (timestamps); `exercises` is a list of at most 200 entries |
| `customExercises/{id}` | keys within `id`, `name`, `category`; `id == {id}` (UUID); `name` 1–1000 chars; `category` absent/null or string up to 1000 chars |
| `settings/default` | keys within `appearance`, `weightUnit`, `sex`, `dateOfBirth`, `heightCentimeters`; the client writes all five, a subset stays valid; enums `system/light/dark`, `kg/lb`, `female/male/preferNotToSay`; profile fields may be explicit `null`; `dateOfBirth` is `yyyy-MM-dd`; height in (0, 1000] |
| `bodyWeightMeasurements/{id}` | exactly `id`, `localDate`, `weightInKilograms`, `measuredAt`, `updatedAt`; `id == {id}` (UUID); `localDate` is `yyyy-MM-dd`; weight in (0, 1000]; timestamps |

UUID means the 8-4-4-4-12 hex form of Swift `UUID.uuidString` (uppercase;
lowercase is accepted too). Swift `Date` is encoded as a Firestore timestamp;
`nil` optionals are omitted (except settings, which writes explicit nulls).
Every client write is a full-document `setData` without merge. Rules cannot
loop over list elements, so nested exercise/set entries inside a workout are
bounded only by list size; the client decoder discards malformed nested entries.

Numeric bounds that the user can type (body weight, height) are mirrored by
`PersistedValueLimits` in the app, so an out-of-range entry fails local
validation instead of an optimistic save that the server later rejects.
String and list caps only bound document size and are far above real use.

When a payload in `FirestoreMapping.swift` changes, update `firestore.rules`
and `firestore-tests/rules.test.js` in the same change, or app writes will be
denied.

## Deploy

The deployed rules must always equal `firestore.rules` on `dev`. In GYM-22 the
Firebase project still ran an older ruleset without the
`bodyWeightMeasurements` match, so every body-weight write was denied while the
repository looked correct. Therefore:

1. Rules are deployed **only from this repository**, never edited in the
   Firebase Console.
2. After any PR that changes `firestore.rules` is merged into `dev`, deploy it
   from the merged `dev` checkout and then run the drift check below. Deploying
   needs explicit user approval each time.
3. Before investigating a "wasn't saved" report, run the drift check first.

Use a non-production Firebase **Spark** project with billing disabled (currently
"GymChecklist Dev"). After `firebase login` for the intended account, deploy
only the rules:

```text
npx firebase-tools@14 deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
```

The project ID is in Firebase Console > Project settings. The project mapping
is intentionally not committed because this repository does not contain
Firebase project credentials or a production project identifier.

### Drift check

```text
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check_deployed_firestore_rules.ps1 -ProjectId YOUR_FIREBASE_PROJECT_ID
```

It reads the released `cloud.firestore` ruleset through the Firebase Rules API
(token from `-AccessToken`, `GOOGLE_OAUTH_ACCESS_TOKEN`, or
`gcloud auth print-access-token`) and prints PASS or the differing lines. It
never deploys. Without a token, compare Firebase Console > Firestore > Rules
with `firestore.rules` by hand. CI does not run it yet because it needs a
service-account secret.

### Diagnosing denied writes

Rejected writes, listener errors and undecodable documents are logged by
`FirestoreDiagnostics` with the collection, document ID and Firestore error code
(for example `permissionDenied`): in the device log (subsystem
`dev.akrasnoslov.GymChecklist`, category `Firestore`) and as Crashlytics
non-fatals grouped as `GymChecklist.Firestore.<operation>.<code>`.

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
