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
- use exact filtered `unit`/`ui` diagnostics for a known failure;
- use `smoke` for iterative coherent checkpoints;
- require a green `full` run on the **exact final candidate SHA** before physical-iPhone product acceptance;
- if `full` fails after a code/test fix, rerun it for the new candidate until the final authoritative result is green.

The Program week/date-selector failure is not eligible for the old harness-flake waiver because the user reproduced it on a physical iPhone.

For one known failing test, use the optional `test_filter` workflow input instead of rerunning the entire target during diagnosis. Example:

```powershell
gh workflow run ios-ci.yml --repo akrasnoslov-dev/Gym_checklist --ref dev -f verification_scope=ui -f "test_filter=GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs"
```

Pending CI alone is **not** a voluntary stopping condition. Continue independent work; if none exists, poll/wait reasonably and process the terminal result. Do not end the task merely because CI is still running.

Use only zero-cost services during current acceptance. Firebase Spark is allowed; Firebase Blaze/billing and paid Apple distribution are not. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
