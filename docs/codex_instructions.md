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

Current MVP strategy: use `smoke` for routine macOS verification. Use exact filtered `unit`/`ui` diagnostics for one known failure. Use `full` only at broad reconciliation/device-handoff checkpoints, not after every small fix.

For one known failing test, use the optional `test_filter` workflow input instead of rerunning the entire target. Example:

```powershell
gh workflow run ios-ci.yml --repo akrasnoslov-dev/Gym_checklist --ref dev -f verification_scope=ui -f "test_filter=GymChecklistUITests/GymChecklistUITests/testProgramWeekNavigation"
```

Use the exact test class/method reported by the failure. After the focused test passes, run `smoke`. Do not automatically run `full`.

When CI is the only remaining gate, do not spend the task limit on a long foreground wait. Check once, wait silently for at most 5 minutes, then record `CI_PENDING <RUN_ID> <SHA>` in `docs/progress.md` and end cleanly if the run is still active. The next task resumes from that run result.

Never claim local Xcode verification from the user's Windows machine. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
