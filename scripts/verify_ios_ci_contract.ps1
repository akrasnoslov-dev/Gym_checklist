$ErrorActionPreference = "Stop"

$workflowPath = Join-Path $PSScriptRoot "..\.github\workflows\ios-ci.yml"
$workflow = Get-Content -Raw $workflowPath

$pullRequestTrigger = [regex]::Match($workflow, '(?ms)^  pull_request:\r?\n.*?(?=^  workflow_dispatch:)')
if (-not $pullRequestTrigger.Success) {
    throw 'iOS CI workflow is missing a pull_request trigger block.'
}

$requiredPatterns = @(
    'candidate_source_sha:',
    'CANDIDATE_SOURCE_SHA:',
    'ref: \$\{\{ inputs\.candidate_source_sha \|\| github\.sha \}\}',
    'candidate scope requires a 40-character lowercase candidate_source_sha',
    'test "\$\(git rev-parse HEAD\)" = "\$CANDIDATE_SOURCE_SHA"',
    'run_xcodebuild candidate-build',
    'run_xcodebuild candidate-focused',
    'run_xcodebuild candidate-full'
)

foreach ($pattern in $requiredPatterns) {
    if ($workflow -notmatch $pattern) {
        throw "iOS CI workflow is missing required candidate contract: $pattern"
    }
}

if ($pullRequestTrigger.Value -notmatch '(?m)^    paths:\s*$') {
    throw 'iOS CI pull-request trigger must contain a paths allowlist.'
}

if ($pullRequestTrigger.Value -match '(?m)^\s*paths-ignore:\s*$') {
    throw "iOS CI pull-request trigger must use an allowlist (paths), not paths-ignore"
}

$requiredPullRequestPaths = @(
    "GymChecklist/**",
    "GymChecklistTests/**",
    "GymChecklistUITests/**",
    "GymChecklist.xcodeproj/**",
    "Package.swift",
    "Package.resolved",
    "**/*.xcconfig",
    "**/*.entitlements",
    "GymChecklist/**/*.plist"
)

foreach ($path in $requiredPullRequestPaths) {
    $escaped = [regex]::Escape("- '$path'")
    if ($pullRequestTrigger.Value -notmatch $escaped) {
        throw "iOS CI workflow is missing required iOS-impacting PR path: $path"
    }
}

$swiftPMCache = [regex]::Match($workflow, '(?ms)^      - name: Cache Swift package sources\r?\n.*?(?=^      - name:|\z)')
if (-not $swiftPMCache.Success) {
    throw 'iOS CI workflow is missing the SwiftPM source-cache step.'
}

$requiredCachePatterns = @(
    'uses: actions/cache@',
    '(?m)^\s+path: \$\{\{ runner\.temp \}\}/SourcePackages\s*$',
    'key: \$\{\{ runner\.os \}\}-xcode-\$\{\{ steps\.xcode\.outputs\.version \}\}-swiftpm-\$\{\{ hashFiles\(''GymChecklist\.xcodeproj/project\.pbxproj'', ''\*\*/Package\.resolved'', ''Package\.swift''\) \}\}',
    'restore-keys:\s*\|\r?\n\s+\$\{\{ runner\.os \}\}-xcode-\$\{\{ steps\.xcode\.outputs\.version \}\}-swiftpm-'
)

foreach ($pattern in $requiredCachePatterns) {
    if ($swiftPMCache.Value -notmatch $pattern) {
        throw "iOS CI SwiftPM cache is missing required contract: $pattern"
    }
}

if ($swiftPMCache.Value -match '(?i)DerivedData') {
    throw 'iOS CI must not cache DerivedData.'
}

$xcodeVersionStep = [regex]::Match($workflow, '(?ms)^      - name: Record Xcode version\r?\n.*?(?=^      - name:|\z)')
if (-not $xcodeVersionStep.Success -or $xcodeVersionStep.Value -notmatch '(?m)^        id: xcode\s*$' -or $xcodeVersionStep.Value -notmatch 'xcodebuild -version') {
    throw 'iOS CI must record the Xcode version used by the SwiftPM cache.'
}
$requiredRoutineAndConcurrencyPatterns = @(
    'VERIFICATION_SCOPE:\s*\$\{\{\s*github\.event_name\s*==\s*''pull_request''\s*&&\s*''smoke''\s*\|\|\s*inputs\.verification_scope\s*\}\}',
    '(?m)^\s*- full\s*$',
    '(?m)^\s*- smoke\s*$',
    '(?m)^\s*- build\s*$',
    '(?m)^\s*- unit\s*$',
    '(?m)^\s*- ui\s*$',
    '(?m)^\s*- candidate\s*$',
    'run_xcodebuild full',
    'group: ios-macos-\$\{\{ github\.ref \}\}-\$\{\{ github\.event_name \}\}',
    'cancel-in-progress: \$\{\{ github\.event_name != ''workflow_dispatch'' \}\}',
    'id: xcode',
    'steps\.xcode\.outputs\.version',
    'hashFiles\(''GymChecklist\.xcodeproj/project\.pbxproj'''
)

foreach ($pattern in $requiredRoutineAndConcurrencyPatterns) {
    if ($workflow -notmatch $pattern) {
        throw "iOS CI workflow is missing required routine-PR, manual-scope, concurrency, or cache contract: $pattern"
    }
}

Write-Output "iOS CI candidate, PR path, smoke, concurrency, and cache contract: PASS"
