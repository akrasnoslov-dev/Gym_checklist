# Gym Checklist — Phase 4 UI/UX Design Research

**Status:** complete and current as of 2026-09-18.  
**Purpose:** direct input to Phase 5 final UI/UX design.  
**Baseline:** Phase 2 current-app inventory + real runtime screenshots.  
**Not an implementation change:** this document does not modify product behavior or production SwiftUI.

## 1. Research scope

Phase 4 covers both **UX interaction patterns** and **UI visual-system decisions**.

The previous title, “Design Research”, understated the visual/UI work. The research now explicitly covers:
- interaction model and information hierarchy;
- native iOS navigation, tabs, toolbars, menus, sheets, forms, lists and destructive actions;
- visual hierarchy, density and surfaces;
- typography and Dynamic Type;
- semantic color and brand-accent usage;
- Light/Dark behavior;
- iconography and SF Symbols;
- spacing, radii and touch targets;
- checklist completion states;
- week/month calendar states;
- empty, loading, offline, error and completion feedback;
- accessibility;
- implementation feasibility for SwiftUI on iOS 17+.

## 2. Evidence priority

For Phase 5:

1. current explicit user decisions;
2. `docs/product_spec.md`;
3. `docs/ux_spec.md`;
4. Phase 2 current-app inventory and real runtime screenshots;
5. this Phase 4 UI/UX research;
6. external references.

The historical mockup and Phase 1 reconstruction are retired from the redesign path and are not Phase 5 inputs.

## 3. Primary external references

### Apple — authoritative platform references
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple Design Resources: https://developer.apple.com/design/resources/
- Apple Branding guidance: https://developer.apple.com/design/human-interface-guidelines/branding
- Apple Dark Mode guidance: https://developer.apple.com/design/human-interface-guidelines/dark-mode
- Apple Lists and Tables guidance: https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
- Apple Toolbars guidance: https://developer.apple.com/design/human-interface-guidelines/toolbars
- Apple Segmented Controls guidance: https://developer.apple.com/design/human-interface-guidelines/segmented-controls
- Apple Sign in with Apple guidance: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple/
- Apple 2026 brand/UI design session: https://developer.apple.com/videos/play/wwdc2026/251/

Apple’s current design resources include official iOS/iPadOS UI kits for Figma. These are reference material for native geometry and component vocabulary, not a replacement for SwiftUI system controls.

### Product references — contrast and pattern evidence
- Apple Reminders: closest reference for checklist-first completion.
- Apple Calendar: reference for date navigation and segmented Week/Month switching.
- Apple Settings: reference for profile/preferences/account grouping.
- Strong: useful for workout data density, but too session-centric for Gym Checklist.
- Hevy: useful for workout-planning density, but social/analytics surfaces are out of scope.
- Liftin': useful for restrained native-feeling workout UI, but timers/progression/graphs remain out of scope.
- Apple Health/Fitness: useful for system polish and state presentation, but not for dashboard structure.

## 4. Core design conclusion

Gym Checklist should look like a **native iOS checklist/planning app that happens to be for gym workouts**, not like a generic fitness dashboard.

The primary mental model remains:

```text
I already know my workout.
Show today's work.
One tap per completed set.
Close the app.
```

This means:
- Today is visually quieter than Program and Settings;
- completion is the strongest state change;
- planning controls stay out of the execution path;
- native platform components are preferred over custom chrome;
- the brand is expressed through content/state, not by recoloring the whole interface.

## 5. UI research decisions

### 5.1 Native platform layer

Gym Checklist targets iOS 17+.

Use standard SwiftUI navigation, tab bars, menus, sheets, forms, lists, pickers, alerts and confirmation dialogs wherever they satisfy the product need.

Do **not** manually imitate a specific generation of Apple system chrome such as Liquid Glass. Newer iOS versions can render newer system styling automatically; older supported versions must remain native to their OS. The custom design system belongs mainly in the app's content layer.

Implication for Phase 5:
- design custom content/components precisely;
- show standard system chrome as native/system-owned;
- do not freeze native bars, sheets and controls into bespoke pixel copies that will become wrong across iOS versions.

### 5.2 Brand and color

Keep the approved green/lime/mint direction.

Apple’s current branding guidance recommends restrained brand color usage. Apply the accent primarily to:
- completed/selected states;
- primary actions;
- selected tab/icon where the system permits;
- compact status feedback.

Do not use green as a broad page background or on every control.

Use semantic tokens, not hard-coded Light-only values:
- `accentFill`
- `accentForeground`
- `accentSoft`
- `surfaceBase`
- `surfaceGrouped`
- `surfaceElevated`
- `textPrimary`
- `textSecondary`
- `separator`
- `destructive`
- `scrim`

System surfaces should remain dominant. Accent is emphasis.

### 5.3 Typography

Use San Francisco/system typography for MVP.

Use semantic Dynamic Type styles rather than a custom fixed-size scale:
- large navigation title;
- title/headline for exercise or section identity;
- body for set values and standard rows;
- subheadline/footnote/caption for metadata and state explanations.

Rules:
- no custom brand font for MVP;
- no fixed-height text container that truncates Dynamic Type;
- avoid excessive bolding;
- numeric workout values should remain highly scannable;
- secondary metadata must not compete with the set value.

### 5.4 Density and spacing

Today must be the lowest-density cognitive surface, not necessarily the sparsest pixel surface.

Recommended baseline:
- screen inset: 16–20 pt;
- 4 pt spacing rhythm;
- exercise-to-exercise separation: 16–24 pt;
- exercise header to rows: 6–10 pt;
- row minimum hit height: 48–52 pt;
- all interactive controls: practical minimum 44 pt;
- group/card radius: about 12–16 pt;
- avoid large empty decorative gaps that push workout content below the fold.

Program may be denser because it is an editing/planning surface.

### 5.5 Surface hierarchy

Avoid “card for everything”.

Today:
- one subtle visual group per exercise;
- set rows live inside that group;
- internal separators instead of independent cards per set;
- no heavy shadow;
- no nested floating cards.

Program/Settings:
- native grouped lists/forms are preferred for editable data;
- summary/navigation content may use restrained grouped surfaces;
- destructive areas are visually separated but not theatrically styled.

### 5.6 Checklist completion

Closest interaction reference: Reminders.

One set row is one completion target:
- whole row is tappable;
- leading circle/check-circle state;
- completed state changes icon plus text treatment/state semantics;
- never rely on green alone;
- second tap undoes completion;
- no confirmation and no navigation.

Do not add:
- Start Workout;
- Finish Workout button;
- timer;
- automatic next exercise;
- swipe-only completion;
- tiny checkbox as the only hit target.

### 5.7 Exercise grouping and secondary actions

Exercise name is the group header.

Rare actions such as Skip remain secondary:
- overflow/context action on the exercise header;
- restore skipped exercises through one low-prominence entry below active content;
- no permanent Skip/Edit/Delete controls beside every set.

### 5.8 Sheets and editors

Use native-style bottom sheets for compact focused editing.

Set editor:
- only fields relevant to the set type;
- Cancel + Save/Done in standard positions;
- same context retained after dismissal;
- no Today set deletion.

Program-only destructive edits:
- destructive action clearly labelled;
- native confirmation states exact object/scope.

### 5.9 Program Week and Month

Use one selected-date model.

Week:
- seven equal date targets;
- clear selected date;
- simple state indicator;
- fast previous/next navigation.

Month:
- compact fixed calendar grid;
- readable day number;
- subordinate workout-state mark;
- selected/today/outside-month are separate visual concepts.

Do not use:
- analytics heatmap;
- multiple tiny status dots;
- percentage/progress metrics in date cells;
- color-only status.

Week/Month switch should use a native segmented control because they are closely related views of the same Program content.

### 5.10 Navigation and tabs

Keep top-level tabs:
- Today
- Program
- Settings

Use standard tab-bar behavior and familiar symbols.

Use large navigation titles where they improve orientation, but do not duplicate the same title again inside content.

Toolbar actions must be limited to essential current-context actions; overflow handles secondary actions.

### 5.11 Settings/Profile

Use a profile-first grouped settings structure:
1. Profile;
2. Body weight;
3. Preferences;
4. Account;
5. Danger zone.

Body weight remains a compact dated list, not a chart.

BMI remains neutral information only.

Use standard row, picker, segmented-control and swipe-delete conventions.

### 5.12 Authentication

Keep auth visually quiet and native.

Use:
- labelled system fields;
- one clear primary action;
- provider controls using provider/system requirements;
- inline or nearby error feedback;
- no onboarding carousel;
- no decorative dashboard or fitness imagery.

Do not recolor or redraw Sign in with Apple outside Apple’s allowed styling.

### 5.13 Empty, loading, offline and error states

Each state should answer:
1. what happened;
2. whether the user can act;
3. what the next useful action is.

Rules:
- one short message;
- at most one primary contextual action;
- cached Today content remains usable when offline;
- offline/sync messaging stays secondary;
- no manual Sync button;
- no large decorative illustration unless it materially improves an otherwise empty state without hiding the action.

### 5.14 Workout completion

Use a short in-place modal/overlay over Today:
- small illustration or symbol;
- one short line;
- optional short subline;
- one dismiss action;
- no stats;
- no share/rating prompt;
- no new screen.

Motion must be nonessential and respect Reduce Motion.

### 5.15 Iconography

Prefer SF Symbols for familiar platform actions and states.

Rules:
- completion circle/check;
- standard chevrons, ellipsis, calendar/navigation symbols where appropriate;
- no mixed icon families;
- no icon-only destructive action when text is needed for clarity;
- use text/VoiceOver labels where meaning is not obvious.

### 5.16 Light/Dark

Use one semantic system, not two independent designs.

Prefer system background/label/separator colors and semantic custom accent variants.

Dark mode is not a simple color inversion.

Every Phase 5 component must be checked for:
- contrast;
- selected/completed distinction;
- separators;
- elevated sheet/surface distinction;
- destructive state;
- disabled state.

### 5.17 Accessibility

Phase 5 must design for:
- Dynamic Type expansion;
- VoiceOver labels and state;
- non-color-only state;
- minimum practical touch targets;
- sufficient contrast;
- Reduce Motion;
- standard focus/dismissal behavior.

Calendar cells can keep fixed geometry, but the accessible label must expose the full date and workout state.

## 6. Product-reference conclusions

### Apple Reminders
Adopt:
- immediate check-off mental model;
- quiet row hierarchy;
- completion as direct manipulation;
- secondary actions behind menus.

Reject:
- reminder-specific metadata density on Today.

### Strong / Hevy
Adopt:
- compact readable exercise/set grouping;
- efficient workout-data scanning;
- clear separation between exercise identity and per-set data.

Reject:
- Start/Finish workout lifecycle;
- rest timer;
- analytics;
- social/feed;
- PRs/streaks;
- persistent workout controls.

### Liftin'
Adopt:
- restraint;
- native-feeling hierarchy;
- workout data first.

Reject:
- automatic progression/coaching;
- graph-heavy progress surfaces;
- timers.

### Apple Health / Fitness
Adopt:
- semantic system styling;
- accessible typography;
- polished empty/state feedback.

Reject:
- dashboard cards;
- rings;
- trends;
- metric-first home screen.

## 7. Phase 5 mandatory inputs

Phase 5 must use:
- `docs/design/current-app-inventory.md`;
- `docs/design/current-app-gap-matrix.md`;
- the real Phase 2 runtime screenshots;
- `docs/product_spec.md`;
- `docs/ux_spec.md`;
- this research;
- `docs/ui_ux_design_rules.md`.

Phase 5 must **not** use the historical mockup/Phase 1 as a design source.

## 8. Phase 5 target

Create the final UI/UX for every relevant MVP surface and important state.

The candidate must define:
- visual design system;
- reusable component states;
- Light/Dark behavior;
- Today;
- Program Week/Month and editing;
- exercise picker/custom exercise;
- copy/repeat;
- historical workout editing;
- Settings/Profile/body weight/account;
- authentication;
- empty/loading/offline/error states;
- workout completion;
- accessibility-sensitive variants.

The final design can be produced in a tool that gives reliable, inspectable, editable output. The tool is secondary to fidelity and determinism. Production SwiftUI remains unchanged until the design is reviewed, approved and frozen.

## 9. Decision summary

```text
Phase 2 current app
        +
Phase 4 UI/UX research
        +
approved product/UX behavior
        ↓
Phase 5 final UI/UX candidate
```

No Phase 1 dependency. No Phase 3 reconciliation step.
