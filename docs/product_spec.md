# Gym Checklist — Product Specification (MVP)

## 1. Product goal
Gym Checklist is a minimalist iOS app for people who already know their workout plan and want to execute it with almost no thinking or navigation.

Primary flow:

```text
Open app -> Today -> mark completed sets -> close app
```

The product differentiator for MVP is simplicity, not feature count.

## 2. Product principles
1. Today opens first after login.
2. One tap completes a set.
3. No mandatory Start Workout flow.
4. Roughly 90% of workout-time interactions should happen on Today.
5. Secondary actions are hidden behind long press, context actions, or deeper Program screens.
6. Today must not contain unnecessary analytics or coaching.
7. Cached workouts must remain usable offline.

## 3. MVP scope
### In scope
- iOS only, English only.
- Authentication: email/password and Google.
- Today checklist by current local calendar date.
- Program calendar with past/future weeks.
- One workout maximum per date.
- Exercises with arbitrary sets, reps, weight and/or time.
- Searchable built-in exercise list plus custom exercises.
- Copy workout to another date.
- Simple weekly repeat that generates independent future workouts.
- One-tap set completion and undo.
- Long-press editing of set values/actual values.
- Skip/restore exercise.
- Historical workout viewing and actual editing.
- Rest day and empty-program states.
- Workout-complete motivational popup.
- System/Light/Dark theme.
- kg/lb setting.
- Offline persistence/sync.
- Minimal analytics and crash reporting.

### Out of scope
- AI coaching or workout generation.
- Recommendations and automatic progression.
- Statistics/charts/PR dashboards.
- Apple Watch, HealthKit, widgets, Live Activities.
- Exercise images/videos/instructions.
- Rest timers.
- Social features, sharing, leaderboards.
- Nutrition/body measurements.
- Payments/subscriptions.
- Multiple workouts per date.
- Android/web.

## 4. Navigation
Top-level tabs:
- Today
- Program
- Settings

After authentication, Today is always the initial tab.

## 5. Today
### Active workout
Vertically scrollable list grouped by exercise. Each set is one independent row.

Examples:
- `8 reps × 60 kg`
- `12 reps`
- `45 sec`

Tap incomplete set -> completed.
Tap completed set -> incomplete.
No modal, confirmation, or navigation for normal completion.

Sets and exercises may be completed in any order.

### Long press
Long press on a set opens a compact editor (prefer bottom sheet/context-driven sheet, not a full navigation flow).
- Before completion: edits current planned values.
- After completion: edits actual values.
- Completed state remains completed unless explicitly undone.

### Skip exercise
Secondary action on an exercise:
- hides it from active Today,
- preserves it as skipped/incomplete in history,
- can be restored during that day.

### Completion
Workout is complete when every remaining non-skipped required set is completed and all other exercises are explicitly skipped.

On completion show a dismissible overlay/popup with short emotional or meme-like encouragement. No navigation to a dedicated completion screen.

### Empty states
No workouts exist yet:
- `No workout planned yet.`
- CTA: `Create workout`

No workout for today but program exists:
- `Rest day.`
- `See you tomorrow.`
- Secondary CTA: `View program`

## 6. Program and calendar
Workouts belong to concrete dates, not abstract weekdays.

Week navigation example:
`< Aug 10 – Aug 16 >`
with seven date selectors.

Users can navigate past and future weeks.

A day can be:
- empty,
- planned,
- partial,
- completed,
- incomplete/skipped.

Program supports create/edit/delete workout and exercise/set ordering.

## 7. Workout creation
Workout contains ordered exercises.
Each exercise contains ordered sets.
Each set can have arbitrary values; sets in the same exercise do not have to match.

Convenience behavior: adding a new set may copy values from the previous set by default.

## 8. Exercise selection
Exercise picker includes:
- search field,
- bundled system exercise list,
- `Add custom exercise`.

Custom exercise requires a name and is saved to the user library for reuse.

System categories may exist for organization (Chest, Back, Legs, Shoulders, Biceps, Triceps, Core, Cardio/Other) but are not required on Today.

## 9. Set data and display rules
Canonical set fields:
- reps
- weight
- timeSeconds

User explicitly enters technical values even when zero/one is used for model consistency.

Display hides values that do not help the user:
- weight > 0, time = 0 -> `8 reps × 60 kg`
- weight = 0, time = 0 -> `12 reps`
- time > 0 with non-meaningful reps/weight -> `45 sec`

Do not show `0 kg` or meaningless `1 rep` just because the data model contains it.

## 10. Planned and actual behavior
There is no separate historical analytics concept comparing an immutable original plan with actual performance.

Before completion, set values are current planned values.
On completion, actual values are initialized from current values.
Actual values can then be edited.

Program changes propagate to Today immediately for not-yet-completed sets.
Completed actual values must not be silently overwritten by later Program edits.

Historical actual values may be edited.

## 11. Copy workout
Copy workout:
- choose destination date,
- copy exercises/order/sets/reps/weight/time,
- do not copy completion/history,
- destination is fully independent afterward.

## 12. Repeat workout
MVP uses simple repeat generation, not a persistent complex template engine.

Preferred interaction:
- `Repeat weekly`
- choose duration such as 4 weeks, 8 weeks, or Until date.

The feature generates independent future workout records.

## 13. Settings
Minimum:
- Appearance: System / Light / Dark
- Weight unit: kg / lb
- Account
- Logout
- App version / policy links as needed

## 14. Authentication
- Register with email/password.
- Login with email/password.
- Google Sign-In.
- Forgot password.
- Logout.
- No onboarding; after first login go directly to Today.

Before public App Store submission, verify whether Sign in with Apple is required under current App Review rules because Google Sign-In is offered.

## 15. Offline requirements
If cached data exists, user must be able to:
- open Today,
- complete/undo sets,
- edit actual values,
- skip/restore exercise
without network access.

Writes should apply locally immediately and sync automatically when connectivity returns. No manual Sync button.

Network/sync errors should be non-blocking whenever local workout data is available.

## 16. Critical acceptance criteria
- App launches to Today for authenticated user.
- Today's workout is visible without Start Workout action.
- One tap toggles a set immediately.
- Set completion does not navigate away or open confirmation.
- Long press allows compact editing.
- Arbitrary completion order is allowed.
- Workout works offline when cached.
- Copy creates independent destination workout.
- Past actual results are viewable/editable.
- Final required set triggers motivational popup.

## 17. MVP definition of done
Functional MVP is complete when authentication, Program creation/editing, exercise selection, Today execution, actual editing, skip/restore, copy, repeat, history, offline behavior, themes, units, motivational completion, analytics/crash reporting, automated build/tests, and TestFlight-ready release plumbing are implemented and verified.
