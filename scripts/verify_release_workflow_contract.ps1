$ErrorActionPreference = "Stop"

$workflowPath = Join-Path $PSScriptRoot "..\.github\workflows\testflight-release.yml"
$workflow = Get-Content -Raw $workflowPath

$requiredFragments = @(
    'IOS_DISTRIBUTION_CERTIFICATE_PASSWORD',
    'source_revision:',
    'validate-source:',
    'test "$GITHUB_REF" = "refs/heads/dev"',
    'git merge-base --is-ancestor HEAD origin/dev',
    'needs: validate-source',
    'ref: ${{ needs.validate-source.outputs.source_sha }}'
)

foreach ($fragment in $requiredFragments) {
    if (-not $workflow.Contains($fragment)) {
        throw "Release workflow is missing required contract: $fragment"
    }
}

if ($workflow.Contains('APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD')) {
    throw "Release workflow references an undefined certificate-password variable."
}

Write-Output "Release workflow contract: PASS"
