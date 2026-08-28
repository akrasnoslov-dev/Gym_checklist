# Codex Instructions — compatibility reference

`AGENTS.md` is the only execution/scheduling rulebook. This file is intentionally small and is **not** mandatory startup reading.

Useful repository checks on Windows/Linux:

```text
git status -sb
git diff --check
pwsh -File scripts/verify_security_hygiene.ps1
pwsh -File scripts/verify_account_deletion_contract.ps1
pwsh -File scripts/verify_firestore_rules.ps1
pwsh -File scripts/verify_offline_contract.ps1
pwsh -File scripts/verify_google_signin_configuration_contract.ps1
```

Authoritative iOS verification runs in `.github/workflows/ios-ci.yml` on macOS/Xcode.

Current pre-payment strategy:
- use exact filtered `unit`/`ui` diagnostics while investigating a known failure;
- for a candidate fix with a known blocker test, use `verification_scope=candidate`: GitHub builds once, runs the exact blocker test, then automatically runs the full suite only if that test passes;
- do not insert a separate smoke run between focused and final verification;
- a green `candidate` run is the required green full evidence for that exact SHA;
- use standalone `smoke` or `full` only when the candidate path does not fit the situation.

The Program week/date-selector failure is not eligible for the old harness-flake waiver because the user reproduced it on a physical iPhone.

For one known failing test, use the optional `test_filter` workflow input instead of rerunning the entire target during diagnosis. Example:

```powershell
gh workflow run ios-ci.yml --repo akrasnoslov-dev/Gym_checklist --ref dev -f verification_scope=ui -f "test_filter=GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs"
```

Do not spend Codex runtime waiting for CI. After dispatch, record run ID + scope + SHA in `docs/progress.md`. Continue only independent work that cannot invalidate the tested candidate; otherwise end the task immediately. On the next task, check the recorded run once. If it is still running, end quickly instead of polling.

Use only zero-cost services during current acceptance. Firebase Spark is allowed; Firebase Blaze/billing and paid Apple distribution are not. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
