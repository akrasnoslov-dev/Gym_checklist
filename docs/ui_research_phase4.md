# Gym Checklist — Phase 4 Design Research Handoff

**Status:** research complete; input to Phase 5 only. No Pencil or production UI was changed.  
**Research date:** 2026-09-07  
**Implementation inspected:** `dev` at `6343b7606421288a3f651dd69c331ab2a7a1d9ac`.

## Scope and evidence boundary

This document makes visual and interaction recommendations for the approved MVP. It does not change product behavior. Source-of-truth priority remains: current explicit user decisions -> `product_spec.md` -> `ux_spec.md` -> current implementation -> historical mockup.

### Verified current product behavior

- App opens authenticated users on **Today**; top-level tabs are Today, Program, Settings.
- Today has one independent, immediately tappable set row; a second tap undoes completion. Sets can be completed in any order. There is no Start Workout flow.
- Long press opens a compact Today set editor. Exercise skip is a secondary context-menu action; skipped exercises can be restored from a low-prominence menu.
- Workout completion is a dismissible in-place overlay, not navigation. Today supports no-program, rest-day, loading, unavailable, and cached-offline states.
- Program has Week/Month modes, one shared selected date, day-state icon/VoiceOver text, date-scoped editing, copy/repeat sheets, and destructive confirmations.
- Settings has profile, compact body-weight history, System/Light/Dark, kg/lb, logout, and protected account deletion. Body-weight deletion uses native destructive swipe actions.
- Current shared implementation already has semantic green/mint tokens (`GymTheme`), semantic system surfaces, native `Form`/`List`/`sheet`/`Menu`/`confirmationDialog`, and substantial VoiceOver identifiers/labels.

### Research interpretation

Apple’s HIG and first-party applications are strongest evidence for interaction grammar: platform navigation, controls, accessibility, system color, sheets, menus and destructive confirmation. Apple Health/Fitness and market leaders are useful *contrast cases*, not templates: their dashboards, coaching, charts, timers and social systems are outside Gym Checklist MVP. Strong, Hevy and Liftin’ validate that a workout logger can be fast; their extra scope is deliberately excluded.

## 1. Executive decisions

These are mandatory rules for the **Pencil Final Candidate** unless a later explicit user decision overrides them.

1. Make Today a completion-first checklist: exercise heading, then full-width set rows. One row is one target and one tap completes/undoes it.
2. Keep Today visually quieter than every other surface. No metrics, charts, progress ring, workout timer, recommendation, warm-up or start/finish control.
3. Use one primary completion affordance per row: leading check circle plus tappable row surface. Completed state changes icon, text treatment and accessibility state; never color alone.
4. Preserve 44 pt minimum interactive height; use 48–52 pt set rows where copy can wrap. Do not make a small icon the only tappable target.
5. Group sets inside their exercise, with modest internal dividers. Exercise groups may use a subtle surface/container, but individual set rows must not become stacked cards.
6. Put rare Today actions behind a header overflow/context action: Skip exercise. Put Restore skipped exercises below active content as one low-prominence menu.
7. Use a medium/large native-style bottom sheet for set editing and compact one-purpose flows; retain Cancel/Save in navigation-bar positions. Do not use a custom modal for ordinary edits.
8. Keep destructive actions only in Program/account contexts. Mark them red, explain the deleted scope, and require a native confirmation before deleting a set, exercise, workout, or account.
9. Keep Program denser than Today. Use a single selected-date model across Week and Month, clear prev/next controls, and state icon + accessible text for every non-empty day.
10. Keep Week as fast planning navigation: seven equal date targets. Keep Month as a compact, fixed grid with readable day numbers and subordinate state marks; never turn it into an analytics heatmap.
11. Use native grouped forms/lists for editors, custom exercise, profile, body weight, auth and account actions. Custom card styling is for summary/navigation surfaces, not every input.
12. Give empty states one clear message, one relevant action at most, and no decorative dashboard substitute. Offline cache messaging must remain non-blocking and secondary.
13. Completion feedback is a short, dismissible celebration overlay above Today. It has one action, returns to same screen/context, contains no statistics, and must be accessible as a modal.
14. Keep approved green/lime/mint direction. Accent conveys selected/completed/primary action; neutral system surfaces and primary text carry most hierarchy. Purple from the historical reference is excluded.
15. Design light and dark together with semantic tokens, not two independent palettes. Avoid hard-coded white/black/gray and avoid low-contrast lime text on light surfaces.
16. Support Dynamic Type by allowing headers, row values and summaries to wrap; do not use compressed fixed-height text. Calendar may keep fixed cell geometry, but must preserve minimum target size and use VoiceOver labels for full dates/state.
17. Use SF Symbols only when their meaning is familiar and pair them with text/VoiceOver labels for actions and state. Do not rely on an icon-only destructive action.
18. Preserve native tab bar, navigation-stack titles, system keyboard/form behavior and standard swipe/menu affordances unless a Pencil decision has a clear, task-specific benefit.

## 2. Decision matrix

| Problem | Reliable references | Chosen pattern | Why it fits Gym Checklist | Affected Phase 5 screens/components | Accessibility / dark-mode implications |
| --- | --- | --- | --- | --- | --- |
| Marking a completed set fast without accidental ambiguity | [Apple HIG — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Apple Reminders](https://apps.apple.com/us/app/reminders/id1108187841) | Entire 48–52 pt set row toggles; leading `circle` / `checkmark.circle.fill`; value stays primary content. | Directly protects one-tap invariant and familiar checklist mental model. | Today incomplete/partial/completed; reusable `SetCompletionRow`. | VoiceOver says exercise, ordinal set, value, completion state and toggle action. Use icon/text-opacity/state together; accent contrast safe in both themes. |
| Avoiding Today card overload while grouping exercises | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Strong](https://www.strong.app/), [Liftin’](https://www.liftinapp.co/) | One calm exercise container with internal edge-to-edge rows and dividers; no card per set. | Workout use is repetitive and glance-driven; card-per-set adds scanning and tap friction. | Today, Program detail; `ExerciseChecklistGroup`, divider token. | Let exercise names and values wrap. Container/separator use semantic system surfaces, not fixed gray. |
| Hiding uncommon Today actions without losing them | [Apple HIG — Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Apple Reminders](https://apps.apple.com/us/app/reminders/id1108187841) | Text exercise header with discreet overflow/context menu for Skip; one Restore skipped exercises menu after visible groups. | Skip/restore remains discoverable but does not compete with set completion. Matches verified behavior. | Today active/skip/restore states; `ExerciseHeaderActions`. | Header has 44 pt target and named VoiceOver custom action. Do not hide restore through color or gesture only. |
| Editing one set without leaving task context | [Apple HIG — Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets), [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/) | Native bottom sheet containing one `Form`: only relevant Reps/Weight/Time fields, Cancel and Save. | Long press is already approved; a sheet preserves Today position and isolates edit from checklist execution. | Today set editor, Program set editor, historical actual editor; `SetEditorSheet`. | Use labelled fields, correct decimal/number keyboards, visible validation, keyboard-safe layout, Dynamic Type scrolling. Sheet must present an accessible title. |
| Planning across dates without losing selected-day context | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Apple HIG — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) | Week/Month segmented mode, explicit previous/next controls, one selected date shared by both modes and same detail below. | Matches current data model and keeps calendar navigation separate from execution. | Program Week, Program Month, selected-date detail; `ProgramDateNavigator`. | Date control labels use full localized date plus state/selected/today. Month day mark supplements, never replaces, text/accessibility state. |
| Showing plan/completion status in a dense calendar | [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color), current `ProgramCalendarState` behavior | Small SF Symbol/state mark plus selected outline; status pill in detail. Use no heatmap and no percentage. | State awareness helps planning; analytics would violate scope and crowd Program. | Week cells, Month cells, Program detail status; `WorkoutDayStateIndicator`. | State has icon + VoiceOver label. Current-date outline and selection must remain distinguishable at increased contrast and in dark mode. |
| Editing and reordering program content | [Apple HIG — Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables), [Apple HIG — Menus](https://developer.apple.com/design/human-interface-guidelines/menus) | Dense ordered exercise sections; labelled `Add set`/`Add exercise`; overflow menus for move/delete; sheets for content edits. | Program is planned work, so density is useful, while destructive/reorder controls remain secondary. | Program workout editor, exercise picker, custom exercise. | Every move action needs text label and position context. Avoid drag-only reorder as sole interaction. Preserve 44 pt targets. |
| Copy/repeat without accidental overwrite | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Strong App Store listing](https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577) | Purpose-built sheet: source summary, native date/cadence choice, resulting-workout summary, disabled primary action on invalid/occupied destinations. | Supports approved independent copies/repeats and communicates outcome before mutation. | Copy workout sheet, Repeat workout sheet; `WorkflowSummaryCard`, validation message token. | Validation is written, not only disabled color. Date/cadence controls need labels and value announcements. Use destructive color only for errors that block action. |
| Destructive actions and deletion recovery | [Apple HIG — Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts), [Apple HIG — Menus](https://developer.apple.com/design/human-interface-guidelines/menus) | Red action in Program/account; native confirmation names object and scope. Body-weight rows use native destructive swipe; retain row on failed deletion and show error. | Matches verified behavior and prevents data loss while keeping common flows light. | Program delete set/exercise/workout; Settings delete account/body weight. | Destructive label must be explicit (for example, “Delete workout”), not only trash icon. Confirmation supports VoiceOver focus and system dark mode automatically. |
| Empty, loading, offline and rest-day states | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Apple Health](https://apps.apple.com/us/app/apple-health/id1242545199) | One short status + one contextual action: create workout, view program, or passive retry message. Small illustration only for no-program/rest if it does not push CTA below fold. | Keeps no-workout moments calm; Health’s data-rich pattern is intentionally not used. | Today no program/rest/empty/loading/unavailable; Program empty/loading/unavailable. | All copy remains readable at large Dynamic Type. Loading/unavailable announce status; cached data stays usable and is not obscured. |
| Finishing a workout with motivation, not another workflow | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Apple Fitness](https://www.apple.com/uk/health/) | In-place celebratory overlay: small brand/SF Symbol illustration, one short line plus optional subline, one “Done” action. | Meets explicit completion requirement and returns immediately to completed Today; Fitness-style rings/stats are out of scope. | Today completion overlay; `WorkoutCompletionOverlay`. | Treat as modal; move VoiceOver focus in, then return it to prior set/header. Respect Reduce Motion: static or nonessential animation only. Light/dark overlay and card contrast must be checked. |
| Profile, body weight, preferences and account | [Apple HIG — Settings](https://developer.apple.com/design/human-interface-guidelines/settings), [Apple Health](https://apps.apple.com/us/app/apple-health/id1242545199) | Profile-first settings: compact summary rows into native form/detail sheets; body-weight history is a short dated list, not a chart/dashboard; account/danger separated. | Preserves approved profile/body-weight scope without becoming Health clone. | Settings, Profile editor, Body weight history, Appearance/units, Account. | BMI remains neutral informational copy and no medical color grading. Segment choices expose labels/value; edit/delete rows retain standard semantics. |
| Auth with lowest possible visual and cognitive load | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/) | Native `Form`/labelled fields, Apple’s supplied Sign in with Apple control, Google control, error inline near fields, no onboarding carousel. | Matches approved no-onboarding behavior and keeps authentication separate from workout product. | Sign up, Sign in, reset password, auth errors. | Use supplied Apple control unchanged; error gets accessible focus. Respect keyboard focus/content types and Dynamic Type. |
| Brand expression across system appearances | [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color), [Apple HIG — Dark mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode) | Semantic tokens: accent fill, accent foreground, soft accent, primary/secondary text, grouped surface, elevated surface, separator, destructive. Accent is restrained. | Existing code already follows this direction; tokens make Pencil and SwiftUI implementable without light/dark drift. | All screens; `GymTheme` successor / Components & Tokens area. | Test contrast per token pairing. Do not place lime text on white; do not use fixed white cards or black overlays without dark-mode token behavior. |

## 3. Do not do

Do not copy these patterns into Gym Checklist:

- Do not add a Start Workout / End Workout lifecycle, timer, rest countdown, automatic exercise advance, rings, streaks, PRs, charts, calorie cards, coaching, recommendations, social feed, sharing, HealthKit surface, Apple Watch UI, widgets, or AI generation. Strong, Hevy, Fitbod and Fitness offer many of these because they are broader products; Gym Checklist does not.
- Do not turn Today into a generic dashboard or make it resemble Apple Health/Fitness. Their data hierarchy is wrong for a pre-planned, one-tap checklist.
- Do not revive historical purple styling. Approved direction is green/lime/mint.
- Do not use a card for every set, nested cards, heavy shadows, glassmorphism, decorative gradients, giant hero artwork, or persistent motivational copy above a live workout.
- Do not make the checkbox, chevron, or overflow icon the only hit target; do not make completion depend on swipe, long press, drag, or a confirmation dialog.
- Do not show Skip, Delete, Edit, Copy, Repeat, or account actions beside each set as permanent controls.
- Do not expose Delete set in Today’s long-press editor. Set deletion belongs to Program editing only.
- Do not represent calendar state with color alone, a dense heatmap, tiny unreadable dots, or an overloaded multi-metric cell.
- Do not replace native tab bar, navigation semantics, sheet dismissal, standard date picker, destructive confirmation, text fields, Apple Sign In button, or body-weight swipe-delete merely for visual novelty.
- Do not use bespoke controls that cannot grow with Dynamic Type, truncate set values, hide keyboard focus, or depend on a gesture unavailable to VoiceOver.
- Do not show network status as a blocking full-screen state when a cached workout is available; do not introduce manual Sync.
- Do not present completion as a new screen, request a rating/share, or display statistics in its overlay.

## 4. Phase 5 handoff

### Mandatory design rules

- Build only in Pencil section `04 — Final Candidate / …`; keep `Components / Tokens` in same Pencil file. Do not modify SwiftUI in Phase 5.
- Draw all meaningful visual states in Light and Dark at least once. Use same semantic token names; do not create separate arbitrary layouts.
- Use iPhone-safe-area layouts, native tab bar, navigation titles and iOS 17+ controls as default implementation target.
- Treat 44 pt as minimum practical target. Design Today set rows at 48–52 pt minimum before Dynamic Type expansion.
- Use system semantic colors/surfaces as base. Brand accent is emphasis, not background paint across every surface.
- Follow current product behavior exactly unless a conflict is called out below as unresolved and taken to the user.
- Include visible selected/focused/disabled/error/destructive states where relevant. Completion and calendar statuses need a non-color cue.

### Recommended reusable components and tokens

| Foundation | Phase 5 definition |
| --- | --- |
| Color | `accentFill`, `accentForeground`, `accentSoft`, `surfaceGrouped`, `surfaceElevated`, `textPrimary`, `textSecondary`, `separator`, `destructive`, `scrim`. Each must specify Light/Dark values and intended text/icon pairings. |
| Type | Prefer native Dynamic Type text styles: large navigation/title, `title3`/headline exercise name, body set value, subheadline summary, caption/footnote metadata. No fixed point sizes for ordinary text. |
| Spacing / shape | 4 pt base rhythm; 12–16 pt internal group padding; 16–20 pt screen inset; 8–12 pt row/group gap; 12 pt row-group radius; 16–20 pt summary/card radius. Verify against current `GymCard` only as implementation reference, not an obligation to retain every card. |
| `SetCompletionRow` | Leading state symbol, set value, full-row hit area, divider, incomplete/completed state, VoiceOver value. No trailing action needed. |
| `ExerciseChecklistGroup` | Exercise header + overflow/Skip, stacked `SetCompletionRow`s, optional low-key skipped state. |
| `WorkoutDayStateIndicator` | Symbol plus semantic label for planned/partial/completed/incomplete; current-day outline and selected-date treatment are separate. |
| `ProgramDateNavigator` | Week and Month variants with one selected-date state, labelled previous/next controls and full date context. |
| `GymSummaryRow` / `GymSection` | Reusable settings/program navigation row: leading optional icon, title, summary, chevron; grouped surface only where it improves scan. |
| `WorkflowSheet` | Navigation title, Cancel/Done or primary action, source/result summary, native form controls, inline validation. Used by set edit, copy, repeat, profile and body weight. |
| `DestructiveConfirmation` | System confirmation dialog copy template: title names object; message states exactly what disappears; red action has explicit verb. |
| `EmptyState` / `OfflineNotice` | Small icon/illustration slot, one title, optional one-line explanation, one contextual CTA maximum. Offline notice is inline/non-blocking. |
| `WorkoutCompletionOverlay` | Dimming scrim, one small illustration/SF Symbol, short encouragement, one dismissal, VoiceOver modal focus, Reduce Motion variant. |

### Screen-by-screen rules

#### Today

- Highest visual priority: `Today`, local date, exercise name, set rows, tab bar. Do not insert a progress dashboard.
- Build explicit frames for: active incomplete, partial, all completed behind overlay, skipped exercise + restore affordance, no workout ever, rest day, empty configured workout, cached-offline, unavailable-without-cache, long-press editor, completion overlay.
- Exercise container gives structure; rows carry interaction. Display canonical set copy exactly as current formatter/spec: weighted, reps-only, or timed without meaningless zero/one values.
- One-tap completion must retain scroll location in implementation; design must not imply a transition or auto-scroll.

#### Program

- Build Week and Month as two views of same selected date; selected-date detail must be visually/structurally identical after either navigation path.
- Week: seven readable date targets; Month: six-row fixed grid with out-of-month dates visually subordinate but selectable.
- Give date state both visible symbol and full accessible label. Program detail may show a compact status pill.
- Editor hierarchy: selected date -> exercises -> sets -> Add set / Add exercise. Put reordering/delete in labelled overflow/context actions.
- Show future editing, historical completed actual-value edit, empty future/past, copy, repeat, and delete confirmations. Do not invent template engine or multi-workout-per-day UI.

#### Editors and sheets

- Set editor displays only fields allowed by set type. Today edits plan before completion and actual after completion; Program completed-set plan edits must not imply it changes actual results.
- Use native form sections, readable labels, primary Save in nav bar/bottom only where keyboard-safe, and Cancel. Program-only deletion is separate, red, confirmed.
- Copy/repeat must preview source/date/result and invalid destination. Copy stays independent; repeat communicates cadence/duration and skipped occupied dates.
- Exercise picker begins with search; custom exercise is visible but secondary. No media tiles or exercise coaching.

#### Settings and authentication

- Settings order: health profile, body weight, appearance/weight unit, account, danger zone. Keep BMI neutral and compact; no health dashboard or BMI category judgement.
- Body-weight history is dated list with edit-on-tap and destructive swipe; explicit form for new/edit measurement. No chart in MVP.
- Authentication stays a short form with official Apple control, Google control, password reset and inline error. Successful auth goes directly to Today; no onboarding.
- Account deletion has a clearly separated danger zone and explicit confirmation/re-auth steps.

#### Empty and completion states

- No program: “No workout planned yet.” + Create workout. Rest day: “Rest day.” / “See you tomorrow.” + View program. Keep one action per state.
- Completion overlay: one upbeat line plus optional subline, little illustration, “Done.” It overlays Today and dismisses back to it. No stats, next-workout CTA or special full screen.
- Loading/unavailable variants are functional system states, not marketing scenes. Cached offline workout remains visible and actionable.

### User decisions still needed

No unresolved **product** decision blocks Phase 5; specs already settle the core behavior.

Before Phase 6 approval, user should choose only these visual details from the Pencil candidate:

1. Completion tone: restrained “You crushed it!” style versus more playful meme-like copy. Both comply with `ux_spec.md`; no extra actions or statistics.
2. Completion visual: SF Symbol/brand-shape treatment versus a small bespoke non-character illustration. It must remain lightweight, static under Reduce Motion, and use the approved green/lime/mint direction.
3. Exact final Light/Dark accent token swatches and completion-state treatment after contrast review. Purple remains excluded.

## 5. Sources

### Apple — primary interaction and accessibility references

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [HIG: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
- [HIG: Menus](https://developer.apple.com/design/human-interface-guidelines/menus)
- [HIG: Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)
- [HIG: Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)
- [HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [HIG: Dark mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple: Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)
- [Apple Reminders — App Store](https://apps.apple.com/us/app/reminders/id1108187841)
- [Apple Health — App Store](https://apps.apple.com/us/app/apple-health/id1242545199)
- [Apple Health/Fitness overview](https://www.apple.com/uk/health/)

### Relevant workout-product references (scope contrast, not feature copying)

- [Strong — official site](https://www.strong.app/)
- [Strong — App Store](https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577)
- [Hevy — official site](https://www.hevyapp.com/)
- [Hevy — App Store](https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350)
- [Liftin’ — official site](https://www.liftinapp.co/)
- [Liftin’ — App Store](https://apps.apple.com/us/app/liftin-gym-workout-tracker/id1445041669)
- [Fitbod — official site](https://fitbod.me/)
- [Fitbod — App Store](https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543)

### Repository sources used to verify current behavior

- `AGENTS.md`
- `docs/ui_redesign_plan.md`
- `docs/progress.md`
- `docs/product_spec.md`
- `docs/ux_spec.md`
- `docs/architecture.md`
- `GymChecklist/Core/UI/GymTheme.swift`
- `GymChecklist/Features/Today/TodayView.swift`
- `GymChecklist/Features/Program/ProgramView.swift`
- `GymChecklist/Features/Exercises/ExercisePickerView.swift`
- `GymChecklist/Features/Settings/SettingsView.swift`
- `GymChecklist/Features/Auth/RegistrationView.swift`
- `GymChecklist/App/ContentView.swift`
