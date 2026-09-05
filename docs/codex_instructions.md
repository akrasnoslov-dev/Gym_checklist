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
- macOS/Xcode CI is a scarce authoritative gate, not the normal development loop;
- do not dispatch it after each fix, commit, or individual finding;
- a hardening task repeats local audit/fix/test cycles until the active MVP scope is locally exhausted; a later finding does not require a new task;
- any task that changes production/test/project code must finish the whole batch, commit/push, mark `REMOTE_GATE_READY_FOR_FINAL_AUDIT <SHA>`, and stop without macOS;
- macOS may be dispatched only from a separate fresh final-audit task on that exact SHA;
- if that audit finds anything requiring production/test/project code changes, it becomes the hardening task: make and re-audit the full batch in that same task, then mark the new SHA ready for final audit without macOS;
- only a clean final-audit pass with no production/test/project code changes may mark `REMOTE_GATE_APPROVED <SHA>` and dispatch one candidate/full gate;
- any red candidate revokes approval and restarts this two-pass process;
- first finish all implementation, migration, test maintenance, UX work, self-review, documentation, and available static/security/offline checks that can be completed without Xcode;
- use focused `unit`/`ui` only for a genuinely isolated remaining blocker;
- use `verification_scope=candidate` only for an implementation-complete candidate checkpoint; GitHub builds once, runs the exact blocker regression, then automatically runs the full suite if that passes;
- after a failed run, batch all related fixes and review the same defect class across the repository before another dispatch;
- do not insert a separate smoke run between focused and final verification;
- a green `candidate` run is the required green full evidence for that exact SHA;
- use standalone `smoke` or `full` only when explicitly justified.

The Program week/date-selector failure is not eligible for the old harness-flake waiver because the user reproduced it on a physical iPhone.

For one known failing test, use the optional `test_filter` workflow input instead of rerunning the entire target during diagnosis. Example:

```powershell
gh workflow run ios-ci.yml --repo akrasnoslov-dev/Gym_checklist --ref dev -f verification_scope=ui -f "test_filter=GymChecklistUITests/GymChecklistUITests/testAppLaunchesOnTodayAndNavigatesAllTabs"
```

Do not spend Codex runtime merely waiting for CI. After dispatch, record run ID + scope + SHA in `docs/progress.md`. Continue any useful work that cannot invalidate the tested candidate. End only when no such work remains. On the next task, inspect the recorded run once; if it is still running, scan for useful non-invalidating work before ending, and never enter a polling loop.

Use only zero-cost services during current acceptance. Firebase Spark is allowed; Firebase Blaze/billing and paid Apple distribution are not. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
