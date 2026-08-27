# Codex Instructions — compatibility reference

`AGENTS.md` is the only execution/scheduling rulebook. This file is intentionally small and is **not** mandatory startup reading.

Useful repository checks on Windows/Linux:

```text
git status -sb
git diff --check
pwsh -File scripts/verify_security_hygiene.ps1
pwsh -File scripts/verify_account_deletion_contract.ps1
```

Authoritative iOS verification runs in `.github/workflows/ios-ci.yml` on macOS/Xcode.

Normal strategy: use one `full` macOS run at a coherent checkpoint. Use `build`, `unit`, or `ui` only to diagnose a failure or a narrowly risky build/test surface, then return to `full` for reconciliation.

For one known failing test, use the optional `test_filter` workflow input instead of rerunning the entire target. Example:

```powershell
gh workflow run ios-ci.yml --repo akrasnoslov-dev/Gym_checklist --ref dev -f verification_scope=ui -f "test_filter=GymChecklistUITests/GymChecklistUITests/testProgramWeekNavigation"
```

Use the exact test class/method reported by the failure. After the focused test passes, return directly to one `full` run.

When CI is the only remaining gate, do not spend model turns polling unchanged status. Confirm the run ID/SHA once, then wait in one silent foreground command:

PowerShell:
```powershell
gh run watch <RUN_ID> --repo akrasnoslov-dev/Gym_checklist --exit-status --interval 60 *> $null
```

Bash:
```bash
gh run watch <RUN_ID> --repo akrasnoslov-dev/Gym_checklist --exit-status --interval 60 >/dev/null 2>&1
```

If the execution tool cannot hold one wait for the full CI duration, use the largest practical silent wait chunks and never check more often than once every 5 minutes. Inspect the result once after the wait returns, then continue work.

Never claim local Xcode verification from the user's Windows machine. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
