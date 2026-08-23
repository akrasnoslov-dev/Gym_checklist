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
    'allow get, list, create, update, delete: if ownsUserData(userId);',
    'allow get, create, update, delete: if ownsUserData(userId);'
)

foreach ($fragment in $requiredFragments) {
    if (-not $rules.Contains($fragment)) {
        throw "Firestore rules are missing required owner-isolation fragment: $fragment"
    }
}

if ($rules.Contains('{document=**}') -or $rules.Contains('allow read, write: if true') -or $rules.Contains('allow get, list, create, update, delete: if true')) {
    throw "Firestore rules contain a broad allow that would weaken owner isolation"
}

Write-Output "Firestore owner-isolation rule contract: PASS"
