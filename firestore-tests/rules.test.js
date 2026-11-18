// Firestore rules emulator tests (GYM-9, GYM-22).
//
// Every `client*` payload below is the exact shape the iOS app writes through
// Firestore.Encoder from GymChecklist/Data/Firebase/FirestoreMapping.swift:
// - IDs are Swift `UUID.uuidString` (uppercase);
// - `Date` becomes a Timestamp;
// - nil optionals are omitted by synthesized Codable, except settings, which
//   encode nil profile fields as explicit nulls;
// - every write is a full-document `setData` without merge.
// If the client mapping changes, update these payloads in the same PR.
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, deleteDoc, doc, getDoc, getDocs, collection, setDoc } from 'firebase/firestore';

const UUID_A = '0F8FAD5B-D9CB-469F-A165-70867728950E';
const UUID_B = '7C9E6679-7425-40DE-944B-E07FC1F90AE7';
const UUID_C = 'A3BB189E-8BF9-4888-9912-ACE4E6543002';
const now = Timestamp.fromMillis(1_700_000_000_000);

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gym-checklist',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const anon = () => env.unauthenticatedContext().firestore();

// FirestoreWorkoutPayload: a completed weighted set, an untouched set with nil
// optionals omitted, and a skipped custom-named exercise with a timed set.
const clientWorkout = () => ({
  workout: { id: UUID_A, localDate: '2026-11-18', createdAt: now, updatedAt: now },
  exercises: [
    {
      exercise: { id: UUID_A, exerciseID: UUID_B, order: 0, isSkipped: false },
      sets: [
        { id: UUID_A, order: 0, reps: 10, weight: 60.5, timeSeconds: 0, type: 'weighted', isCompleted: true,
          actualReps: 10, actualWeight: 60.5, actualTimeSeconds: 0, actualType: 'weighted', completedAt: now },
        { id: UUID_B, order: 1, reps: 10, weight: 60, timeSeconds: 0, type: 'weighted', isCompleted: false },
      ],
    },
    {
      exercise: { id: UUID_B, exerciseID: UUID_C, customName: 'Farmer carry', order: 1, isSkipped: true },
      sets: [{ id: UUID_C, order: 0, reps: 0, weight: 0, timeSeconds: 45, type: 'timed', isCompleted: false }],
    },
  ],
});
// FirestoreCustomExerciseDocument with and without the optional category.
const clientExercise = (id = UUID_A) => ({ id, name: 'Bench press', category: 'Chest' });
const clientExerciseWithoutCategory = (id = UUID_A) => ({ id, name: 'Squat' });
// FirestoreUserSettingsDocument: a new user (nil profile) and a full profile.
const clientSettings = () => ({ appearance: 'system', weightUnit: 'kg', sex: null, dateOfBirth: null, heightCentimeters: null });
const clientFullSettings = () => ({
  appearance: 'dark', weightUnit: 'lb', sex: 'preferNotToSay', dateOfBirth: '1990-01-31', heightCentimeters: 180.5,
});
// FirestoreBodyWeightMeasurementDocument, as written by Settings > Body weight.
const clientWeight = (id = UUID_A) => ({ id, localDate: '2026-11-18', weightInKilograms: 80, measuredAt: now, updatedAt: now });

const paths = [
  { name: 'workouts', col: 'workouts', id: '2026-11-18', valid: clientWorkout },
  { name: 'customExercises', col: 'customExercises', id: UUID_A, valid: () => clientExercise() },
  { name: 'settings', col: 'settings', id: 'default', valid: clientSettings },
  { name: 'bodyWeightMeasurements', col: 'bodyWeightMeasurements', id: UUID_A, valid: () => clientWeight() },
];

for (const p of paths) {
  describe(`${p.name}: owner isolation`, () => {
    test('owner can create, read, update, delete the client payload', async () => {
      const ref = doc(alice(), `users/alice/${p.col}/${p.id}`);
      await assertSucceeds(setDoc(ref, p.valid()));
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(setDoc(ref, p.valid()));
      await assertSucceeds(deleteDoc(ref));
    });
    test('other user cannot read or write', async () => {
      await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), `users/alice/${p.col}/${p.id}`), p.valid()));
      const ref = doc(bob(), `users/alice/${p.col}/${p.id}`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, p.valid()));
      await assertFails(deleteDoc(ref));
    });
    test('unauthenticated cannot read or write', async () => {
      const ref = doc(anon(), `users/alice/${p.col}/${p.id}`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, p.valid()));
    });
    test('extra field is rejected', async () => {
      await assertFails(setDoc(doc(alice(), `users/alice/${p.col}/${p.id}`), { ...p.valid(), injected: true }));
    });
  });
}

describe('collection queries', () => {
  test('owner can list own collections, others cannot', async () => {
    for (const col of ['workouts', 'customExercises', 'bodyWeightMeasurements']) {
      await assertSucceeds(getDocs(collection(alice(), `users/alice/${col}`)));
      await assertFails(getDocs(collection(bob(), `users/alice/${col}`)));
      await assertFails(getDocs(collection(anon(), `users/alice/${col}`)));
    }
  });
  test('unknown paths are denied', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice/other/x'), { a: 1 }));
    await assertFails(setDoc(doc(alice(), 'users/alice'), { a: 1 }));
  });
});

describe('workouts validation', () => {
  const ref = (id = '2026-11-18') => doc(alice(), `users/alice/workouts/${id}`);
  test('new empty workout (createEmptyWorkout) is valid', async () => {
    await assertSucceeds(setDoc(ref(), { ...clientWorkout(), exercises: [] }));
  });
  test('document id must be yyyy-MM-dd', async () => {
    const w = clientWorkout(); w.workout.localDate = 'today';
    await assertFails(setDoc(ref('today'), w));
  });
  test('localDate must match document id', async () => {
    await assertFails(setDoc(ref('2026-11-19'), clientWorkout()));
  });
  test('createdAt must be a timestamp', async () => {
    const w = clientWorkout(); w.workout.createdAt = '2026-11-18';
    await assertFails(setDoc(ref(), w));
  });
  test('workout id must be a UUID', async () => {
    const w = clientWorkout(); w.workout.id = 'x'.repeat(36);
    await assertFails(setDoc(ref(), w));
  });
  test('missing exercises is rejected', async () => {
    const w = clientWorkout(); delete w.exercises;
    await assertFails(setDoc(ref(), w));
  });
  test('too many exercises is rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientWorkout(), exercises: Array(201).fill({}) }));
  });
  test('extra workout key is rejected', async () => {
    const w = clientWorkout(); w.workout.userID = 'bob';
    await assertFails(setDoc(ref(), w));
  });
});

describe('customExercises validation', () => {
  const ref = (id = UUID_A) => doc(alice(), `users/alice/customExercises/${id}`);
  test('category may be omitted (nil is skipped by the encoder)', async () => {
    await assertSucceeds(setDoc(ref(), clientExerciseWithoutCategory()));
  });
  test('lowercase UUID ids are accepted too', async () => {
    const id = UUID_A.toLowerCase();
    await assertSucceeds(setDoc(ref(id), clientExercise(id)));
  });
  test('id must equal document id', async () => {
    await assertFails(setDoc(ref(UUID_B), clientExercise(UUID_A)));
  });
  test('empty and overlong names are rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientExercise(), name: '' }));
    await assertFails(setDoc(ref(), { ...clientExercise(), name: 'x'.repeat(1001) }));
  });
  test('non-string category is rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientExercise(), category: 5 }));
  });
});

describe('settings validation', () => {
  const ref = (id = 'default') => doc(alice(), `users/alice/settings/${id}`);
  test('full profile is valid', async () => {
    await assertSucceeds(setDoc(ref(), clientFullSettings()));
  });
  test('clearing the profile with explicit nulls is valid', async () => {
    await assertSucceeds(setDoc(ref(), clientFullSettings()));
    await assertSucceeds(setDoc(ref(), clientSettings()));
  });
  test('partial documents stay writable', async () => {
    await assertSucceeds(setDoc(ref(), { appearance: 'light' }, { merge: true }));
    await assertSucceeds(setDoc(ref(), { weightUnit: 'kg' }, { merge: true }));
  });
  test('unknown enum values are rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientSettings(), appearance: 'neon' }));
    await assertFails(setDoc(ref(), { ...clientSettings(), weightUnit: 'stone' }));
    await assertFails(setDoc(ref(), { ...clientSettings(), sex: 'other' }));
  });
  test('bad dateOfBirth and height are rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientSettings(), dateOfBirth: '31.01.1990' }));
    await assertFails(setDoc(ref(), { ...clientSettings(), heightCentimeters: '180' }));
    await assertFails(setDoc(ref(), { ...clientSettings(), heightCentimeters: 0 }));
    await assertFails(setDoc(ref(), { ...clientSettings(), heightCentimeters: 1000.5 }));
  });
  test('non-default settings document is denied', async () => {
    await assertFails(setDoc(ref('other'), clientSettings()));
    await assertFails(getDoc(ref('other')));
  });
});

describe('bodyWeightMeasurements validation (GYM-22)', () => {
  const ref = (id = UUID_A) => doc(alice(), `users/alice/bodyWeightMeasurements/${id}`);
  test('fractional and boundary weights are valid', async () => {
    await assertSucceeds(setDoc(ref(), { ...clientWeight(), weightInKilograms: 80.2 }));
    await assertSucceeds(setDoc(ref(), { ...clientWeight(), weightInKilograms: 1000 }));
  });
  test('editing a measurement rewrites the same document', async () => {
    await assertSucceeds(setDoc(ref(), clientWeight()));
    await assertSucceeds(setDoc(ref(), { ...clientWeight(), weightInKilograms: 79.5, localDate: '2026-11-17' }));
  });
  test('id must equal document id', async () => {
    await assertFails(setDoc(ref(UUID_B), clientWeight(UUID_A)));
  });
  test('non-positive, too large or non-numeric weight is rejected', async () => {
    await assertFails(setDoc(ref(), { ...clientWeight(), weightInKilograms: 0 }));
    await assertFails(setDoc(ref(), { ...clientWeight(), weightInKilograms: 1000.5 }));
    await assertFails(setDoc(ref(), { ...clientWeight(), weightInKilograms: '80' }));
  });
  test('missing measuredAt, string dates and bad localDate are rejected', async () => {
    const w = clientWeight(); delete w.measuredAt;
    await assertFails(setDoc(ref(), w));
    await assertFails(setDoc(ref(), { ...clientWeight(), updatedAt: '2026-11-18T10:00:00Z' }));
    await assertFails(setDoc(ref(), { ...clientWeight(), localDate: '2026-1-1' }));
  });
});
