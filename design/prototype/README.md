# Gym Checklist — Phase 5A Minimal Grouped foundation

The user selected **Minimal Grouped** as the Phase 5A visual direction. This is now the canonical Phase 5 foundation: one Today control screen in an active, partially completed state. It is a static HTML/CSS/JavaScript prototype, not production SwiftUI.

## Open locally

Open [index.html](index.html) directly in a modern desktop browser. No install or build step is required.

Alternatively, serve the repository root with any local static server and open `/design/prototype/`.

## Inspect

- Use **Light** and **Dark** to switch the semantic theme.
- Tap any set row to inspect its complete/undo state. This only demonstrates the one-tap interaction; it does not implement application logic.
- The shell is 390 × 844 px, representing an iPhone-sized viewport. Resize the browser below 760 px to inspect the responsive preview framing.

## Included in Phase 5A

- semantic Light/Dark tokens, typography, spacing, radii, surfaces, borders and state treatment;
- reusable exercise-group and set-row templates/styles;
- direct exercise headings plus one quiet grouped set surface, with no outer exercise card or nested-card structure;
- Today hierarchy, date context, partially completed workout data, and tab-bar intent;
- a deliberately restrained green/lime/mint completion and selection treatment.

Rejected Soft Grouped and Native Flat variants have been removed. Light and Dark remain supported, and production SwiftUI has not been changed.

## Intentionally not included

No other app screen, workflow, editor, menu, completion overlay, backend behavior, or production SwiftUI implementation is included. System navigation and tab-bar styling communicate intent only; native SwiftUI remains responsible for actual system-owned controls.
