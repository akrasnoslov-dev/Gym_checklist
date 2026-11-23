(function () {
  const THEMES = Object.freeze(["light", "dark"]);
  const CLASSIFICATIONS = Object.freeze({
    surface: "A. canonical app surface",
    state: "B. state/variant of a canonical surface",
    overlay: "C. overlay / sheet / menu / confirmation",
    qa: "D. QA/review-only route",
  });

  const entry = (id, group, label, classification, parent, trigger, state = {}, components = []) => Object.freeze({
    id, group, label, classification, parent, trigger,
    userVisible: classification !== "qa",
    reviewOnly: classification === "qa",
    themeCoverage: THEMES,
    activation: state.activation || "interaction",
    snapshotId: id,
    components: Object.freeze(components),
    ...state,
  });

  const shared = ["phone-shell", "screen-title", "system-tab-bar"];
  const today = [...shared, "exercise-group", "set-row"];
  const program = [...shared, "calendar", "program-detail", "editor-row"];
  const settings = [...shared, "settings-section", "grouped-list"];
  const auth = ["phone-shell", "auth-screen", "form-card"];

  globalThis.PROTOTYPE_REGISTRY_META = Object.freeze({
    baselineCount: 66,
    frozenCount: 64,
    classifications: CLASSIFICATIONS,
    consolidated: Object.freeze([
      Object.freeze({ id: "settings-appearance", into: "settings-main", reason: "The inline Appearance control is already visible and interactive on Settings." }),
      Object.freeze({ id: "settings-unit", into: "settings-main", reason: "The inline Weight unit control is already visible and interactive on Settings." }),
    ]),
  });

  globalThis.PROTOTYPE_REGISTRY = Object.freeze([
    entry("today-incomplete", "Today", "Workout", "surface", "Today", "Open app → Today", { done: 0 }, today),
    entry("today-partial", "Today", "Partial", "state", "Today", "Today → tap any set", { done: 2 }, today),
    entry("today-completed", "Today", "Completed", "state", "Today", "Today → complete every remaining set", { done: 8 }, today),
    entry("today-exercise-menu", "Today", "Exercise actions", "overlay", "Today", "Today → exercise •••", { done: 2, o: "todayMenu" }, [...today, "context-menu"]),
    entry("today-skipped", "Today", "Multiple skipped", "state", "Today", "Today → exercise ••• → Skip exercise", { done: 2, skipped: 1 }, today),
    entry("today-rest-day", "Today", "Rest day", "state", "Today", "Today → no workout scheduled today", { empty: "rest", activation: "data" }, [...shared, "empty-state"]),
    entry("today-no-program", "Today", "No program", "state", "Today", "Today → no workouts exist", { empty: "none", activation: "data" }, [...shared, "empty-state"]),
    entry("today-set-editor", "Today", "Edit planned set", "overlay", "Today", "Today → press and hold incomplete set", { o: "plan" }, [...today, "sheet"]),
    entry("today-set-editor-actual", "Today", "Edit actual set", "overlay", "Today", "Today → press and hold completed set", { done: 2, o: "actual" }, [...today, "sheet"]),
    entry("today-completion", "Today", "Completion variants", "overlay", "Today", "Today → final required set", { done: 8, o: "complete", activation: "behavior" }, [...today, "completion-overlay"]),
    entry("today-set-editor-lb", "Today", "Edit planned set · lb", "overlay", "Today", "Settings → Weight unit lb → Today → press and hold set", { o: "plan", unit: "lb", activation: "preference" }, [...today, "sheet"]),
    entry("today-set-editor-actual-lb", "Today", "Edit actual set · lb", "overlay", "Today", "Settings → Weight unit lb → Today → press and hold completed set", { done: 2, o: "actual", unit: "lb", activation: "preference" }, [...today, "sheet"]),
    entry("today-set-editor-timed", "Today", "Edit timed set", "overlay", "Today", "Today → press and hold Plank set", { o: "plan", type: "timed" }, [...today, "sheet"]),
    entry("today-set-editor-timed-actual", "Today", "Edit timed actual", "overlay", "Today", "Today → complete Plank → press and hold set", { done: 7, o: "actual", type: "timed" }, [...today, "sheet"]),
    entry("today-set-editor-reps", "Today", "Edit reps-only set", "overlay", "Today", "Today → press and hold Cable Face Pull set", { o: "plan", type: "reps" }, [...today, "sheet"]),
    entry("today-set-editor-reps-actual", "Today", "Edit reps-only actual", "overlay", "Today", "Today → complete Cable Face Pull → press and hold set", { done: 7, o: "actual", type: "reps" }, [...today, "sheet"]),
    entry("today-completion-barely", "Today", "Completion · barely", "overlay", "Today", "Today → final required set → bundled variant", { done: 8, o: "complete", variant: 1, activation: "review-variant" }, [...today, "completion-overlay"]),
    entry("today-completion-another", "Today", "Completion · another", "overlay", "Today", "Today → final required set → bundled variant", { done: 8, o: "complete", variant: 2, activation: "review-variant" }, [...today, "completion-overlay"]),

    entry("program-week", "Program", "Week", "surface", "Program", "Program → Week", { v: "week" }, program),
    entry("program-week-prev", "Program", "Previous week", "state", "Program", "Program → Week → Previous week", { v: "week", week: "prev" }, program),
    entry("program-week-next", "Program", "Next week", "state", "Program", "Program → Week → Next week", { v: "week", week: "next" }, program),
    entry("program-month", "Program", "Month", "state", "Program", "Program → Month", { v: "month" }, program),
    entry("program-month-prev", "Program", "Previous month", "state", "Program", "Program → Month → Previous month", { v: "month", month: "prev" }, program),
    entry("program-month-next", "Program", "Next month", "state", "Program", "Program → Month → Next month", { v: "month", month: "next" }, program),
    entry("program-edit", "Program", "Current workout", "state", "Program", "Program → select current date", { v: "edit" }, program),
    entry("program-history-week-prev", "Program", "Past workout · previous week", "state", "Program", "Program → previous week → select past date", { v: "history", week: "prev", selected: "Friday, September 4 · Past date" }, program),
    entry("program-edit-week-next", "Program", "Selected workout · next week", "state", "Program", "Program → next week → select planned date", { v: "edit", week: "next", selected: "Monday, September 14 · Planned" }, program),
    entry("program-history-month-prev", "Program", "Past workout · previous month", "state", "Program", "Program → previous month → select past date", { v: "history", month: "prev", selected: "Friday, August 28 · Past date" }, program),
    entry("program-edit-month-next", "Program", "Selected workout · next month", "state", "Program", "Program → next month → select planned date", { v: "edit", month: "next", selected: "Thursday, October 1 · Planned" }, program),
    entry("program-add-set", "Program", "Copied weighted set", "state", "Program", "Program → Bench Press → Add set", { v: "edit", add: 1 }, program),
    entry("program-add-timed-set", "Program", "Copied timed set", "state", "Program", "Program → Plank → Add set", { v: "edit", addTimed: 1 }, program),
    entry("program-set-editor", "Program", "Edit plan", "overlay", "Program", "Program → select planned set", { v: "edit", o: "plan" }, [...program, "sheet"]),
    entry("program-completed-plan-editor", "Program", "Edit completed set plan", "overlay", "Program", "Program → completed set → Edit plan", { v: "edit", o: "plan", preserveActual: 1 }, [...program, "sheet"]),
    entry("program-reorder", "Program", "Reorder exercises", "state", "Program", "Program → exercise ••• → Reorder exercises (representative focused reorder scope)", { v: "edit", reorder: 1 }, program),
    entry("program-exercise-menu", "Program", "Exercise actions", "overlay", "Program", "Program → Bench Press → •••", { v: "edit", o: "exercise" }, [...program, "context-menu"]),
    entry("program-set-menu", "Program", "Set actions", "overlay", "Program", "Program → Set 2 → •••", { v: "edit", o: "set" }, [...program, "context-menu"]),
    entry("program-workout-menu", "Program", "Workout actions", "overlay", "Program", "Program → workout •••", { v: "edit", o: "workout" }, [...program, "context-menu"]),
    entry("program-delete-confirm", "Program", "Delete set", "overlay", "Program", "Program → Set 2 ••• → Delete set", { v: "edit", o: "delSet" }, [...program, "alert-card"]),
    entry("program-delete-exercise", "Program", "Delete exercise", "overlay", "Program", "Program → Bench Press ••• → Delete exercise", { v: "edit", o: "delExercise" }, [...program, "alert-card"]),
    entry("program-delete-workout", "Program", "Delete workout", "overlay", "Program", "Program → workout ••• → Delete workout", { v: "edit", o: "delWorkout" }, [...program, "alert-card"]),
    entry("program-history", "Program", "Past workout", "state", "Program", "Program → Week or Month → select Sep 7 past date", { v: "history" }, program),
    entry("program-history-set-editor", "Program", "Edit historical actual", "overlay", "Program", "Program → past date → select actual set", { v: "history", o: "actual" }, [...program, "sheet"]),
    entry("program-set-editor-lb", "Program", "Edit plan · lb", "overlay", "Program", "Settings → Weight unit lb → Program → select set", { v: "edit", o: "plan", unit: "lb", activation: "preference" }, [...program, "sheet"]),
    entry("program-history-set-editor-lb", "Program", "Edit historical actual · lb", "overlay", "Program", "Settings → Weight unit lb → past actual set", { v: "history", o: "actual", unit: "lb", activation: "preference" }, [...program, "sheet"]),
    entry("program-set-editor-timed", "Program", "Edit timed plan", "overlay", "Program", "Program → select planned timed set", { v: "edit", o: "plan", type: "timed" }, [...program, "sheet"]),
    entry("program-history-set-editor-timed", "Program", "Edit timed actual", "overlay", "Program", "Program → past date → select timed actual", { v: "history", o: "actual", type: "timed" }, [...program, "sheet"]),

    entry("exercise-picker", "Workout flows", "Exercise picker", "surface", "Exercise picker", "Program → Add exercise", { v: "picker" }, [...shared, "picker-list"]),
    entry("custom-exercise", "Workout flows", "Custom exercise", "surface", "Custom exercise", "Exercise picker → Add custom exercise", { v: "custom" }, [...shared, "form-card"]),
    entry("copy-workout", "Workout flows", "Copy workout", "surface", "Copy workout", "Program → workout ••• → Copy workout", { v: "copy" }, [...shared, "flow-summary", "date-picker-row"]),
    entry("copy-workout-calendar", "Workout flows", "Copy destination calendar", "overlay", "Copy workout", "Copy workout → Destination date", { v: "copy", cal: 1 }, [...shared, "native-calendar"]),
    entry("repeat-workout", "Workout flows", "Repeat workout", "surface", "Repeat workout", "Program → workout ••• → Repeat workout", { v: "repeat" }, [...shared, "schedule-card"]),
    entry("repeat-workout-until", "Workout flows", "Repeat until date", "state", "Repeat workout", "Repeat workout → Until date", { v: "repeat", until: 1 }, [...shared, "schedule-card", "date-picker-row"]),
    entry("repeat-workout-calendar", "Workout flows", "Repeat calendar", "overlay", "Repeat workout", "Repeat workout → Until date → date picker", { v: "repeat", until: 1, cal: 1 }, [...shared, "schedule-card", "native-calendar"]),

    entry("settings-main", "Settings", "Main Settings", "surface", "Settings", "Settings tab", { v: "settings" }, settings),
    entry("settings-profile", "Settings", "Profile", "surface", "Profile", "Settings → Profile", { v: "profile" }, ["phone-shell", "screen-title", "form-card"]),
    entry("settings-body-weight", "Settings", "Body weight", "surface", "Body weight", "Settings → Body weight", { v: "weight" }, ["phone-shell", "screen-title", "form-card", "grouped-list"]),
    entry("settings-account", "Settings", "Account / deletion", "overlay", "Settings", "Settings → Danger zone → Delete account", { v: "settings", o: "delAccount" }, [...settings, "alert-card"]),

    entry("auth-sign-in", "Authentication", "Sign in", "surface", "Authentication", "Launch while signed out", { v: "auth" }, auth),
    entry("auth-sign-up", "Authentication", "Sign up", "state", "Authentication", "Sign in → Create account", { v: "auth" }, auth),
    entry("auth-reset", "Authentication", "Reset password", "state", "Authentication", "Sign in → Forgot password", { v: "auth" }, auth),

    entry("state-loading", "System / error states", "Loading", "state", "Today", "Today → loading state", { v: "loading", activation: "data" }, [...shared, "empty-state"]),
    entry("state-offline", "System / error states", "Offline cached Today", "state", "Today", "Today → cached offline state", { done: 1, offline: 1, activation: "data" }, today),
    entry("state-error", "System / error states", "Error", "state", "Program", "Program → load error", { v: "error", activation: "data" }, [...shared, "alert-card"]),
    entry("state-disabled", "System / error states", "Disabled", "state", "Settings", "Settings → destructive disabled state", { v: "settings", o: "delAccount", activation: "data" }, [...settings, "alert-card"]),
  ]);
}());
