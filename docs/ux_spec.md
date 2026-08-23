# Gym Checklist — UX Specification

## 1. UX objective
The workout experience should feel like a checklist, not a fitness dashboard.

Primary mental model:

```text
I already know my program. Show me today's work and let me tick it off.
```

## 2. Design direction
- One minimalist design system.
- System / Light / Dark appearances.
- English only for MVP.
- Native iOS interaction patterns where practical.
- High information clarity with low visual density.
- Purple accent is acceptable as the current concept direction, but color is secondary to hierarchy and readability.

### Reference mockup status
`today-program-mockup.png` is a non-authoritative visual reference. If it conflicts with this specification, this specification wins. In particular, any `Delete set` action shown in the Today long-press editor is obsolete: set deletion belongs to Program editing only and must not be exposed as a Today long-press action unless explicitly approved later.

## 3. Today — highest priority screen
### Content hierarchy
1. `Today`
2. Local date
3. Exercise name
4. One row per set
5. Bottom navigation

Avoid secondary metrics and explanatory copy while a workout exists.

### Set row
One row is one tappable completion target.

Examples:
- `8 reps × 85 kg`
- `10 reps × 26 kg`
- `10 reps`
- `45 sec`

Set row states:
- incomplete
- completed

Completed must be distinguishable by more than color alone.

### Interaction
- Tap: toggle completed/incomplete.
- Long press: open compact edit sheet.
- No Start Workout button.
- No per-exercise completion screen.
- No automatic jumping to a next exercise.
- Preserve scroll position after set interaction.

### Exercise actions
Secondary action for Skip Exercise should be available without cluttering every set row. Preferred candidates for final UI review:
- long press on exercise header,
- discreet overflow menu.

Skipped exercise is removed from active Today. A low-prominence restore action must remain available.

## 4. Long-press set editor
Prefer a bottom sheet.

Fields displayed only as necessary:
- Reps
- Weight
- Time

Actions:
- Save
- Cancel
- destructive set deletion only when editing Program, not as a primary Today action unless later explicitly approved.

The editor should return directly to the same Today position.

## 5. Workout completion
Triggered only when the whole day's workout is complete.

Use an overlay/modal, not navigation.
Contents:
- small illustration/animation,
- short encouraging/meme-like line,
- one dismiss action.

Tone examples:
- `You crushed it!`
- `Gym survived. Barely.`
- `Another one done.`
- `Look at you actually sticking to the plan.`

Do not show statistics in the completion popup for MVP.

## 6. Today empty states
### No program yet
- Illustration may be used.
- `No workout planned yet.`
- `Create workout`

### Rest day
- `Rest day.`
- `See you tomorrow.`
- `View program`

## 7. Program
Program is allowed to be denser than Today because it is an editing/planning surface.

### Week navigation
Header with previous/next week controls and a 7-day selector.
Each date may visually communicate empty/planned/partial/completed/incomplete state.

### Workout editor
For selected date:
- exercise sections,
- ordered set rows,
- add set,
- add exercise,
- edit/remove/reorder,
- copy workout,
- repeat weekly,
- delete workout.

Do not surface history analytics here; past dates simply show actual completion/results.

## 8. Exercise picker
- Search at top.
- Common/system exercises listed below.
- `Add custom exercise` visible but secondary.
- No exercise images/videos in MVP.

## 9. Custom exercise
Minimum field:
- Exercise name

Optional category may be included for organization if it does not create unnecessary setup friction.

## 10. Copy workout
Compact sheet/flow:
- source date/workout summary,
- destination date selector,
- Copy action.

Do not copy completion state.

## 11. Repeat workout
Compact sheet:
- `Repeat weekly`
- cadence fixed to weekly for MVP,
- end choice: 4 weeks / 8 weeks / Until date.

Generated dates become independent workouts.

## 12. History
History is reached by navigating Program to past dates.
Past workout displays completed, incomplete, and skipped sets and current actual values.
Actual values can be edited.

## 13. Authentication
Keep minimal:
- Sign in
- Sign up
- Continue with Google
- Forgot password

After successful authentication, go directly to Today. No onboarding carousel.

## 14. Settings
Simple iOS settings-list pattern:
- Appearance
- Weight unit
- Account
- About/version
- Log out

## 15. Accessibility
- Minimum practical touch targets.
- VoiceOver labels for set state and actions.
- Dynamic Type where layout permits.
- Completion state not color-only.
- Sufficient contrast in both themes.

## 16. UX review checklist
Before accepting any Today change, answer:
1. Does it reduce or preserve the number of taps?
2. Does it add visual information that is unnecessary during the workout?
3. Can the user still complete any set in any order?
4. Does the screen remain understandable at a glance?
5. Does offline state remain non-blocking?
6. Is the secondary action hidden until needed?

If a proposed feature fails these checks, keep it outside Today or outside MVP.
