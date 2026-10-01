# Phase 5B Prototype Stabilization

## Goal

Freeze the existing Phase 5B HTML/CSS prototype structure, classify its review entries, and add deterministic Linux browser regression protection before any further visual bug fix.

## Clarified requirements

- Work only in existing PR #5 and branch `codex/phase-5b-full-uiux-candidate`.
- The current candidate is a regression baseline, not approved design.
- Do not redesign or fix the next visual-feedback batch.
- Do not change production SwiftUI, the Xcode project, iOS tests, or macOS CI.
- The current 66 review entries may be consolidated but must never increase silently.
- Playwright/Chromium on Linux is preferred for deterministic Light/Dark screenshot and layout regression coverage.

## Scope

- Canonical prototype review registry and its derived screen/state matrix.
- Gallery hierarchy and review-only metadata.
- Static stabilization contracts.
- Browser visual/layout tests, committed baselines, and failure artifacts.
- Linux-only, prototype-path-gated CI.
- Prototype/task/progress documentation for the freeze and future Phase 7 bug-fix contract.

## Out of scope

- Product features, UX concepts, app screens, new user-visible states, or visual redesign.
- Existing visual bug fixes.
- Production SwiftUI, Xcode project, iOS tests, backend, persistence, or macOS CI.
- PR merge.

## Acceptance criteria

1. Every review entry has exactly one classification: canonical surface, state/variant, overlay/sheet/menu/confirmation, or QA-only.
2. A derived matrix records parent, trigger, visibility, review-only status, Light/Dark coverage, and snapshot ID.
3. The frozen registry total is at most 66 and cannot grow or gain an unclassified entry silently.
4. Gallery and normal mode use the same canonical registry and preserve normal interaction paths.
5. Playwright verifies committed Light/Dark baselines at 390 x 844 with deterministic data, timezone, locale, scale, scroll position, local assets, and disabled motion.
6. Verify and update operations are separate; CI only verifies.
7. Failures retain expected, actual, and diff evidence and CI uploads it.
8. Browser assertions cover overflow, phone bounds, tab overlap, overlays, reviewer metadata, fixed dimensions, reachability, and registry parity.
9. Linux visual CI is path-gated to prototype and its test/workflow configuration.
10. Future Phase 7 work is bug-fix only and requires explicit approval before adding any state or review route.

## Affected areas

- `design/prototype/`
- `.github/workflows/`
- `docs/task_specs/2026-10-01-phase-5b-stabilization.md`
- `docs/ui_redesign_plan.md`
- `docs/progress.md`

## Risks and edge cases

- Screenshot baselines can encode current defects; documentation must state they are regression anchors only.
- Browser and host font differences can create noise; CI and local commands must pin browser/runtime behavior as far as practical.
- Consolidation must remove only review duplication and preserve actual interactive paths.
- Shared CSS changes can affect many states; dependency metadata must select all consumers automatically.

## Data/schema impact

None.

## Test strategy

- Add static contracts first and record their failure against the current candidate.
- Validate classification completeness, frozen count, derived matrix freshness, local-only assets, and verify/update command separation.
- Add Playwright screenshot and structural/layout coverage for the full frozen matrix in Light and Dark.
- Run JavaScript syntax, prototype contracts, browser verification, relevant Linux policy contracts, and `git diff --check`.
- Run `design_prototype_guardian`, `ios_ux_guardian`, `product_spec_guardian`, and `test_ci_agent` reviews.

## Implementation plan

1. Add and run RED stabilization contracts.
2. Make one registry canonical and derive Gallery, the matrix, static checks, and browser cases from it.
3. Consolidate only duplicate Gallery convenience entries.
4. Add deterministic Playwright configuration, layout assertions, baselines, and explicit verify/update commands.
5. Add path-gated Linux visual CI and failure artifact upload.
6. Document the freeze, snapshot policy, future bug-fix contract, evidence, and known existing issues.
7. Run GREEN verification and specialist reviews; resolve blocking findings without expanding scope.

The executable freeze contract hard-codes the approved post-consolidation total of 64. Changing that contract is an explicit review event and requires prior user scope approval; updating registry metadata alone cannot permit growth.

## RED evidence

- Against `cedc11461e3c1253fb25e6a3f05b89e9a94e1a8c`, `node design/prototype/verify-stabilization.mjs` failed because the canonical registry, matrix, Playwright configuration/spec, and package commands did not exist and classification/snapshot metadata was absent.
- The first browser attempt also proved the environment contract was real: Playwright could not launch before its pinned Chromium was installed. After installation, the first focused layout run caught an incorrect test selector before any baseline was accepted.
- The first Linux CI verification correctly rejected all 128 provisional Windows-rendered screenshots because host font rasterization differed (the first reported image differed by 3%). The actual-image failure artifact was used to seed Linux-authoritative baselines; renderer-specific `linux` and `win32` sets keep the threshold strict and the local VERIFY command useful without treating drift as design approval.

## GREEN evidence

- `npm test` in `design/prototype/` passed all static contracts and 132 pinned-Chromium tests: 128 Light/Dark route snapshots plus four structural, reachability, and interaction suites.
- The freeze contract requires 64 Light and 64 Dark images for both supported renderers; Linux is authoritative in CI and Windows supports local review.
- The browser suite executes every interaction-backed registry transition, verifies Gallery/normal parity and shared-component consumers, and enforces the 390 x 844 shell, overflow, tab, overlay, metadata, and usable-control contracts.
- `npm run visual:update` refuses an unscoped update, and the update helper refuses more than eight explicitly named routes.
- `git diff --check` and the repository agentic-workflow, security-hygiene, release-workflow, and iOS-CI policy contracts passed.
- `design_prototype_guardian`, `ios_ux_guardian`, `product_spec_guardian`, `test_ci_agent`, and independent code review all returned GREEN after blocking findings were resolved.
- `graphify update .` was attempted after the changes but the installed launcher failed to canonicalize its script path; the bundled Python runtime also has no `graphify` module. Graph artifacts therefore remain unchanged, and this toolchain limitation is recorded rather than bypassed.

## Consolidation record

- Before: 66 review entries.
- After: 64 review entries.
- Removed `settings-appearance` and `settings-unit` as duplicate Gallery-only convenience entries. The Appearance and Weight unit controls remain visible and interactive on `settings-main`, so no user-visible state or normal path was removed.

## Known unresolved review issue

- `state-disabled` currently reuses the existing destructive account-confirmation rendering rather than showing a visibly distinct disabled-control treatment. It is intentionally captured unchanged for a later one-issue Phase 7 fix.
