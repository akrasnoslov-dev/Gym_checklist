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

Write-Output "iOS CI candidate contract: PASS"
