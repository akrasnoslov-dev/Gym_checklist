[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$trackedFiles = @(git ls-files)
$forbiddenName = '(^|/)(GoogleService-Info.*\.plist|.*firebase-adminsdk.*\.json|service-account.*\.json|firebase-service-account.*\.json)$'
if ($trackedFiles | Where-Object { $_ -match $forbiddenName }) {
    throw 'Tracked Firebase configuration or service-account material detected'
}

$serviceAccountMarker = '"type"\s*:\s*"service_account"'
foreach ($file in $trackedFiles) {
    if ((Test-Path -LiteralPath $file -PathType Leaf) -and (Select-String -LiteralPath $file -Pattern $serviceAccountMarker -Quiet)) {
        throw 'Tracked Firebase service-account material detected'
    }
}

Write-Output 'Firebase security hygiene: PASS'
