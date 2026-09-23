# Gym Checklist — Phase 5B Minimal Grouped candidate

The user selected **Minimal Grouped** in Phase 5A. This Phase 5B prototype expands that approved foundation into the complete MVP visual candidate. It is deterministic HTML/CSS/JavaScript, not production SwiftUI or product logic.

## Open locally

Open [index.html](index.html) directly in a modern desktop browser. No install or build step is required.

Alternatively, serve the repository root with any local static server and open `/design/prototype/`.

## Inspect

- Use the **Screen or state** picker for every required surface and representative state; the shortcut chips jump to common review points.
- Use **Light** and **Dark** to switch the semantic theme. Each route uses the same semantic token set.
- Tap a Today set row to inspect its complete/undo state. This only demonstrates the one-tap interaction; it does not implement application logic.
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
