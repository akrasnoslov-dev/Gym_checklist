# Phase 5B — Full UI/UX Candidate

## Goal

Expand the approved Minimal Grouped Phase 5A HTML/CSS foundation into a deterministic, navigable Phase 5B design candidate for every approved MVP surface and representative state.

## Clarified requirements

- The approved Phase 5A direction, Minimal Grouped, is the visual foundation.
- Authentication represents email/password and Google only; do not add Sign in with Apple.
- The prototype is design-only: no product/backend logic and no production SwiftUI, Xcode, or iOS-test changes.
- It must cover the user-requested Today, Program, supporting workout, Settings, authentication, state, and Light/Dark surfaces.

## Scope

- `design/prototype/` HTML, CSS, JavaScript, and its local review guide.
- This task record and the relevant Phase 5/progress documentation.
- A deterministic static validation contract for required prototype routes and states.

## Out of scope

- SwiftUI, production behavior, backend, CI workflow, Xcode project, and iOS-test changes.
- Phase 1 reconstruction and historical mockups as design inputs.
- New product features, dashboards, analytics, timers, gamification, or media.

## Acceptance criteria

1. Prototype remains locally openable without installation or external tooling.
2. Every required MVP surface/state is selectable through simple deterministic controls.
3. Semantic reusable tokens/components preserve Minimal Grouped and Light/Dark behavior.
4. Today remains quiet, direct, and supports a one-tap set completion demonstration.
5. Native iOS system-owned structures are annotated/represented as intent rather than pixel-perfect web chrome.
6. Accessibility-sensitive states expose non-color state, labels, and practical target sizing.
7. No iOS-impacting paths change.

## Affected areas

- `design/prototype/`
- `docs/task_specs/2026-09-23-phase-5b-full-uiux-candidate.md`
- `docs/ui_redesign_plan.md`
- `docs/progress.md`

## Risks and edge cases

- A full candidate can become a screen-specific CSS collection; use shared tokens and render templates.
- System controls must communicate native intent without recreating a precise iOS version in HTML.
- Program may be denser than Today without introducing dashboard patterns.
- Offline must remain secondary when cached Today content is usable.

## Data, test, and validation strategy

- No data/schema impact.
- Before prototype expansion, add a static validation contract for the required state registry and run it against the Phase 5A foundation to establish RED evidence.
- After implementation, run the contract, JavaScript syntax checks, whitespace/diff checks, and relevant Linux policy contracts only. macOS/Xcode verification is not applicable.

## Implementation plan

1. Define the validation registry/contract and record its expected initial failure.
2. Expand the app-owned component vocabulary and reusable rendered screen data.
3. Add deterministic navigation and state controls for all required representative surfaces.
4. Update local review documentation and Phase 5/progress records.
5. Run validation, inspect the complete diff, obtain required specialist reviews, resolve blockers, then prepare a focused PR to `dev`.

## Validation evidence

- RED: the initial 29-route version of `node design/prototype/verify-prototype.mjs` failed against the Phase 5A foundation because its required route IDs and the native-intent marker were absent. The final contract adds the explicit actual-editor variant.
- GREEN: `node design/prototype/verify-prototype.mjs` passes with all 30 required routes and semantic markers.
- GREEN: `node --check design/prototype/app.js` and `node --check design/prototype/verify-prototype.mjs` pass.
- GREEN: `git diff --check` passes.
- GREEN: repository Linux-contract equivalents pass: security hygiene, account deletion, Google Sign-In configuration, release workflow, iOS CI policy, and agentic workflow.
- Not applicable: Swift/Xcode tests and macOS verification. The changed paths are only design prototype and documentation, outside the iOS CI path allowlist; no macOS CI was dispatched.

## Review status

- Initial design-prototype review found Program remove/reorder actions were only implied. Resolved with explicit native-intent exercise and set menus, reorder affordances, destructive actions, and object-scoped confirmation intent. Re-review: approved.
- Initial iOS UX review found calendar state semantics and 44 pt target gaps. Resolved with distinct state symbols and specific accessible labels in Week/Month plus 44 pt segmented, calendar-navigation, and Month-cell targets. Re-review: approved.
- Initial product-spec review found skipped content remained visible, planned-set editing was omitted, Program mutation actions were implied, and calendar states were generic. Resolved by filtering skipped content while retaining restore, adding planned/actual editor variants, adding Program menus, and adding named calendar states. Re-review: approved.
- `graphify update .` was attempted as required after code changes, but the local Graphify launcher is misconfigured (it invokes a missing `C:\\Users\\Andrei\\.local\\bin\\graphify` script). No graph output was changed.
