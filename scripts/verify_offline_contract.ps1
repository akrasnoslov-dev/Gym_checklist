[CmdletBinding()]
param(
    [string]$RepositoryPath = (Join-Path $PSScriptRoot "..\GymChecklist\Data\Firebase\FirestoreWorkoutRepository.swift"),
    [string]$PlanPath = (Join-Path $PSScriptRoot "..\docs\offline_test_plan.md"),
    [string]$TodayViewPath = (Join-Path $PSScriptRoot "..\GymChecklist\Features\Today\TodayView.swift")
)

$repository = Get-Content -Raw $RepositoryPath
$plan = Get-Content -Raw $PlanPath
$todayView = Get-Content -Raw $TodayViewPath

foreach ($fragment in @('addSnapshotListener', 'workouts.append(workout)', 'publish()', 'persist(workout)', 'collection("users").document(userID.rawValue).collection("workouts").document(date.description)')) {
    if (-not $repository.Contains($fragment)) {
        throw "Firestore workout repository is missing offline contract fragment: $fragment"
    }
}

$createMutation = [regex]::Match($repository, 'workouts\.append\(workout\)\s*publish\(\)\s*persist\(workout\)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $createMutation.Success) {
    throw 'Workout creation must publish its local snapshot before persistence is queued'
}

$saveMutation = [regex]::Match($repository, 'workouts\.append\(workout\)\s*publish\(\)\s*persist\(workout\)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $saveMutation.Success) {
    throw 'Workout saves must publish their local snapshot before persistence is queued'
}

$deleteMutation = [regex]::Match($repository, 'workouts\.removeAll\s*\{[^}]+\}\s*publish\(\)\s*document\(for: date\)\.delete\(\)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $deleteMutation.Success) {
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
