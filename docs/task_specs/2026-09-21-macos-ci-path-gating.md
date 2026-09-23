# Task Spec — Scope automatic macOS CI to iOS-impacting changes

Date: 2026-09-21
Status: DONE

## Goal

Finish PR #3 so expensive automatic macOS/Xcode CI runs only when a pull request changes files that can affect the iOS app build or automated iOS tests, and routine code PRs use the smoke suite rather than the complete suite.

## Clarified requirement

The previous design-only exclusion is too narrow. Documentation, design prototypes, agent/workflow files, ordinary repository scripts, backend-only Firebase files, and similar process/infrastructure changes should not automatically spend a macOS runner.

Use an allowlist of iOS-impacting paths instead of continuously growing a list of exclusions.

## Scope

- `.github/workflows/ios-ci.yml` pull-request path trigger
- `scripts/verify_ios_ci_contract.ps1` contract coverage
- automatic pull-request scope selection, concurrency, and SwiftPM source-cache identity
- PR #3 metadata and verification evidence

## Out of scope

- App behavior
- Swift/SwiftUI code
- Firebase behavior
- Test content
- Manual `workflow_dispatch` behavior
- Release workflows

## Acceptance criteria

- Automatic macOS CI runs for changes under:
  - `GymChecklist/**`
  - `GymChecklistTests/**`
  - `GymChecklistUITests/**`
  - `GymChecklist.xcodeproj/**`
  - root Swift package manifests if introduced
  - `*.xcconfig`, `*.entitlements`, or app-owned `GymChecklist/**/*.plist` files
- Documentation-only, design-only, agent/config/workflow-support, ordinary script, and backend-only changes do not automatically start macOS CI.
- Mixed PRs still run macOS whenever at least one iOS-impacting path is changed.
- Automatic iOS-impacting pull-request runs use `smoke`; they are not authoritative final verification.
- Manual macOS workflow dispatch remains available with `build`, `unit`, `ui`, `smoke`, `full`, and `candidate`.
- Manual `full` and `candidate` retain exact-SHA candidate validation, focused regression, build-once execution, and the complete candidate suite.
- Obsolete pull-request runs cancel, while manually dispatched diagnostic and authoritative runs do not.
- Linux CI contract protects the allowlist from accidental regression.

## RED evidence

PR #4 is process/configuration-only, but the old PR trigger started authoritative macOS run `35589341357`. That is the unwanted pre-fix behavior this task corrects.

A separate intentionally wasteful macOS RED run is not required because the real failing behavior already exists as evidence.

## Test strategy

Extend `scripts/verify_ios_ci_contract.ps1` to require:
- an allowlist-based `paths:` trigger;
- the known iOS-impacting roots/files;
- absence of `paths-ignore:`.
- automatic pull-request `smoke` selection, preserved manual scopes, concurrency semantics, and cache-key dependency/toolchain inputs.

Then update the workflow until Linux CI is GREEN.

## Implementation plan

1. Preserve the iOS-impacting allowlist after auditing current build/test surfaces.
2. Make automatic iOS-impacting pull-request runs select `smoke` explicitly.
3. Extend the existing iOS CI contract for path gating, routine scope, manual scope, concurrency, and cache identity.
4. Run the directly affected contract and Linux validation.
5. Confirm no new automatic macOS run is created for this process-only update and review the PR diff.

## Risks

The main risk of an allowlist is adding a new iOS build-relevant root later and forgetting to add it. The contract protects the current known build surfaces; future structural changes must update the allowlist when they introduce a new iOS-impacting path.

## DB/schema/data impact

None.


## Earlier GREEN evidence

Linux run `35591298735` passed after the allowlist and contract update.

The updated PR head `f414ae03721aa9bd5e1526d001d20481474cee17` has only the Linux workflow run. No automatic macOS/Xcode run was created for this process-only change.

This is the intended post-fix behavior.


## Current completion verification

- Local CI contracts, JavaScript syntax, and whitespace checks are green.
- Linux run `35870019826` passed on final commit `2be586ca73f0fdc1726adc7c1aa5247e372f3e8f`; no automatic macOS run was created for this process-only change.

## Completion evidence

- Automatic iOS-impacting PRs now resolve to `smoke`; manual `full` and `candidate` behavior is structurally preserved.
- SwiftPM source caching now keys from the current Xcode version and Xcode project dependency declarations. DerivedData remains uncached.
- Local contracts passed: agentic workflow, security hygiene, account deletion, Google Sign-In configuration, release workflow, and iOS CI. `node --check functions/index.js` and `git diff --check` also passed.
- GitHub Actions Linux run `35870019826` passed for final commit `2be586ca73f0fdc1726adc7c1aa5247e372f3e8f`; the only automatic run was Linux.
- Independent review found and the follow-up commit fixed the broad plist glob and weak cache/trigger contract checks.