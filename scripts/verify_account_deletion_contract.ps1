[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$functionSource = 'functions/index.js'
$authenticationSource = 'GymChecklist/Features/Auth/Authentication.swift'
$settingsSource = 'GymChecklist/Features/Settings/SettingsView.swift'

foreach ($file in @($functionSource, $authenticationSource, $settingsSource)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Missing account-deletion contract file: $file"
    }
}

$functionText = Get-Content -Raw -LiteralPath $functionSource
if ($functionText -notmatch 'request\.auth\?\.uid') {
    throw 'Account deletion must derive the user ID from authenticated callable context'
}
if ($functionText -match 'request\.data') {
    throw 'Account deletion must not accept a caller-supplied deletion target'
}
if ($functionText -notmatch 'recursiveDelete' -or $functionText -notmatch 'deleteUser') {
    throw 'Account deletion must erase Firestore data before deleting Firebase Auth'
}
if ($functionText -notmatch 'auth_time') {
    throw 'Account deletion must require recent authentication'
}

$authenticationText = Get-Content -Raw -LiteralPath $authenticationSource
if ($authenticationText -notmatch 'httpsCallable\("deleteAccount"\)') {
    throw 'The iOS account-deletion client must call the authenticated backend contract'
}
if ($authenticationText -notmatch 'revokeToken\(withAuthorizationCode: authorizationCode\)') {
    throw 'Sign in with Apple account deletion must revoke the freshly collected Apple authorization code'
}
if ($authenticationText -match '\.delete\(\)') {
    throw 'The iOS client must not delete Firebase Auth before the server-side erase succeeds'
}
if ((Get-Content -Raw -LiteralPath $settingsSource) -notmatch 'Delete account\?') {
    throw 'Settings must require destructive account-deletion confirmation'
}

Write-Output 'Account-deletion contract: PASS'
