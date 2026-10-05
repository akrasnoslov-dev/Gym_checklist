[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

function Read-RepoFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required workflow file: $RelativePath"
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
        throw "$RelativePath is missing required workflow contract: $Fragment"
    }
}

function Forbid-Fragment {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Fragment
    )

    if ($Content.Contains($Fragment)) {
        throw "$RelativePath still contains deprecated workflow contract: $Fragment"
    }
}

$projectSource = Read-RepoFile 'CHATGPT_PROJECT_SOURCE.md'
$agents = Read-RepoFile 'AGENTS.md'
$sourceOfTruth = Read-RepoFile 'docs/source_of_truth.md'
$codex = Read-RepoFile 'docs/codex_instructions.md'
$plan = Read-RepoFile 'docs/implementation_plan.md'
$routing = Read-RepoFile 'agents/routing.toml'
$agentReadme = Read-RepoFile 'agents/README.md'
$config = Read-RepoFile '.codex/config.toml'
$readme = Read-RepoFile 'README.md'

if (Test-Path -LiteralPath (Join-Path $root 'docs/task_specs')) {
    throw 'Deprecated docs/task_specs directory still exists'
}

if (Test-Path -LiteralPath (Join-Path $root 'docs/codex_master_prompt.md')) {
    throw 'Deprecated docs/codex_master_prompt.md still exists'
}

@(
    'ChatGPT is the primary control plane',
    'codex-chatgpt-bridge',
    'L3_WORKSPACE_WRITE',
    'D:\Projects\gym_checklist',
    'Codex is fallback execution only',
    'Do not create Git worktrees'
) | ForEach-Object {
    Require-Fragment 'CHATGPT_PROJECT_SOURCE.md' $projectSource $_
}

@(
    'The ChatGPT project chat is the primary decision-maker and orchestrator.',
    'Keep one checkout only.',
    'Do not create `git worktree` checkouts',
    'Do not create per-task `docs/task_specs/` records.'
) | ForEach-Object {
    Require-Fragment 'AGENTS.md' $agents $_
}

@(
    'CHATGPT_PROJECT_SOURCE.md',
    'docs/codex_instructions.md',
    'There is no per-task `docs/task_specs/` system.'
) | ForEach-Object {
    Require-Fragment 'docs/source_of_truth.md' $sourceOfTruth $_
}

@(
    'Codex is not the primary orchestrator for this project.',
    'Do not create Git worktrees.',
    'No task-spec files',
    'No green verification, no completion.',
    'ChatGPT decides the next action and final acceptance.'
) | ForEach-Object {
    Require-Fragment 'docs/codex_instructions.md' $codex $_
}

@(
    'This is the long-term implementation backlog and acceptance reference. It does not own the execution workflow.',
    '## Execution ownership',
    'ChatGPT selects and sequences work'
) | ForEach-Object {
    Require-Fragment 'docs/implementation_plan.md' $plan $_
}

Forbid-Fragment 'docs/implementation_plan.md' $plan '## Autonomous execution rules'
Forbid-Fragment 'docs/implementation_plan.md' $plan 'This is the execution backlog for Codex.'

@(
    'ChatGPT decides when a specialist review is needed.',
    'Do not create extra worktrees or parallel editing checkouts'
) | ForEach-Object {
    Require-Fragment 'agents/README.md' $agentReadme $_
}

@(
    'primary_control_plane = "chatgpt_project_chat"',
    'codex_usage = "fallback_only"',
    'parallelization_policy = "sequential_single_checkout"',
    'orchestrator_surface = "chatgpt"',
    'codex_role = "fallback_executor_only"',
    'worker_count_policy = "single"',
    'isolation = "single_checkout"'
) | ForEach-Object {
    Require-Fragment 'agents/routing.toml' $routing $_
}

Forbid-Fragment 'agents/routing.toml' $routing 'isolation = "git_worktree"'
Forbid-Fragment 'docs/codex_instructions.md' $codex 'Keep Codex as the orchestrator'

@(
    'model = "gpt-5.6-sol"',
    'model_reasoning_effort = "medium"',
    'default_subagent_model = "gpt-5.6-terra"',
    'default_subagent_reasoning_effort = "medium"'
) | ForEach-Object {
    Require-Fragment '.codex/config.toml' $config $_
}

@(
    'ChatGPT project chat is the primary decision-maker and orchestrator.',
    'One local checkout only: `D:\Projects\gym_checklist`.',
    'Codex is fallback execution only'
) | ForEach-Object {
    Require-Fragment 'README.md' $readme $_
}

Write-Output 'ChatGPT-first single-checkout workflow contract: PASS'
