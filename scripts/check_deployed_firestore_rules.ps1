[CmdletBinding()]
param(
    # Firebase project ID (Firebase Console > Project settings), e.g. the GymChecklist Dev project.
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    # OAuth access token with Firebase Rules read access. Defaults to
    # $env:GOOGLE_OAUTH_ACCESS_TOKEN, then `gcloud auth print-access-token`.
    [string]$AccessToken,
    [string]$RulesPath
)

# Compares the Firestore rules currently released in a Firebase project with
# firestore.rules in this repository (GYM-22: the deployed rules had drifted and
# rejected every body-weight write). Read-only: it never deploys.

$ErrorActionPreference = 'Stop'
if (-not $RulesPath) { $RulesPath = Join-Path $PSScriptRoot "..\firestore.rules" }

if (-not $AccessToken) { $AccessToken = $env:GOOGLE_OAUTH_ACCESS_TOKEN }
if (-not $AccessToken) {
    $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
    if (-not $gcloud) {
        throw "No access token. Pass -AccessToken, set GOOGLE_OAUTH_ACCESS_TOKEN, or install gcloud and run 'gcloud auth login'. Manual alternative: Firebase Console > Firestore > Rules, compare with firestore.rules."
    }
    $AccessToken = (& gcloud auth print-access-token).Trim()
}

function Get-NormalizedRules([string]$Text) {
    $lines = ($Text -replace "`r`n", "`n") -split "`n" | ForEach-Object { $_.TrimEnd() }
    return ($lines -join "`n").Trim()
}

$headers = @{ Authorization = "Bearer $AccessToken" }
$base = 'https://firebaserules.googleapis.com/v1'
$release = Invoke-RestMethod -Headers $headers -Uri "$base/projects/$ProjectId/releases/cloud.firestore"
$ruleset = Invoke-RestMethod -Headers $headers -Uri "$base/$($release.rulesetName)"
$deployedFile = $ruleset.source.files | Select-Object -First 1
if (-not $deployedFile) { throw "Released ruleset $($release.rulesetName) has no source files." }

$deployed = Get-NormalizedRules $deployedFile.content
$repository = Get-NormalizedRules (Get-Content -Raw $RulesPath)

Write-Output "Released ruleset: $($release.rulesetName) (updated $($release.updateTime))"
if ($deployed -ceq $repository) {
    Write-Output "Deployed Firestore rules match firestore.rules: PASS"
    exit 0
}

$deployedLines = $deployed -split "`n"
$repositoryLines = $repository -split "`n"
Compare-Object -ReferenceObject $repositoryLines -DifferenceObject $deployedLines |
    Select-Object -First 40 |
    ForEach-Object {
        $side = if ($_.SideIndicator -eq '<=') { 'repo only    ' } else { 'deployed only' }
        Write-Output "$side | $($_.InputObject)"
    }
Write-Error "Deployed Firestore rules differ from firestore.rules: DRIFT. Deploy from the repository: firebase deploy --only firestore:rules --project $ProjectId"
exit 1
