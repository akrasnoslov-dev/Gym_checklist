# Gym Checklist — Phase 5B Minimal Grouped candidate

The user selected **Minimal Grouped** in Phase 5A. This Phase 5B prototype expands that approved foundation into the complete MVP visual candidate. It is deterministic HTML/CSS/JavaScript, not production SwiftUI or product logic.

## Open locally

Open [index.html](index.html) directly in a modern desktop browser. No install or build step is required.

For browser review from the repository root:

```powershell
npx serve . -l 4173
```

Then open `http://127.0.0.1:4173/design/prototype/`.

## Inspect

- **Normal mode:** leave **Review gallery** off. Use the **Screen or state** picker or the shortcut chips, then exercise the in-phone paths: tap a Today set to complete/undo it; long-press or context-click a set to edit it; use Program date cells and each `•••` action; open Copy/Repeat calendars; expand skipped exercises; search and scroll the exercise picker; and inspect Settings, Profile, and Body weight dismissal controls.
- **Gallery mode:** turn **Review gallery** on. Inspect all 64 frozen 390 × 844 review entries and the reviewer-only `Trigger:` metadata above each frame. Entries are grouped by their real parent surface and classified as surface, state, or overlay. Repeat once in **Light** and once in **Dark**. Trigger metadata is review tooling and must stay outside the phone.
- Use **Light** and **Dark** to switch the semantic theme. Each route uses the same semantic token set.
- A normal tap or keyboard activation on a Today set completes/undoes it. Long-press, context-click, the Context Menu key, or Shift+Enter opens the appropriate planned/actual editor.
- The shell is 390 × 844 px, representing an iPhone-sized viewport. Resize below 760 px to inspect the responsive preview framing.
- Labels reading **System intent** distinguish native SwiftUI-owned structures (navigation, sheets, menus, forms, pickers, alerts and Google control) from the app-owned visual system.

## Included in Phase 5B

- all Today execution, empty, skip/restore, editor, completion, loading and cached-offline states;
- Program Week/Month, selected-date editing, ordering/destructive intent and historical actual editing;
- exercise picker/custom exercise and copy/repeat sheets;
- grouped Settings, Profile, body-weight, preferences and account/destructive states;
- email/password and Google authentication (no Apple Sign-in); and
- reusable semantic tokens and component styles for rows, groups, calendars, forms, sheets, overlays, errors and disabled actions in Light/Dark.

## Intentionally not included

No backend behavior, product feature, production SwiftUI implementation, dashboard, statistics, timer, gamification, media, or Phase 1/historical-mockup input. System controls communicate intended structure only; native SwiftUI remains responsible for actual system-owned rendering and behavior.

## Static validation

From the repository root, run:

```text
node design/prototype/verify-prototype.mjs
node design/prototype/verify-stabilization.mjs
node design/prototype/generate-matrix.mjs --check
node --check design/prototype/app.js
```

## Frozen registry and matrix

`registry.js` is the only canonical review registry. Normal mode, Gallery, static contracts, the generated [screen/state matrix](screen-state-matrix.md), and Playwright cases all derive from it.

The stabilization pass reduced the 66-entry Gallery to 64 by removing only `settings-appearance` and `settings-unit`. Both were duplicate Gallery convenience entries for inline controls already visible and interactive on `settings-main`; no product state or trigger path was removed.

Until the user explicitly approves a scope change:

- no new canonical screens, UX states, review routes, prototype-only flows, or redesign-experiment components;
- every future issue must map to an existing registry ID before implementation; and
- if a fix truly needs a new state, stop and ask the user instead of extending the registry.

## Visual regression

Install once from `design/prototype/`:

```text
npm ci
npx playwright install chromium
```

VERIFY compares current output with committed baselines and never updates them:

```text
npm run visual:verify
```

UPDATE requires an explicit comma-separated affected-state list and refuses more than eight IDs in one operation:

```text
npm run visual:update -- --routes today-partial,program-week
```

Baselines are in `tests/snapshots/{linux,win32}/{light,dark}/`. Linux is the CI authority; the Windows set keeps the same VERIFY command useful in the repository's primary local workspace. On failure, Playwright writes actual screenshots, visual diffs, traces, and context under `test-results/`; CI uploads those plus the expected baselines and HTML report. CI also publishes a small `prototype-visual-linux-actuals-*` artifact containing only Linux-rendered actual images for focused baseline triage; it never changes the repository.

These images are regression anchors, not user design approval. Never respond to broad diffs by updating every image. For each Phase 7 bug fix: list affected IDs first, reproduce, make the smallest reasonable change, run the full verification suite, inspect changed images, update only approved IDs, then rerun the full suite. Unaffected baselines must remain identical. Shared CSS automatically exercises every registered consumer because the full frozen matrix runs on each relevant prototype change.

## Phase 7 bug-fix contract

- Bug-fix only; one issue or tightly coupled issue group per cycle.
- No new route/state without explicit user approval.
- Record the affected registry IDs before implementation.
- Keep the diff minimal; no unrelated refactor or automatic design improvement.
- Run visual regression before and after; update only intended baselines.
- Handoff only with the complete contract and browser suite GREEN.

## Known unresolved baseline issues

- `state-disabled` currently renders the existing destructive account-confirmation presentation rather than a visibly distinct disabled-control treatment. This stabilization pass records the mismatch and intentionally does not redesign or fix it.
