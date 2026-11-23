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

$acceptanceWorkflowPath = Join-Path $PSScriptRoot "..\.github\workflows\mvp-acceptance-ipa.yml"
$acceptanceWorkflow = Get-Content -Raw $acceptanceWorkflowPath
$acceptanceFragments = @(
    'source_sha:',
    'APP_SOURCE_SHA: ${{ inputs.source_sha }}',
    'ref: ${{ inputs.source_sha }}',
    '^[0-9a-f]{40}$',
    'test "$(git rev-parse HEAD)" = "$APP_SOURCE_SHA"',
    'app source SHA: $APP_SOURCE_SHA',
    'name: GymChecklist-MVP-${{ inputs.source_sha }}'
)

foreach ($fragment in $acceptanceFragments) {
    if (-not $acceptanceWorkflow.Contains($fragment)) {
        throw "Acceptance IPA workflow is missing exact-source contract: $fragment"
    }
}

if ($acceptanceWorkflow.Contains('e17cb8173a6373059729226453c568e976954d33')) {
    throw "Acceptance IPA workflow still pins the obsolete acceptance source."
}

Write-Output "Acceptance IPA exact-source contract: PASS"
