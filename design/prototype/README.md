# Gym Checklist — Phase 5A prototype

This is the Phase 5A design foundation and its single control screen: **Today / active workout / partially completed**. It is a static HTML/CSS/JavaScript prototype, not production SwiftUI.

## Open locally

Open [index.html](index.html) directly in a modern desktop browser. No install or build step is required.

Alternatively, serve the repository root with any local static server and open `/design/prototype/`.

## Inspect

- Use **Light** and **Dark** above the phone shell to switch the semantic theme.
- Tap any set row to inspect its complete/undo state. This only demonstrates the one-tap interaction; it does not implement application logic.
- The shell is 390 × 844 px, representing an iPhone-sized viewport. Resize the browser below 760 px to inspect the responsive preview framing.

## Included in Phase 5A

- semantic Light/Dark tokens, typography, spacing, radii, surfaces, borders and state treatment;
- reusable exercise-group and set-row templates/styles;
- Today hierarchy, date context, exercise groups, partially completed rows, and tab-bar intent;
- a deliberately restrained green/lime/mint completion and selection treatment.

## Intentionally not included

No other app screen, workflow, editor, menu, completion overlay, backend behavior, or production SwiftUI implementation is included. System navigation and tab-bar styling communicate intent only; native SwiftUI remains responsible for actual system-owned controls.
