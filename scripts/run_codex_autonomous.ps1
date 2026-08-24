param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$MasterPromptPath = "docs/codex_master_prompt.md",
    [ValidateSet("workspace-write", "danger-full-access")]
    [string]$Sandbox = "workspace-write",
    [int]$MaxConsecutiveNoProgress = 4,
    [int]$MaxConsecutiveProcessErrors = 3,
    [int]$RetryDelaySeconds = 15
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath([string]$PathValue) {
    return (Resolve-Path $PathValue).Path
}

function Get-MasterPrompt([string]$PathValue) {
    $raw = Get-Content $PathValue -Raw
    $match = [regex]::Match($raw, '(?s)```text\s*(.*?)\s*```')
    if (-not $match.Success) {
        throw "Could not find the fenced ```text master prompt in $PathValue"
    }
    return $match.Groups[1].Value.Trim()
}

function Get-RepoFingerprint {
    $head = (& git rev-parse HEAD 2>$null)
    $progressHash = ""
    if (Test-Path "docs/progress.md") {
        $progressHash = (Get-FileHash "docs/progress.md" -Algorithm SHA256).Hash
    }
    return "$head|$progressHash"
}

function Invoke-Gate {
    & python "scripts/codex_final_gate.py"
    return $LASTEXITCODE
}

function Parse-ThreadId([string[]]$Lines) {
    foreach ($line in $Lines) {
        try {
            $obj = $line | ConvertFrom-Json
            if ($obj.type -eq "thread.started" -and $obj.thread_id) {
                return [string]$obj.thread_id
            }
        } catch {
            # Ignore non-JSON stderr/progress lines.
        }
    }
    return $null
}

function Invoke-CodexInitial([string]$Prompt, [string]$LogPath) {
    Write-Host "Starting Codex autonomous session..."
    $lines = @(
        $Prompt | & codex exec --sandbox $Sandbox --json - 2>&1 |
            Tee-Object -FilePath $LogPath
    )
    $exitCode = $LASTEXITCODE
    $threadId = Parse-ThreadId $lines
    return @{
        ExitCode = $exitCode
        ThreadId = $threadId
    }
}

function Invoke-CodexResume([string]$ThreadId, [string]$Prompt, [string]$LogPath) {
    Write-Host "Resuming Codex thread $ThreadId ..."
    $lines = @(
        & codex exec resume $ThreadId $Prompt 2>&1 |
            Tee-Object -FilePath $LogPath
    )
    return @{
        ExitCode = $LASTEXITCODE
        ThreadId = $ThreadId
    }
}

$repo = Resolve-RepoPath $RepoPath
Set-Location $repo

if (-not (Test-Path ".git")) {
    throw "RepoPath is not a Git repository: $repo"
}
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    throw "Codex CLI was not found in PATH. Install/authenticate Codex CLI first."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python was not found in PATH."
}
if (-not (Test-Path "scripts/codex_final_gate.py")) {
    throw "Missing scripts/codex_final_gate.py"
}
if (-not (Test-Path $MasterPromptPath)) {
    throw "Missing $MasterPromptPath"
}

New-Item -ItemType Directory -Force ".codex/logs" | Out-Null
Remove-Item ".codex/stop_state.json" -Force -ErrorAction SilentlyContinue

$masterPrompt = Get-MasterPrompt $MasterPromptPath
$continuationPrompt = @"
The previous Codex turn ended, but the external machine gate says CONTINUE.

Re-read the actual repository state and continue the implementation plan immediately.
A final message is only a checkpoint unless scripts/codex_final_gate.py says STOP_ALLOWED.

If the current task is blocked by external configuration or verification:
- finish every safe local part;
- record PENDING EXTERNAL/CI/LIVE accurately;
- add the required action to the batched USER ACTION REQUIRED QUEUE;
- scan the ENTIRE remaining implementation plan for another technically safe task;
- continue that work.

Do not stop merely because a task, milestone, commit, push, review, CI run, or progress update completed.

Only when no technically safe work remains anywhere in the backlog may you create .codex/stop_state.json using scripts/write_codex_stop_state.py and return a terminal response.
"@

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$initialLog = ".codex/logs/$timestamp-initial.jsonl"
$before = Get-RepoFingerprint
$result = Invoke-CodexInitial $masterPrompt $initialLog

if (-not $result.ThreadId) {
    Write-Warning "Could not parse a thread ID from the initial JSONL output."
}
$threadId = $result.ThreadId
$consecutiveNoProgress = 0
$consecutiveProcessErrors = 0
$iteration = 0

while ($true) {
    $iteration++

    $gateCode = Invoke-Gate
    if ($gateCode -eq 0) {
        Write-Host "Supervisor stop allowed."
        exit 0
    }
    if ($gateCode -ne 10) {
        throw "Final gate failed with exit code $gateCode."
    }

    $after = Get-RepoFingerprint
    if ($after -eq $before) {
        $consecutiveNoProgress++
    } else {
        $consecutiveNoProgress = 0
    }
    $before = $after

    if ($result.ExitCode -ne 0) {
        $consecutiveProcessErrors++
        Write-Warning "Codex process exited with code $($result.ExitCode). Error streak: $consecutiveProcessErrors/$MaxConsecutiveProcessErrors"
        if ($consecutiveProcessErrors -ge $MaxConsecutiveProcessErrors) {
            throw "Codex repeatedly exited with errors while the gate still says CONTINUE. Inspect the latest .codex/logs output."
        }
        Start-Sleep -Seconds ($RetryDelaySeconds * $consecutiveProcessErrors)
    } else {
        $consecutiveProcessErrors = 0
    }

    if ($consecutiveNoProgress -ge $MaxConsecutiveNoProgress) {
        throw "Supervisor stalled: $consecutiveNoProgress consecutive Codex turns made no Git/progress change while work remains."
    }

    Remove-Item ".codex/stop_state.json" -Force -ErrorAction SilentlyContinue

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $log = ".codex/logs/$timestamp-resume-$iteration.jsonl"

    if ($threadId) {
        $result = Invoke-CodexResume $threadId $continuationPrompt $log
    } else {
        Write-Warning "No resumable thread ID is available; starting a fresh Codex exec from repository state."
        $result = Invoke-CodexInitial $masterPrompt $log
        if ($result.ThreadId) {
            $threadId = $result.ThreadId
        }
    }
}
