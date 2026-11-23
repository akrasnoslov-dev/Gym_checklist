$ErrorActionPreference = 'Stop'

$project = Get-Content -Raw (Join-Path $PSScriptRoot '..\GymChecklist.xcodeproj\project.pbxproj')
$googleSetup = Get-Content -Raw (Join-Path $PSScriptRoot '..\docs\google_signin_setup.md')

foreach ($requiredProjectToken in @(
    'Install local Firebase configuration',
    'GoogleService-Info.plist',
    'REVERSED_CLIENT_ID',
    'CFBundleURLSchemes'
)) {
    if (-not $project.Contains($requiredProjectToken)) {
        throw "Xcode project is missing Google Sign-In configuration token: $requiredProjectToken"
    }
}

if (-not $googleSetup.Contains('GymChecklist/GoogleService-Info.plist')) {
    throw 'Google Sign-In setup documentation must name the local configuration path.'
}

Write-Output 'Google Sign-In configuration contract passed.'
