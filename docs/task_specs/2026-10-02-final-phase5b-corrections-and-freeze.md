# Final Phase 5B corrections and Phase 8 freeze

## Goal
Resolve the five remaining user-reported UI issues on the stabilized Phase 5B prototype, preserve the frozen 64-entry registry, then freeze the corrected design for Phase 9 implementation.

## Clarified requirements
- Final design delta only: compact overlay scroll locking, Program calendar state symbols, Program set-row edit semantics, focused reorder UI, and leading-aligned authentication fields.
- No new routes, states, product features, or unrelated redesign.
- Use existing visual-regression protection; only explicitly affected baselines may change.
- After these corrections are green, the user has authorized Phase 8 design freeze and immediate Phase 9 SwiftUI implementation in a separate branch/PR.
- PR #5 remains the design/freeze PR and must not be merged automatically.

## Scope
- `design/prototype/` implementation/tests/baselines for the five fixes.
- Phase 5/8 design documentation and implementation mapping.
- No production SwiftUI changes in this branch.

## Out of scope
- New UX states/features.
- Backend, schema, persistence, or authentication behavior changes.
- Production SwiftUI/Xcode/iOS-test changes on PR #5.
- Manual authoritative macOS candidate/full dispatch.

## Acceptance criteria
1. Registry remains exactly 64 entries.
2. Compact menus/confirmations do not scroll themselves or the underlying app content.
3. Week/Month use symbolic workout-state indicators rather than state initials.
4. Program set rows no longer show `Edit`/`Edit plan`/`Edit actual` trailing copy or unexplained grey completed text.
5. Reorder is a focused native-intent list with one scope and drag handles, not a mixed debug list.
6. Auth Email/Password fields are visually leading-aligned.
7. Only affected visual baselines change and the full Light/Dark suite is green.
8. Required specialist reviews are green.
9. Exact corrected design SHA is recorded as Phase 8 APPROVED/FROZEN.

## Test strategy
- Extend prototype contract first to express the five corrections; confirm RED against the stabilized candidate.
- Run targeted Playwright/browser assertions for scroll lock, semantic symbols, reorder scope, Program row copy, and auth alignment.
- Update only affected snapshot IDs, in batches of at most eight.
- Run full visual regression, stabilization contract, syntax, diff check, and relevant static/Linux checks.

## Implementation plan
1. Add failing contracts/tests.
2. Make minimal shared prototype fixes without changing registry.
3. Update only intended baselines and rerun the full suite.
4. Run required specialist reviews.
5. Freeze the exact corrected design and document Phase 9 native mapping.
6. Stop design work; production implementation proceeds on a separate branch/worktree.


## Validation evidence — correction pass

- RED: the new final-correction contract failed against the stabilized candidate because it still contained `REORDER MODE` and lacked the focused reorder/scroll-lock markers.
- RED: the new browser semantics check failed before the implementation changes.
- GREEN (Windows/system Chrome): prototype contract and stabilization contract pass with exactly 64 frozen entries.
- GREEN (Windows/system Chrome): full Playwright suite passes after explicit baseline updates for affected states; unaffected states remained unchanged.
- Affected review IDs with intentional visual changes: `program-week`, `program-week-prev`, `program-week-next`, `program-edit`, `program-history-week-prev`, `program-edit-week-next`, `program-add-set`, `program-add-timed-set`, `program-reorder`, `program-history`, `auth-sign-in`, `auth-sign-up`, `auth-reset`.
- Shared compact-overlay scroll locking is behavior-only for the existing overlay routes; no new registry ID was added.
- GREEN (Linux): Linux checks run `37013418934` and Prototype visual regression run `37013419866` pass on frozen visual source `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- Phase 8 decision: the user explicitly authorized immediate freeze after these corrections and direct Phase 9 implementation. Frozen design source is `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`.
- Required design-prototype, iOS-UX, and product-spec reviews found no blocking issue after the focused reorder correction. The test/CI evidence is the green local 133-test suite plus the recorded Linux checks and prototype-visual-regression runs.
