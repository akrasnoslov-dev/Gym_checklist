# Gym Checklist — UI Redesign Plan

## Current direction

The redesign path is intentionally simplified.

```text
Phase 2 — Current app baseline
        +
Phase 4 — UI/UX design research
        ↓
Phase 5 — Final UI/UX candidate
        ↓
Phase 6 — User review
        ↓
Phase 7 — Iterate to approval
        ↓
Phase 8 — Design freeze
        ↓
Phase 9 — SwiftUI implementation
```

Phase 1 and Phase 3 are retired by explicit user decision.

## Governing rules

- Production SwiftUI must not be redesigned before Phase 5 is reviewed, explicitly approved and frozen.
- Current explicit user decisions have highest priority.
- `docs/product_spec.md` is authoritative for product behavior.
- `docs/ux_spec.md` is authoritative for approved UX behavior.
- Phase 2 is the factual baseline for how the current MVP actually looks and behaves.
- Phase 4 defines the UI/UX research conclusions and design constraints.
- `docs/ui_ux_design_rules.md` contains durable visual/interaction rules for Phase 5 and implementation.
- The historical mockup and Phase 1 reconstruction are no longer design inputs.
- Protect the core invariant:

```text
Open app -> Today -> one tap per completed set -> close app
```

---

## Phase 1 — RETIRED

Historical reference reconstruction is no longer required.

Existing Phase 1 assets may remain in the repository as historical material, but:
- do not spend time improving them;
- do not use them to drive Phase 5;
- do not require editable reconstruction;
- do not compare Phase 5 against them for acceptance.

---

## Phase 2 — Current application baseline

**Status:** complete enough to drive Phase 5.

Authoritative inputs:
- `docs/design/current-app-inventory.md`;
- `docs/design/current-app-gap-matrix.md`;
- real current-MVP runtime screenshots;
- relevant current SwiftUI/source when exact behavior needs confirmation.

Phase 2 defines:
- current screens and states;
- current visual hierarchy and native rendering;
- implemented behavior;
- existing tokens/components;
- current limitations and conditional states.

Runtime screenshots are preferred over AI reconstructions for visual truth.

No editable clone of the current app is required.

---

## Phase 3 — REMOVED

No separate reconciliation phase.

Conflicts are resolved directly during Phase 5 using this priority:

1. explicit current user decision;
2. product spec;
3. UX spec;
4. Phase 4 UI/UX design rules;
5. current implementation/Phase 2 visual baseline.

---

## Phase 4 — UI/UX Design Research

**Status:** complete and refreshed 2026-09-18.

Primary document:
- `docs/ui_research_phase4.md`

Durable rules:
- `docs/ui_ux_design_rules.md`

Phase 4 covers both UX and UI:
- interaction patterns;
- native iOS component grammar;
- visual hierarchy;
- typography;
- colors and brand usage;
- Light/Dark;
- density;
- spacing/radii;
- surfaces;
- iconography;
- state design;
- accessibility;
- SwiftUI feasibility for iOS 17+.

Research sources include Apple HIG/Design Resources, current Apple first-party patterns, Reminders, Calendar, Settings, Health/Fitness, Strong, Hevy and Liftin'.

Phase 4 exists to constrain Phase 5. It does not itself redesign production UI.

---

## Phase 5 — Final UI/UX Candidate

**Next design phase.**

### Inputs

Mandatory:
- Phase 2 current-app inventory;
- Phase 2 real runtime screenshots;
- `docs/product_spec.md`;
- `docs/ux_spec.md`;
- `docs/ui_research_phase4.md`;
- `docs/ui_ux_design_rules.md`.

Excluded:
- Phase 1 historical reconstruction;
- historical mockup as a design source;
- invented product behavior.

### Goal

Create the final UI/UX for the approved MVP as a **deterministic HTML/CSS design prototype**.

The prototype is the Phase 5 visual design surface. It must be stored in the repository and must be inspectable in a normal desktop browser.

Figma and Pencil are not part of the critical Phase 5 workflow. They may be used later only as optional documentation/reference surfaces.

The prototype must distinguish two layers:

1. **app-owned content layer** — layout, spacing, typography hierarchy, colors, set rows, exercise groups, calendar cells, empty states, completion overlay and other product-specific visuals are represented precisely in HTML/CSS;
2. **native iOS system layer** — navigation bars, tab bars, sheets, menus, pickers, forms, alerts and other system-owned controls are represented only to communicate structure and intent. They must not be treated as pixel-perfect web replacements for native SwiftUI controls.

The approved Phase 5 prototype plus `docs/ui_ux_design_rules.md` will be the visual input to Phase 9 SwiftUI implementation.

### Phase 5 delivery sequence

Do not design every screen at once.

#### Phase 5A — Foundation + control screen

1. Create the prototype shell under `design/prototype/`.
2. Create semantic design tokens and reusable CSS components.
3. Build one representative **Today / active workout / partial completion** screen.
4. Build its Light and Dark appearances.
5. Make it easy to run locally in a browser.
6. Review the control screen with the user.
7. Do not expand to the full screen set until the visual direction is accepted.

The purpose of the control screen is to validate:
- overall visual language;
- typography hierarchy;
- green/lime/mint usage;
- spacing and density;
- exercise grouping;
- set-row styling;
- completion state;
- native-vs-custom boundary.

#### Phase 5B — Full candidate

After the control screen direction is accepted:
- expand the same design system to all required MVP surfaces/states;
- keep components reusable;
- preserve Light/Dark;
- add only interactions needed to inspect states and flows;
- do not implement product/backend logic.

### Required design-system output

Define:
- semantic color tokens;
- typography;
- spacing;
- radii;
- surface hierarchy;
- separators/borders;
- icons;
- buttons;
- set rows;
- exercise groups;
- calendar cells;
- summary/settings rows;
- sheets/forms;
- completion/destructive/disabled/error states;
- Light/Dark behavior.

### Required surfaces

At minimum:
- Today incomplete/partial/completed;
- Today skipped/restored;
- Today rest day;
- Today no-program/empty;
- Today long-press set editor;
- workout completion overlay;
- Program Week;
- Program Month;
- selected-date workout editing;
- add/edit/remove/reorder exercise/set;
- exercise picker;
- custom exercise;
- copy workout;
- repeat workout;
- historical workout editing;
- Settings;
- Profile;
- body-weight history;
- appearance/unit preferences;
- account/destructive actions;
- sign in/sign up/reset;
- important loading/offline/error states;
- representative Light/Dark states.

### Acceptance

- one coherent visual system;
- Today remains fastest and quietest;
- no approved feature is lost;
- no out-of-scope dashboard/fitness features added;
- important states are represented;
- design remains feasible in native SwiftUI iOS 17+;
- native system chrome is not unnecessarily re-created;
- accessibility is considered;
- user can inspect the final result visually in a browser before implementation;
- prototype avoids web-specific visual patterns that would force a non-native SwiftUI implementation;
- no Phase 5 dependency on Figma AI credits, Figma Professional credits or Pencil AI generation.

---

## Phase 6 — User review

Stop before production implementation.

User reviews the Phase 5 candidate and records changes.

Silence or partial acceptance is not approval.

---

## Phase 7 — Iterate to approval

Iterate only in the design artifact/specification:

```text
Final v1 -> v2 -> ... -> APPROVED
```

Do not redesign production SwiftUI during this loop.

---

## Phase 8 — Design freeze

After explicit user approval:

1. mark the approved design version;
2. treat it as the visual reference for implementation;
3. update `docs/ux_spec.md` where approved design changes make durable clarification necessary;
4. ensure `docs/ui_ux_design_rules.md` matches the approved result;
5. map approved screens/components to SwiftUI files/components;
6. record deliberate native-system substitutions/tolerances.

---

## Phase 9 — Implement in SwiftUI

Implement in coherent batches:

1. design tokens/shared components;
2. Today;
3. Program date navigation;
4. Program editors/copy/repeat/history;
5. Settings/Profile;
6. Auth and supporting states;
7. accessibility/visual consistency;
8. tests/regression coverage;
9. Pass A implementation/hardening;
10. separate Pass B remote-gate audit and justified authoritative macOS verification.

Rules:
- approved Phase 5 design is the visual reference;
- product spec remains behavior authority;
- native SwiftUI/system controls are preferred where they match the approved intent;
- do not invent missing design in implementation;
- preserve offline behavior, security/ownership and data semantics;
- compare implementation screenshots against the approved candidate before acceptance.
