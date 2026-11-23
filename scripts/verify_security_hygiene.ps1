[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$trackedFiles = @(git ls-files)
$forbiddenName = '(^|/)(GoogleService-Info.*\.plist|.*firebase-adminsdk.*\.json|service-account.*\.json|firebase-service-account.*\.json|.*\.p12|.*\.mobileprovision|.*\.p8)$'
if ($trackedFiles | Where-Object { $_ -match $forbiddenName }) {
    throw 'Tracked Firebase configuration or service-account material detected'
}

$serviceAccountMarker = '"type"\s*:\s*"service_account"'
$privateKeyMarker = '-----BEGIN(?: [A-Z]+)* PRIVATE KEY-----'
foreach ($file in $trackedFiles) {
    if ((Test-Path -LiteralPath $file -PathType Leaf) -and (Select-String -LiteralPath $file -Pattern $serviceAccountMarker -Quiet)) {
        throw 'Tracked Firebase service-account material detected'
    }
    if ((Test-Path -LiteralPath $file -PathType Leaf) -and (Select-String -LiteralPath $file -Pattern $privateKeyMarker -Quiet)) {
        throw 'Tracked private-key material detected'
    }
}

$projectFile = 'GymChecklist.xcodeproj/project.pbxproj'
$entitlementsFile = 'GymChecklist/GymChecklist.entitlements'
if (-not (Test-Path -LiteralPath $entitlementsFile -PathType Leaf)) {
    throw 'Missing Sign in with Apple entitlement file'
}
if ((Get-Content -Raw -LiteralPath $projectFile) -notmatch 'CODE_SIGN_ENTITLEMENTS\s*=\s*GymChecklist/GymChecklist\.entitlements') {
    throw 'GymChecklist target does not declare its entitlement file'
}
if ((Get-Content -Raw -LiteralPath $entitlementsFile) -notmatch '<key>com\.apple\.developer\.applesignin</key>') {
    throw 'Sign in with Apple entitlement is missing'
}

Write-Output 'Firebase security hygiene: PASS'
