# Phase 9 — Frozen Design to SwiftUI Mapping

**Frozen design source:** `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`
**Prototype registry:** 64 review entries = 10 canonical surfaces, 26 states, 28 overlays.
**Important:** review entries are not separate production screens. Phase 9 implements the canonical app hierarchy with native SwiftUI states and presentations.

## Native-system substitutions

Use native iOS 17+ controls whenever they express the frozen intent:

- `TabView` for Today / Program / Settings.
- `NavigationStack` for focused navigation.
- `Menu` / `contextMenu` for compact secondary actions.
- `sheet` for focused editors and supporting flows.
- `confirmationDialog` / `alert` for destructive confirmation.
- `List`, `Form`, `Section` and native row backgrounds for grouped content.
- `DatePicker` for copy/repeat/date inputs.
- `Picker` with segmented style where approved.
- native list move / edit mode for focused exercise/set reorder.
- SF Symbols for tab and workout-state iconography.

The HTML prototype communicates structure and visual intent; it is not a pixel-perfect source for system chrome.

## Canonical implementation map

| Canonical surface | Frozen intent | SwiftUI implementation |
| --- | --- | --- |
| App navigation | Today first; Program calendar icon; Settings gear | `GymChecklist/App/ContentView.swift` |
| Shared visual system | green/mint semantic palette, grouped surfaces, spacing, typography | `GymChecklist/Core/UI/GymTheme.swift` |
| Today | checklist execution, skip/restore, long-press set editing, completion feedback, empty/offline states | `GymChecklist/Features/Today/TodayView.swift` |
| Program | Week/Month, selected date, plan/history rows, menus, focused reorder, delete confirmation | `GymChecklist/Features/Program/ProgramView.swift` |
| Program state model | Empty/Planned/Partial/Completed/Incomplete symbols and calendar semantics | `GymChecklist/Features/Program/ProgramCalendarState.swift` |
| Exercise picker | search bundled catalog, add custom exercise | `GymChecklist/Features/Exercises/ExercisePickerView.swift` |
| Copy / Repeat | native DatePicker and compact repeat controls | `GymChecklist/Features/Program/ProgramView.swift` supporting sheets |
| Settings | Profile, Body weight, inline Appearance/unit, Account, Danger zone | `GymChecklist/Features/Settings/SettingsView.swift` |
| Authentication | minimal native email/password/provider hierarchy, leading-aligned fields | `GymChecklist/Features/Auth/RegistrationView.swift` |
| Domain / data behavior | preserve existing workout, actual/planned, offline, copy/repeat semantics | existing view models/repositories; change only when required by frozen UI |

## Final Phase 8 interaction clarifications

### Compact contextual actions
Compact menus and destructive confirmations use native modal/menu presentation. They must not introduce a nested scrolling surface or permit background interaction while presented. Larger editor sheets may scroll when needed for keyboard or Dynamic Type accessibility.

### Program calendar symbols
Use one semantic state vocabulary in Week and Month:
- Empty: no workout marker / circle intent as appropriate.
- Planned: `circle`.
- Partial: `circle.lefthalf.filled`.
- Completed: `checkmark.circle.fill`.
- Incomplete: `exclamationmark.circle`.

State remains accessible by label and never by color alone.

### Program set rows
- Current/future Program: tap a set row to edit its plan.
- Past Program: tap an editable recorded set to edit actual values.
- Do not show trailing `Edit`, `Edit plan`, or `Edit actual` labels on every row.
- Completed state is communicated by icon/state treatment, not by greying the whole primary value.
- Editing a completed set plan must not overwrite the already-recorded actual result.
- Today keeps its separate execution model: tap complete/undo, long press edit.

### Reorder
Exercise and set reordering are separate focused native flows:
- Exercise actions -> Reorder exercises -> exercise-only list -> drag/move -> Done.
- Set actions -> Reorder sets -> sets for that exercise only -> drag/move -> Done.

Do not combine exercise ordering and set ordering into one screen.

### Authentication
Email/password form labels, placeholders and values use the standard leading-aligned native form hierarchy.

## Representative-state caution

`state-disabled` remains a regression/reference state with a known prototype defect from stabilization. It is **not** authoritative visual guidance for production destructive/disabled UI. Use the frozen UX rules and native iOS semantics instead.

## Verification mapping

Phase 9 acceptance compares:
1. product behavior against `docs/product_spec.md`;
2. user-visible interaction against `docs/ux_spec.md`;
3. visual hierarchy against frozen prototype source `2457a7beee4205e4a5e8fb51e219aea1a46ca5fa`;
4. native implementation against this mapping and `docs/ui_ux_design_rules.md`;
5. production behavior with existing/focused iOS tests and the repository two-pass macOS remote gate.
