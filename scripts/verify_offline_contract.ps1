[CmdletBinding()]
param(
    [string]$RepositoryPath = (Join-Path $PSScriptRoot "..\GymChecklist\Data\Firebase\FirestoreWorkoutRepository.swift"),
    [string]$SettingsRepositoryPath = (Join-Path $PSScriptRoot "..\GymChecklist\Data\Firebase\FirestoreUserSettingsRepository.swift"),
    [string]$ExerciseRepositoryPath = (Join-Path $PSScriptRoot "..\GymChecklist\Data\Firebase\FirestoreCustomExerciseRepository.swift"),
    [string]$BodyWeightRepositoryPath = (Join-Path $PSScriptRoot "..\GymChecklist\Data\Firebase\FirestoreBodyWeightRepository.swift"),
    [string]$PlanPath = (Join-Path $PSScriptRoot "..\docs\offline_test_plan.md"),
    [string]$TodayViewPath = (Join-Path $PSScriptRoot "..\GymChecklist\Features\Today\TodayView.swift")
)

$repository = Get-Content -Raw $RepositoryPath
$settingsRepository = Get-Content -Raw $SettingsRepositoryPath
$exerciseRepository = Get-Content -Raw $ExerciseRepositoryPath
$bodyWeightRepository = Get-Content -Raw $BodyWeightRepositoryPath
$plan = Get-Content -Raw $PlanPath
$todayView = Get-Content -Raw $TodayViewPath

foreach ($fragment in @('addSnapshotListener', 'workouts.append(workout)', 'publish()', 'persist(workout, ticket: ticket)', 'ScopedDocumentMutationTracker<LocalDate, Workout>', 'DurablePendingMutationJournal<LocalDate, Workout>', 'collection("users").document(userID.rawValue).collection("workouts").document(date.description)')) {
    if (-not $repository.Contains($fragment)) {
        throw "Firestore workout repository is missing offline contract fragment: $fragment"
    }
}

if (-not $repository.Contains('addSnapshotListener(includeMetadataChanges: true)')) {
    throw 'Firestore workout listeners must observe metadata-only reconnect transitions'
}

$createStart = $repository.IndexOf('func createEmptyWorkout')
$saveStart = $repository.IndexOf('func save(_ workout: Workout) throws')
$deleteStart = $repository.IndexOf('func deleteWorkout')
if ($createStart -lt 0 -or $saveStart -lt 0 -or $deleteStart -lt 0) {
    throw 'Firestore workout repository is missing a required mutation method'
}

$createBody = $repository.Substring($createStart, $saveStart - $createStart)
$saveBody = $repository.Substring($saveStart, $deleteStart - $saveStart)
$deleteBody = $repository.Substring($deleteStart)

if ($createBody.IndexOf('workouts.append(workout)') -gt $createBody.IndexOf('publish()') -or $createBody.IndexOf('publish()') -gt $createBody.IndexOf('persist(workout, ticket: ticket)')) {
    throw 'Workout creation must publish its local snapshot before persistence is queued'
}

if ($saveBody.IndexOf('workouts.append(workout)') -gt $saveBody.IndexOf('publish()') -or $saveBody.IndexOf('publish()') -gt $saveBody.IndexOf('persist(workout, ticket: ticket)')) {
    throw 'Workout saves must publish their local snapshot before persistence is queued'
}

if ($repository.Contains('latestWriteGeneration') -or $repository.Contains('nextWriteGeneration')) {
    throw 'Workout write failures must not be filtered by a repository-global generation counter'
}

foreach ($namedRepository in @(
    @{ Name = 'settings'; Source = $settingsRepository },
    @{ Name = 'custom exercise'; Source = $exerciseRepository },
    @{ Name = 'body weight'; Source = $bodyWeightRepository }
)) {
    foreach ($fragment in @('ScopedDocumentMutationTracker<', 'DurablePendingMutationJournal<', 'observePersistenceFailures', 'addSnapshotListener(includeMetadataChanges: true)')) {
        if (-not $namedRepository.Source.Contains($fragment)) {
            throw "Firestore $($namedRepository.Name) repository is missing rejected-write recovery fragment: $fragment"
        }
    }
}

if ($settingsRepository.Contains('merge: true')) {
    throw 'Settings tracking assumes full-document writes; Firestore merge semantics would violate that contract'
}

$deleteQueueIndex = $deleteBody.IndexOf('document(for: date).delete')
if ($deleteBody.IndexOf('workouts.removeAll') -gt $deleteBody.IndexOf('publish()') -or $deleteBody.IndexOf('publish()') -gt $deleteQueueIndex) {
    throw 'Workout deletes must publish their local snapshot before deletion is queued'
}

foreach ($heading in @('## Airplane-mode flow', '## Reconnect and duplicate-safety flow', '## Required evidence')) {
    if (-not $plan.Contains($heading)) {
        throw "Offline test plan is missing required section: $heading"
    }
}

if ($todayView -match '"Sync"' -or $todayView -match 'Sync button') {
    throw 'Today must not expose a manual sync control'
}

Write-Output 'Offline cache/reconnect contract: PASS'
