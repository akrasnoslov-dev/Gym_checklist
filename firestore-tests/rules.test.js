// Firestore rules emulator tests. Payloads mirror FirestoreMapping.swift.
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, deleteDoc, doc, getDoc, getDocs, collection, setDoc } from 'firebase/firestore';

const UUID_A = '0F8FAD5B-D9CB-469F-A165-70867728950E';
const UUID_B = '7C9E6679-7425-40DE-944B-E07FC1F90AE7';
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

const validWorkout = () => ({
  workout: { id: UUID_A, localDate: '2026-11-18', createdAt: now, updatedAt: now },
  exercises: [{
    exercise: { id: UUID_A, exerciseID: UUID_B, order: 0, isSkipped: false },
    sets: [
      { id: UUID_A, order: 0, reps: 10, weight: 60.5, timeSeconds: 0, type: 'weighted', isCompleted: true,
        actualReps: 10, actualWeight: 60.5, completedAt: now },
      { id: UUID_B, order: 1, reps: 10, weight: 60, timeSeconds: 0, isCompleted: false },
    ],
  }],
});
const validExercise = (id = UUID_A) => ({ id, name: 'Bench press', category: 'Chest' });
const validSettings = () => ({ appearance: 'dark', weightUnit: 'kg', sex: null, dateOfBirth: null, heightCentimeters: null });
const validWeight = (id = UUID_A) => ({ id, localDate: '2026-11-18', weightInKilograms: 80.2, measuredAt: now, updatedAt: now });

const paths = [
  { name: 'workouts', col: 'workouts', id: '2026-11-18', valid: validWorkout },
  { name: 'customExercises', col: 'customExercises', id: UUID_A, valid: () => validExercise() },
  { name: 'settings', col: 'settings', id: 'default', valid: validSettings },
  { name: 'bodyWeightMeasurements', col: 'bodyWeightMeasurements', id: UUID_A, valid: () => validWeight() },
];

for (const p of paths) {
  describe(`${p.name}: owner isolation`, () => {
    test('owner can create, read, update, delete', async () => {
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
});

describe('workouts validation', () => {
  const ref = (id = '2026-11-18') => doc(alice(), `users/alice/workouts/${id}`);
  test('empty exercise list is valid', async () => {
    await assertSucceeds(setDoc(ref(), { ...validWorkout(), exercises: [] }));
  });
  test('document id must be yyyy-MM-dd', async () => {
    const w = validWorkout(); w.workout.localDate = 'today';
    await assertFails(setDoc(ref('today'), w));
  });
  test('localDate must match document id', async () => {
    await assertFails(setDoc(ref('2026-11-19'), validWorkout()));
  });
  test('createdAt must be a timestamp', async () => {
    const w = validWorkout(); w.workout.createdAt = '2026-11-18';
    await assertFails(setDoc(ref(), w));
  });
  test('missing exercises is rejected', async () => {
    const w = validWorkout(); delete w.exercises;
    await assertFails(setDoc(ref(), w));
  });
  test('too many exercises is rejected', async () => {
    await assertFails(setDoc(ref(), { ...validWorkout(), exercises: Array(101).fill({}) }));
  });
  test('extra workout key is rejected', async () => {
    const w = validWorkout(); w.workout.userID = 'bob';
    await assertFails(setDoc(ref(), w));
  });
});

describe('customExercises validation', () => {
  const ref = (id = UUID_A) => doc(alice(), `users/alice/customExercises/${id}`);
  test('category may be omitted (nil is skipped by the encoder)', async () => {
    await assertSucceeds(setDoc(ref(), { id: UUID_A, name: 'Squat' }));
  });
  test('id must equal document id', async () => {
    await assertFails(setDoc(ref(UUID_B), validExercise(UUID_A)));
  });
  test('empty and overlong names are rejected', async () => {
    await assertFails(setDoc(ref(), { ...validExercise(), name: '' }));
    await assertFails(setDoc(ref(), { ...validExercise(), name: 'x'.repeat(201) }));
  });
  test('non-string category is rejected', async () => {
    await assertFails(setDoc(ref(), { ...validExercise(), category: 5 }));
  });
});

describe('settings validation', () => {
  const ref = (id = 'default') => doc(alice(), `users/alice/settings/${id}`);
  test('full profile is valid', async () => {
    await assertSucceeds(setDoc(ref(), { appearance: 'system', weightUnit: 'lb', sex: 'preferNotToSay', dateOfBirth: '1990-01-31', heightCentimeters: 180.5 }));
  });
  test('single-field merge writes are valid', async () => {
    await assertSucceeds(setDoc(ref(), { appearance: 'light' }, { merge: true }));
    await assertSucceeds(setDoc(ref(), { weightUnit: 'kg' }, { merge: true }));
  });
  test('unknown enum values are rejected', async () => {
    await assertFails(setDoc(ref(), { ...validSettings(), appearance: 'neon' }));
    await assertFails(setDoc(ref(), { ...validSettings(), weightUnit: 'stone' }));
    await assertFails(setDoc(ref(), { ...validSettings(), sex: 'other' }));
  });
  test('bad dateOfBirth and height are rejected', async () => {
    await assertFails(setDoc(ref(), { ...validSettings(), dateOfBirth: '31.01.1990' }));
    await assertFails(setDoc(ref(), { ...validSettings(), heightCentimeters: '180' }));
  });
  test('non-default settings document is denied', async () => {
    await assertFails(setDoc(ref('other'), validSettings()));
    await assertFails(getDoc(ref('other')));
  });
});

describe('bodyWeightMeasurements validation', () => {
  const ref = (id = UUID_A) => doc(alice(), `users/alice/bodyWeightMeasurements/${id}`);
  test('id must equal document id', async () => {
    await assertFails(setDoc(ref(UUID_B), validWeight(UUID_A)));
  });
  test('non-positive or non-numeric weight is rejected', async () => {
    await assertFails(setDoc(ref(), { ...validWeight(), weightInKilograms: 0 }));
    await assertFails(setDoc(ref(), { ...validWeight(), weightInKilograms: '80' }));
  });
  test('missing measuredAt and bad localDate are rejected', async () => {
    const w = validWeight(); delete w.measuredAt;
    await assertFails(setDoc(ref(), w));
    await assertFails(setDoc(ref(), { ...validWeight(), localDate: '2026-1-1' }));
  });
});
