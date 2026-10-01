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
- **Gallery mode:** turn **Review gallery** on. Inspect all 66 fixed 390 × 844 frames and the reviewer-only `Trigger:` metadata above each frame. Repeat once in **Light** and once in **Dark**. Trigger metadata is review tooling and must stay outside the phone.
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
node --check design/prototype/app.js
```
