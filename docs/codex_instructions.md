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

Never claim local Xcode verification from the user's Windows machine. Never print or commit secrets, signing material, service-account credentials, auth tokens, or `GoogleService-Info.plist`.
