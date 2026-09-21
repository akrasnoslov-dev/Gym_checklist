[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

function Read-RepoFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required agentic-workflow file: $RelativePath"
    }

    return Get-Content -Raw -LiteralPath $path
}

function Require-Fragment {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Fragment
    )

    if (-not $Content.Contains($Fragment)) {
        throw "$RelativePath is missing required agentic-workflow contract: $Fragment"
    }
}

$agents = Read-RepoFile 'AGENTS.md'
$sourceOfTruth = Read-RepoFile 'docs/source_of_truth.md'
$codex = Read-RepoFile 'docs/codex_instructions.md'
$routing = Read-RepoFile 'agents/routing.toml'
$config = Read-RepoFile '.codex/config.toml'
$readme = Read-RepoFile 'README.md'

if (-not (Test-Path -LiteralPath (Join-Path $root 'docs/task_specs') -PathType Container)) {
    throw 'Missing docs/task_specs directory for task-specific historical specifications'
}

Require-Fragment 'AGENTS.md' $agents 'docs/source_of_truth.md'
Require-Fragment 'AGENTS.md' $agents 'docs/codex_instructions.md'

@(
    'docs/product_spec.md',
    'docs/ux_spec.md',
    'docs/architecture.md',
    'docs/implementation_plan.md',
    'docs/progress.md',
    'docs/codex_instructions.md',
    'agents/routing.toml',
    '.codex/config.toml',
    'docs/task_specs/'
) | ForEach-Object {
    Require-Fragment 'docs/source_of_truth.md' $sourceOfTruth $_
}

@(
    'Clarification gate',
    'Task specification and plan',
    'Test-first gate',
    'RED',
    'GREEN',
    'No green verification, no completion.',
    'git worktree',
    'gpt-5.6-sol',
    'gpt-5.6-terra',
    'gpt-5.6-luna',
    'adaptive',
    'Token-efficiency objective',
    'PRs target `dev`',
    'Do not auto-merge'
) | ForEach-Object {
    Require-Fragment 'docs/codex_instructions.md' $codex $_
}

@(
    '[execution]',
    'orchestrator_model = "gpt-5.6-sol"',
    'default_worker_model = "gpt-5.6-terra"',
    'low_cost_worker_model = "gpt-5.6-luna"',
    'worker_count_policy = "adaptive"',
    'isolation = "git_worktree"',
    'sol_worker_policy = "escalation_only"',
    'token_efficiency_objective = true'
) | ForEach-Object {
    Require-Fragment 'agents/routing.toml' $routing $_
}

if ($routing.Contains('prefer_parallel_subagents_when_available = true')) {
    throw 'agents/routing.toml still forces parallel subagents instead of adaptive, benefit-based worker use'
}

@(
    'model = "gpt-5.6-sol"',
    'model_reasoning_effort = "medium"',
    'default_subagent_model = "gpt-5.6-terra"',
    'default_subagent_reasoning_effort = "medium"'
) | ForEach-Object {
    Require-Fragment '.codex/config.toml' $config $_
}

Require-Fragment 'README.md' $readme 'docs/source_of_truth.md'

Write-Output 'Agentic development workflow contract: PASS'
