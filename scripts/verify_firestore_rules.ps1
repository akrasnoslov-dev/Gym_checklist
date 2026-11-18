[CmdletBinding()]
param(
    [string]$RulesPath = (Join-Path $PSScriptRoot "..\firestore.rules")
)

$rules = Get-Content -Raw $RulesPath
$requiredFragments = @(
    "rules_version = '2';",
    'service cloud.firestore',
    'request.auth != null && request.auth.uid == userId',
    'match /users/{userId}/workouts/{workoutDate}',
    'match /users/{userId}/customExercises/{exerciseId}',
    'match /users/{userId}/settings/default',
    'match /users/{userId}/bodyWeightMeasurements/{measurementId}',
    'allow get, list, delete: if ownsUserData(userId);',
    'allow get, delete: if ownsUserData(userId);',
    'allow create, update: if ownsUserData(userId) && isValidWorkout(workoutDate);',
    'allow create, update: if ownsUserData(userId) && isValidCustomExercise(exerciseId);',
    'allow create, update: if ownsUserData(userId) && isValidSettings();',
    'allow create, update: if ownsUserData(userId) && isValidBodyWeight(measurementId);',
    "workoutDate.matches('^\\d{4}-\\d{2}-\\d{2}$')",
    'data.id == exerciseId',
    'data.id == measurementId',
    'keys().hasOnly('
)

foreach ($fragment in $requiredFragments) {
    if (-not $rules.Contains($fragment)) {
        throw "Firestore rules are missing required owner-isolation fragment: $fragment"
    }
}

if ($rules.Contains('{document=**}') -or $rules.Contains('allow read, write: if true') -or $rules.Contains('allow get, list, create, update, delete: if true')) {
    throw "Firestore rules contain a broad allow that would weaken owner isolation"
}

$testPath = Join-Path $PSScriptRoot "..\firestore-tests\rules.test.js"
if (-not (Test-Path $testPath)) {
    throw "Firestore rules emulator tests are missing: firestore-tests/rules.test.js"
}

Write-Output "Firestore owner-isolation and write-validation rule contract: PASS"
