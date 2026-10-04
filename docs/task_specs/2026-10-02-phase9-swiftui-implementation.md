# Phase 9 SwiftUI implementation

## Goal
Implement the approved Phase 8 canonical SwiftUI hierarchy from frozen visual source `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`, preserving existing product and data behavior.

## Scope
- Native SwiftUI presentation, accessibility, and visual hierarchy for Today, Program, workout supporting flows, Settings, and authentication.
- Reuse existing view models, repositories, domain rules, and system controls.
- Keep the existing Phase 9 branch and PR #6; merge current `dev` before implementation without discarding work.

## Non-goals
- No new product features, routes, data schema, backend changes, browser prototype changes, or manual macOS candidate/full CI.
- The 64 prototype review states are not 64 production screens.

## Current checkpoint
- Phase 8 base: `64fef1c3a6cc22ae58950e34e26c0b2b7c869a58`; frozen visual source remains `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- Existing Phase 9 commits provide semantic tokens, leading-aligned authentication fields, canonical calendar symbols, and focused native exercise/set reorder flows.
- `dev` was merged through `3f2c28c`; the current Phase 9 implementation now includes the frozen completion artwork variants in the iOS asset catalog, deterministic per-workout selection, and a unit/UI regression contract for that presentation.
- Existing Today editing remains native and keeps its planned-vs-actual semantics; the weight editor uses a native labelled unit row rather than encoding the unit inside the text-field placeholder.

## Acceptance and validation
- Preserve Today’s one-tap completion/undo and planned-vs-actual semantics.
- Use native SwiftUI controls for menus, sheets, confirmations, date pickers, lists, forms, and reordering.
- Maintain VoiceOver semantics, Dynamic Type resilience, 44 pt practical targets, Light/Dark semantic colors, and non-color-only state.
- Run focused tests where behavior changes, the available static/security/offline/identity/CI contracts, diff checks, and required specialist review before Pass A handoff.

## Batch plan
1. Audit shared tokens and existing native navigation.
2. Complete Today and completion feedback.
3. Complete Program calendar, plan/history rows, actions, and reorder.
4. Audit exercise picker, custom exercise, copy, and repeat flows.
5. Audit Settings, Profile, Body weight, and account deletion presentation.
6. Audit authentication and representative support states.
7. Harden accessibility and consistency, then record the exact Pass A remote-gate SHA and stop.

## Pass A evidence
- Focused regression coverage: `WorkoutCompletionTriggerTests.testCompletionContentUsesFrozenArtworkAndStableSelection` verifies the three frozen asset/copy variants and stable UUID selection; `TodayCompletionUITests` accepts each approved visible title. The asset-catalog contract validates every referenced SVG path. Today content is inaccessible and non-hit-testable while the modal popup is presented.
- Static checks GREEN on Windows: `git diff --check`; completion asset-catalog JSON/path contract; `node --check functions/index.js`; agentic workflow, security hygiene, account deletion, Firestore owner isolation, offline cache/reconnect, Google Sign-In configuration, release workflow, and iOS CI contracts.
- Xcode/xcodebuild and XCTest/UI test execution are unavailable on this Windows host. Per the two-pass policy, no macOS smoke/candidate/full workflow is dispatched in Pass A.
- Independent review corrected reorder UI-test selectors to target the labels intentionally exposed by the focused native reorder lists.
