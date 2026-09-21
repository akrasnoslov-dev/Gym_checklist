# Task Spec — Scope automatic macOS CI to iOS-impacting changes

Date: 2026-09-21
Status: IN PROGRESS

## Goal

Finish PR #3 so expensive automatic macOS/Xcode CI runs only when a pull request changes files that can affect the iOS app build or automated iOS tests.

## Clarified requirement

The previous design-only exclusion is too narrow. Documentation, design prototypes, agent/workflow files, ordinary repository scripts, backend-only Firebase files, and similar process/infrastructure changes should not automatically spend a macOS runner.

Use an allowlist of iOS-impacting paths instead of continuously growing a list of exclusions.

## Scope

- `.github/workflows/ios-ci.yml` pull-request path trigger
- `scripts/verify_ios_ci_contract.ps1` contract coverage
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
  - `*.xcconfig` or `*.entitlements` files
- Documentation-only, design-only, agent/config/workflow-support, ordinary script, and backend-only changes do not automatically start macOS CI.
- Mixed PRs still run macOS whenever at least one iOS-impacting path is changed.
- Manual macOS workflow dispatch remains available.
- Linux CI contract protects the allowlist from accidental regression.

## RED evidence

PR #4 is process/configuration-only, but the old PR trigger started authoritative macOS run `35589341357`. That is the unwanted pre-fix behavior this task corrects.

A separate intentionally wasteful macOS RED run is not required because the real failing behavior already exists as evidence.

## Test strategy

Extend `scripts/verify_ios_ci_contract.ps1` to require:
- an allowlist-based `paths:` trigger;
- the known iOS-impacting roots/files;
- absence of `paths-ignore:`.

Then update the workflow until Linux CI is GREEN.

## Implementation plan

1. Replace the design-specific ignore rule with the iOS-impacting allowlist.
2. Extend the existing iOS CI contract.
3. Run PR Linux checks.
4. Confirm no new automatic macOS run is created for this process-only PR update.
5. Review the PR diff and update PR #3 description.

## Risks

The main risk of an allowlist is adding a new iOS build-relevant root later and forgetting to add it. The contract protects the current known build surfaces; future structural changes must update the allowlist when they introduce a new iOS-impacting path.

## DB/schema/data impact

None.
