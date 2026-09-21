$ErrorActionPreference = "Stop"

$workflowPath = Join-Path $PSScriptRoot "..\.github\workflows\ios-ci.yml"
$workflow = Get-Content -Raw $workflowPath

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

if ($workflow -match '(?m)^\s*paths-ignore:\s*$') {
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
    "**/*.entitlements"
)

foreach ($path in $requiredPullRequestPaths) {
    $escaped = [regex]::Escape("- '$path'")
    if ($workflow -notmatch $escaped) {
        throw "iOS CI workflow is missing required iOS-impacting PR path: $path"
    }
}

Write-Output "iOS CI candidate and PR path contract: PASS"
