# Gym Checklist — Phase 5A prototype

This is the Phase 5A comparison of one control screen: **Today / active workout / partially completed**. It is a static HTML/CSS/JavaScript prototype, not production SwiftUI.

## Open locally

Open [index.html](index.html) directly in a modern desktop browser. No install or build step is required.

Alternatively, serve the repository root with any local static server and open `/design/prototype/`.

## Inspect

- Use the **A / B / C** controls above the phone shell to compare the same Today content in three visual treatments. Variant switches change CSS only; they do not reset the shared workout state.
- Use **Light** and **Dark** to switch the semantic theme.
- Tap any set row to inspect its complete/undo state. This only demonstrates the one-tap interaction; it does not implement application logic.
- The shell is 390 × 844 px, representing an iPhone-sized viewport. Resize the browser below 760 px to inspect the responsive preview framing.

## Included in Phase 5A

- semantic Light/Dark tokens, typography, spacing, radii, surfaces, borders and state treatment;
- reusable exercise-group and set-row templates/styles;
- **Variant A — Soft Grouped:** subtle outer exercise card with a quieter internal set group;
- **Variant B — Native Flat:** direct exercise headings and separator-led set rows without cards;
- **Variant C — Minimal Grouped:** direct exercise headings plus one quiet grouped set surface;
- identical Today hierarchy, date context, partially completed workout data, and tab-bar intent across every variant;
- a deliberately restrained green/lime/mint completion and selection treatment.

## Intentionally not included

No other app screen, workflow, editor, menu, completion overlay, backend behavior, or production SwiftUI implementation is included. System navigation and tab-bar styling communicate intent only; native SwiftUI remains responsible for actual system-owned controls.
