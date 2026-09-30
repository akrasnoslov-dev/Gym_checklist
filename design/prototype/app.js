const screens = [
  { id: "today-incomplete", group: "Today", label: "Incomplete", tab: "today", type: "today", done: 0 },
  { id: "today-partial", group: "Today", label: "Partial", tab: "today", type: "today", done: 3 },
  { id: "today-completed", group: "Today", label: "Completed", tab: "today", type: "today", done: 7 },
  { id: "today-exercise-menu", group: "Today", label: "Exercise actions", tab: "today", type: "today", done: 3, overlay: "exercise-menu" },
  { id: "today-skipped", group: "Today", label: "Skipped / restore", tab: "today", type: "today", done: 3, skipped: true },
  { id: "today-rest-day", group: "Today", label: "Rest day", tab: "today", type: "empty", state: "rest" },
  { id: "today-no-program", group: "Today", label: "No program", tab: "today", type: "empty", state: "no-program" },
  { id: "today-set-editor", group: "Today", label: "Long-press planned set editor", tab: "today", type: "today", done: 0, overlay: "editor-planned" },
  { id: "today-set-editor-actual", group: "Today", label: "Long-press actual set editor", tab: "today", type: "today", done: 3, overlay: "editor-actual" },
  { id: "today-completion", group: "Today", label: "Workout completion overlay", tab: "today", type: "today", done: 7, overlay: "completion" },
  { id: "program-week", group: "Program", label: "Week", tab: "program", type: "week" },
  { id: "program-month", group: "Program", label: "Month", tab: "program", type: "month" },
  { id: "program-edit", group: "Program", label: "Selected-date editing", tab: "program", type: "edit" },
  { id: "program-add-set", group: "Program", label: "Add set", tab: "program", type: "edit", addedSet: true },
  { id: "program-set-editor", group: "Program", label: "Edit set", tab: "program", type: "edit", overlay: "set-editor" },
  { id: "program-exercise-menu", group: "Program", label: "Exercise actions", tab: "program", type: "edit", overlay: "exercise-menu" },
  { id: "program-set-menu", group: "Program", label: "Set actions", tab: "program", type: "edit", overlay: "set-menu" },
  { id: "program-workout-menu", group: "Program", label: "Workout actions", tab: "program", type: "edit", overlay: "workout-menu" },
  { id: "program-delete-confirm", group: "Program", label: "Delete set confirmation", tab: "program", type: "edit", overlay: "delete-confirm", deleteTarget: "set" },
  { id: "program-delete-exercise", group: "Program", label: "Delete exercise confirmation", tab: "program", type: "edit", overlay: "delete-confirm", deleteTarget: "exercise" },
  { id: "program-delete-workout", group: "Program", label: "Delete workout confirmation", tab: "program", type: "edit", overlay: "delete-confirm", deleteTarget: "workout" },
  { id: "program-history", group: "Program", label: "Historical workout editing", tab: "program", type: "history" },
  { id: "program-history-set-editor", group: "Program", label: "Historical actual editor", tab: "program", type: "history", overlay: "actual-set-editor" },
  { id: "exercise-picker", group: "Workout flows", label: "Exercise picker", tab: "program", type: "picker" },
  { id: "custom-exercise", group: "Workout flows", label: "Custom exercise", tab: "program", type: "custom" },
  { id: "copy-workout", group: "Workout flows", label: "Copy workout", tab: "program", type: "copy" },
  { id: "repeat-workout", group: "Workout flows", label: "Repeat workout", tab: "program", type: "repeat" },
  { id: "repeat-workout-until", group: "Workout flows", label: "Repeat until date", tab: "program", type: "repeat", untilDate: true },
  { id: "settings-main", group: "Settings", label: "Main Settings", tab: "settings", type: "settings" },
  { id: "settings-profile", group: "Settings", label: "Profile", tab: "settings", type: "profile" },
  { id: "settings-body-weight", group: "Settings", label: "Body-weight history", tab: "settings", type: "weight" },
  { id: "settings-appearance", group: "Settings", label: "Appearance", tab: "settings", type: "preference", preference: "Appearance", choices: ["System", "Light", "Dark"] },
  { id: "settings-unit", group: "Settings", label: "Weight unit", tab: "settings", type: "preference", preference: "Weight unit", choices: ["kg", "lb"] },
  { id: "settings-account", group: "Settings", label: "Account / destructive", tab: "settings", type: "account" },
  { id: "auth-sign-in", group: "Authentication", label: "Sign in", tab: "auth", type: "auth", auth: "Sign in" },
  { id: "auth-sign-up", group: "Authentication", label: "Sign up", tab: "auth", type: "auth", auth: "Create account" },
  { id: "auth-reset", group: "Authentication", label: "Reset password", tab: "auth", type: "auth", auth: "Reset password" },
  { id: "state-loading", group: "Representative states", label: "Loading", tab: "today", type: "loading" },
  { id: "state-offline", group: "Representative states", label: "Offline cached Today", tab: "today", type: "offline" },
  { id: "state-error", group: "Representative states", label: "Error", tab: "program", type: "error" },
  { id: "state-disabled", group: "Representative states", label: "Disabled / destructive", tab: "settings", type: "disabled" }
];

const workout = [
  ["Bench Press", ["8 reps × 60 kg", "8 reps × 60 kg", "6 reps × 60 kg"]],
  ["Barbell Row", ["10 reps × 50 kg", "10 reps × 50 kg"]],
  ["Cable Face Pull", ["12 reps × 26 kg", "12 reps × 26 kg"]]
];

const app = document.querySelector("#app");
const picker = document.querySelector("#screen-picker");
const shortcuts = document.querySelector("#screen-shortcuts");
const galleryRoot = document.querySelector("#gallery-root");
const galleryButton = document.querySelector("#gallery-mode");
let current = screens[1];
let galleryMode = false;
let longPressTimer;
let pickerQuery = "";

function route(label, id, style) {
  return "<button type=\"button\" class=\"button button-" + (style || "secondary") + "\" data-route=\"" + id + "\">" + label + "</button>";
}

function heading(name, detail, action) {
  return "<header class=\"screen-title\"><div><h2>" + name + "</h2>" + (detail ? "<p>" + detail + "</p>" : "") + "</div>" + (action || "") + "</header>";
}

function todayRows(done, skippedName) {
  let number = 0;
  return workout.filter(function (exercise) { return exercise[0] !== skippedName; }).map(function (exercise) {
    const rows = exercise[1].map(function (value, index) {
      number += 1;
      const completed = number <= done;
      const editorRoute = completed ? "today-set-editor-actual" : "today-set-editor";
      return "<div class=\"set-row-wrap\"><button class=\"set-row " + (completed ? "is-completed" : "") + "\" data-set data-action=\"long-press-editor\" data-editor=\"" + editorRoute + "\" data-set-name=\"" + exercise[0] + "\" data-set-number=\"" + (index + 1) + "\" data-set-value=\"" + value + "\" aria-keyshortcuts=\"Shift+F10\" aria-pressed=\"" + completed + "\" aria-label=\"" + exercise[0] + ", set " + (index + 1) + ": " + value + ", " + (completed ? "completed. Tap to mark incomplete; press and hold or use Shift+F10 to edit actual results." : "incomplete. Tap to complete; press and hold or use Shift+F10 to edit planned values.") + "\"><span class=\"completion-icon\" aria-hidden=\"true\"></span><span>" + value + "</span></button></div>";
    }).join("");
    return "<section class=\"exercise-group\"><header class=\"exercise-header\"><h3>" + exercise[0] + "</h3><button class=\"icon-button native-intent\" data-route=\"today-exercise-menu\" aria-label=\"" + exercise[0] + " actions\">•••</button></header><div class=\"set-list\">" + rows + "</div></section>";
  }).join("");
}

function today(screen) {
  let extra = screen.skipped ? "<button class=\"restore-row native-intent\" data-route=\"today-incomplete\" aria-label=\"Restore Barbell Row\"><span>Skipped exercises</span><span>Restore Barbell Row</span></button>" : "";
  if (screen.overlay === "editor-planned" || screen.overlay === "editor-actual") extra += editorOverlay(screen.overlay === "editor-actual");
  if (screen.overlay === "exercise-menu") extra += exerciseMenu();
  if (screen.overlay === "completion") extra += completionOverlay();
  return heading("Today", "Tuesday, September 8") + "<div class=\"workout-list\">" + todayRows(screen.done, screen.skipped ? "Barbell Row" : "") + extra + "</div>";
}

function empty(screen) {
  const rest = screen.state === "rest";
  return heading("Today", "Tuesday, September 8") + "<section class=\"empty-state app-owned\"><span class=\"empty-symbol\" aria-hidden=\"true\">" + (rest ? "☀" : "✓") + "</span><h3>" + (rest ? "Rest day." : "No program yet.") + "</h3><p>" + (rest ? "Your program has workouts, just none scheduled for today." : "You have no workouts in your program. Create your first one when you are ready.") + "</p>" + route(rest ? "View program" : "Create workout", "program-week", "primary") + "</section>";
}

function editorOverlay(actual) {
  const titleText = actual ? "Edit actual" : "Edit set";
  const note = actual ? "Actual results · completed set stays completed" : "Planned set · before completion";
  return "<div class=\"sheet-scrim\"><section class=\"sheet native-intent\" aria-label=\"Native bottom sheet: compact " + (actual ? "actual" : "planned") + " set editor\"><div class=\"sheet-grabber\"></div><header><button data-route=\"today-partial\">Cancel</button><h3>" + titleText + "</h3><button class=\"accent-action\" data-route=\"today-partial\">Save</button></header><p>" + note + "</p><div class=\"form-card\"><label>Reps<input value=\"8\"></label><label>Weight<input value=\"60 kg\"></label></div></section></div>";
}

function exerciseMenu() {
  return "<div class=\"menu-scrim\"><section class=\"context-menu native-intent\" aria-label=\"Native exercise actions\"><button data-route=\"today-skipped\">Skip exercise</button><button data-route=\"today-partial\">Cancel</button></section></div>";
}

function completionOverlay() {
  return "<div class=\"sheet-scrim\"><section class=\"completion-overlay app-owned\"><div class=\"gym-illustration\" aria-hidden=\"true\"><span>🏋</span><i>●━━━━●</i></div><h3>You crushed it!</h3><p>Gym survived. Barely.</p>" + route("Done", "today-completed", "primary") + "</section></div>";
}

function calendarLegend() {
  return "<div class=\"calendar-legend\"><span class=\"state-empty\">○ Empty</span><span class=\"state-planned\">• Planned</span><span class=\"state-partial\">◐ Partial</span><span class=\"state-completed\">✓ Completed</span><span class=\"state-incomplete\">! Incomplete</span></div>";
}

function dayStrip() {
  const dates = [["M", "7", "Empty", "○"], ["T", "8", "Partial", "◐"], ["W", "9", "Planned", "•"], ["T", "10", "Completed", "✓"], ["F", "11", "Incomplete", "!"], ["S", "12", "Empty", "○"], ["S", "13", "Empty", "○"]];
  return "<div class=\"day-strip\">" + dates.map(function (item, index) {
    const stateClass = "state-" + item[2].toLowerCase();
    return "<button class=\"day-cell " + stateClass + " " + (index === 1 ? "is-selected is-today" : "") + "\" aria-label=\"September " + item[1] + ", " + item[2] + (index === 1 ? ", today and selected" : "") + "\"><span>" + item[0] + "</span><strong>" + item[1] + "</strong><i aria-hidden=\"true\">" + item[3] + "</i></button>";
  }).join("") + "</div>";
}

function setEditorRow(number, label, routeId, actual, actions) {
  const row = routeId ? "<button class=\"editor-row " + (actual ? "is-completed" : "") + "\" data-route=\"" + routeId + "\"><span>" + number + "</span><strong>" + label + "</strong><em>" + (actual ? "Edit actual" : "Edit") + "</em></button>" : "<div class=\"editor-row " + (actual ? "is-completed" : "") + "\"><span>" + number + "</span><strong>" + label + "</strong><em>Recorded</em></div>";
  return "<div class=\"editor-row-wrap\">" + row + (actions ? "<button class=\"editor-more\" data-route=\"program-set-menu\" aria-label=\"Set " + number + " actions\">•••</button>" : "") + "</div>";
}

function detail(historical, editable, addedSet) {
  const actual = historical ? "7 reps × 65 kg · actual" : "8 reps × 60 kg";
  const actualRoute = historical ? "program-history-set-editor" : "program-set-editor";
  const rows = setEditorRow(1, "8 reps × 60 kg" + (historical ? " · planned" : ""), historical ? "" : "program-set-editor", false, !historical) + setEditorRow(2, actual, actualRoute, true, !historical) + setEditorRow(3, "6 reps × 60 kg" + (historical ? " · planned" : ""), historical ? "" : "program-set-editor", false, !historical) + (addedSet ? setEditorRow(4, "New set · choose reps and weight", "program-set-editor", false, true) : "");
  return "<section class=\"program-detail\"><p class=\"selected-date-label\">" + (historical ? "Friday, September 4 · Past date" : "Tuesday, September 8") + "</p><section class=\"program-exercise\"><header><h3>Bench Press</h3>" + (historical ? "" : "<button class=\"icon-button native-intent\" data-route=\"program-exercise-menu\" aria-label=\"Bench Press actions\">•••</button>") + "</header><div class=\"editor-list\">" + rows + "</div>" + (editable ? "<div class=\"exercise-local-action\">" + route("Add set", "program-add-set") + "</div>" : "") + "</section></section>";
}

function week() {
  return heading("Program", "", "<button class=\"add-button\" data-route=\"program-edit\" aria-label=\"Edit selected workout\">+</button>") + "<div class=\"segmented native-intent\"><button class=\"is-selected\">Week</button><button data-route=\"program-month\">Month</button></div><div class=\"calendar-nav native-intent\"><button aria-label=\"Previous week\">‹</button><strong>Sep 7 – Sep 13</strong><button aria-label=\"Next week\">›</button></div>" + dayStrip() + calendarLegend() + detail(false, false);
}

function month() {
  const dayNames = ["M", "T", "W", "T", "F", "S", "S"].map(function (day) { return "<span>" + day + "</span>"; }).join("");
  const states = { 1: ["Planned", "•"], 8: ["Partial", "◐"], 11: ["Completed", "✓"], 18: ["Incomplete", "!"] };
  const cells = Array.from({ length: 35 }, function (_, i) {
    const day = i === 0 ? 31 : i <= 30 ? i : i - 30;
    const monthName = i === 0 ? "August" : i > 30 ? "October" : "September";
    const status = states[i] || ["Empty", "○"];
    const today = i === 8;
    return "<button class=\"state-" + status[0].toLowerCase() + " " + (today ? "is-selected is-today " : "") + (i === 0 || i > 30 ? "is-muted" : "") + "\" aria-label=\"" + monthName + " " + day + ", " + status[0] + (today ? ", today and selected" : "") + "\">" + day + "<i aria-hidden=\"true\">" + status[1] + "</i></button>";
  }).join("");
  return heading("Program") + "<div class=\"segmented native-intent\"><button data-route=\"program-week\">Week</button><button class=\"is-selected\">Month</button></div><div class=\"calendar-nav native-intent\"><button aria-label=\"Previous month\">‹</button><strong>September 2026</strong><button aria-label=\"Next month\">›</button></div><section class=\"month-grid\">" + dayNames + cells + "</section>" + calendarLegend() + detail(false, false);
}

function programMenu(kind) {
  const actions = kind === "exercise-menu" ? [["Move exercise", "program-edit"], ["Delete exercise", "program-delete-exercise"]] : kind === "set-menu" ? [["Move set", "program-edit"], ["Delete set", "program-delete-confirm"]] : [["Copy workout", "copy-workout"], ["Repeat workout", "repeat-workout"], ["Delete workout", "program-delete-workout"]];
  return "<div class=\"menu-scrim\"><section class=\"context-menu native-intent\" aria-label=\"Native " + kind.replace("-", " ") + "\">" + actions.map(function (action) { return "<button class=\"" + (action[0].indexOf("Delete") === 0 ? "is-destructive" : "") + "\" data-route=\"" + action[1] + "\">" + action[0] + "</button>"; }).join("") + "<button data-route=\"program-edit\">Cancel</button></section></div>";
}

function setSheet(actual, returnRoute) {
  const title = actual ? "Edit actual" : "Edit set";
  const note = actual ? "Actual result · saved workout history stays intact" : "Planned set";
  const destination = returnRoute || "program-edit";
  return "<div class=\"sheet-scrim\"><section class=\"sheet native-intent\" aria-label=\"Native bottom sheet: " + title + "\"><div class=\"sheet-grabber\"></div><header><button data-route=\"" + destination + "\">Cancel</button><h3>" + title + "</h3><button class=\"accent-action\" data-route=\"" + destination + "\">Save</button></header><p>" + note + "</p><div class=\"form-card\"><label>Reps<input value=\"" + (actual ? "7" : "8") + "\"></label><label>Weight<input value=\"" + (actual ? "65 kg" : "60 kg") + "\"></label></div></section></div>";
}

function deleteConfirm(target) {
  const copy = {
    set: ["Delete this set?", "This removes Set 2 from Bench Press. This can’t be undone.", "Delete set"],
    exercise: ["Delete Bench Press?", "This removes Bench Press and its 3 planned sets. This can’t be undone.", "Delete exercise"],
    workout: ["Delete this workout?", "This removes the workout scheduled for Tuesday, September 8. This can’t be undone.", "Delete workout"]
  }[target || "set"];
  return "<div class=\"menu-scrim\"><section class=\"alert-card native-intent\" aria-label=\"Native delete confirmation\"><span class=\"error-symbol\">!</span><h3>" + copy[0] + "</h3><p>" + copy[1] + "</p><div>" + route("Cancel", "program-edit") + "<button class=\"button button-destructive\" data-route=\"program-edit\">" + copy[2] + "</button></div></section></div>";
}

function edit(screen) {
  let overlay = "";
  if (screen.overlay === "set-editor") overlay = setSheet(false);
  if (["exercise-menu", "set-menu", "workout-menu"].includes(screen.overlay)) overlay = programMenu(screen.overlay);
  if (screen.overlay === "delete-confirm") overlay = deleteConfirm(screen.deleteTarget);
  return heading("Program", "Tuesday, September 8", "<button class=\"icon-button native-intent\" data-route=\"program-workout-menu\" aria-label=\"Workout actions\">•••</button>") + "<section class=\"program-editor\"><div class=\"editor-toolbar\">" + route("Add exercise", "exercise-picker", "primary") + "</div>" + detail(false, true, screen.addedSet) + "</section>" + overlay;
}

function history(screen) {
  const overlay = screen.overlay === "actual-set-editor" ? setSheet(true, "program-history") : "";
  return heading("Program", "Past date selected") + "<div class=\"segmented native-intent\"><button class=\"is-selected\">Week</button><button data-route=\"program-month\">Month</button></div><div class=\"history-path\"><span>Program</span><b>→</b><span>Friday, September 4</span></div><p class=\"history-note\">Recorded results stay editable. Planning changes never overwrite completed actual results.</p>" + detail(true, false) + overlay;
}

function pickerView() {
  const catalogue = [["Bench Press", "Chest"], ["Incline Dumbbell Press", "Chest"], ["Push-Up", "Chest"], ["Cable Fly", "Chest"], ["Pull-Up", "Back"], ["Lat Pulldown", "Back"], ["Barbell Row", "Back"], ["Seated Cable Row", "Back"], ["Back Squat", "Legs"], ["Front Squat", "Legs"], ["Romanian Deadlift", "Legs"], ["Leg Press", "Legs"], ["Walking Lunge", "Legs"], ["Standing Calf Raise", "Legs"], ["Overhead Press", "Shoulders"], ["Dumbbell Lateral Raise", "Shoulders"], ["Reverse Fly", "Shoulders"], ["Arnold Press", "Shoulders"], ["Barbell Curl", "Biceps"], ["Dumbbell Curl", "Biceps"], ["Hammer Curl", "Biceps"], ["Preacher Curl", "Biceps"], ["Cable Triceps Pushdown", "Triceps"], ["Skull Crusher", "Triceps"], ["Overhead Triceps Extension", "Triceps"], ["Close-Grip Bench Press", "Triceps"], ["Plank", "Core"], ["Hanging Knee Raise", "Core"], ["Cable Crunch", "Core"], ["Russian Twist", "Core"], ["Treadmill Run", "Cardio/Other"], ["Stationary Bike", "Cardio/Other"], ["Rowing Machine", "Cardio/Other"], ["Elliptical", "Cardio/Other"]];
  const visible = catalogue.filter(function (item) { return item[0].toLowerCase().includes(pickerQuery.toLowerCase()); });
  const rows = visible.length ? visible.map(function (item) { return "<button class=\"picker-row\" data-route=\"program-edit\"><span><strong>" + item[0] + "</strong><em>" + item[1] + "</em></span><b>+</b></button>"; }).join("") : "<p class=\"empty-list\">No system exercises match this search.</p>";
  return heading("Add exercise", "", "<button class=\"text-button\" data-route=\"program-edit\">Cancel</button>") + "<label class=\"search native-intent\" aria-label=\"Native searchable list\">⌕ <input data-picker-search value=\"" + pickerQuery + "\" placeholder=\"Search exercises\" aria-label=\"Search exercises\"></label><p class=\"list-label\">EXERCISES · " + visible.length + " OF " + catalogue.length + "</p><section class=\"grouped-list picker-list\">" + rows + "</section>" + route("Add custom exercise", "custom-exercise");
}

function custom() {
  return heading("Custom exercise", "", "<button class=\"text-button\" data-route=\"exercise-picker\">Cancel</button>") + "<section class=\"form-card native-intent\" aria-label=\"Native focused form\"><label>Exercise name<input placeholder=\"e.g. Romanian Deadlift\" aria-label=\"Exercise name\"></label></section>" + route("Add", "program-edit", "primary");
}

function flow(screen) {
  const copy = screen.type === "copy";
  if (copy) return heading("Copy workout", "", "<button class=\"text-button\" data-route=\"program-edit\">Cancel</button>") + "<p class=\"form-label\">SOURCE</p><section class=\"flow-summary\"><span>▣</span><div><strong>Tuesday, September 8</strong><p>3 exercises · 7 sets</p></div></section><p class=\"form-label\">DESTINATION</p><section class=\"form-card\"><button class=\"date-picker-row native-intent\" aria-label=\"native DatePicker intent: Destination date\"><span>Destination date</span><strong>▣ Sep 15, 2026</strong></button><p>Creates an independent planned workout. Completion and history are not copied. The destination cannot be the source date or overwrite an existing workout.</p></section>" + route("Copy", "program-week", "primary");
  const until = screen.untilDate;
  return heading("Repeat workout", "", "<button class=\"text-button\" data-route=\"program-edit\">Cancel</button>") + "<p class=\"form-label\">SOURCE WORKOUT</p><section class=\"flow-summary\"><span>↻</span><div><strong>Tuesday, September 8</strong><p>3 exercises · 7 sets</p></div></section><section class=\"schedule-card native-intent\" aria-label=\"Native segmented picker intent\"><p>Cadence</p><div class=\"compact-segmented\"><button class=\"is-selected\">Every 1 week</button><button>2 weeks</button><button>3 weeks</button><button>4 weeks</button></div><p>Duration</p><div class=\"compact-segmented three\"><button class=\"" + (until ? "" : "is-selected") + "\">4 weeks</button><button>8 weeks</button><button class=\"" + (until ? "is-selected" : "") + "\" data-route=\"repeat-workout-until\">Until date</button></div>" + (until ? "<button class=\"date-picker-row native-intent\" aria-label=\"native DatePicker intent: Repeat until\"><span>Repeat until</span><strong>▣ Oct 27, 2026</strong></button>" : "") + "</section><p class=\"form-label\">RESULT</p><section class=\"result-card\">" + (until ? "7" : "4") + " independent workouts will be created. Existing workouts are not replaced.</section>" + route("Create", "program-week", "primary");
}

function settings() {
  return heading("Settings") + settingsSection("Profile", settingsRow("Profile", "Optional details ›", "settings-profile")) + settingsSection("Body weight", settingsRow("Body weight", "80 kg ›", "settings-body-weight")) + settingsSection("Preferences", settingsRow("Appearance", "System ›", "settings-appearance") + settingsRow("Weight unit", "kg ›", "settings-unit")) + settingsSection("Account", settingsRow("Account", "›", "settings-account"));
}

function settingsSection(label, rows) {
  return "<section class=\"settings-section\"><p>" + label + "</p><div class=\"grouped-list\">" + rows + "</div></section>";
}

function settingsRow(label, value, routeId) {
  return "<button class=\"settings-row\" data-route=\"" + routeId + "\"><span>" + label + "</span><em>" + value + "</em></button>";
}

function profile() {
  return heading("Profile") + "<section class=\"form-card native-intent\"><label>Sex<select><option>Prefer not to say</option></select></label><label>Date of birth<input value=\"Optional\"></label><label>Height<input value=\"180 cm\"></label></section><section class=\"info-card\"><strong>BMI 25.0</strong><span>Neutral information based on your latest body weight.</span></section>" + route("Save", "settings-main", "primary");
}

function weight() {
  return heading("Body weight", "Stored in kg") + "<section class=\"grouped-list native-intent\"><button class=\"settings-row\"><span>September 2, 2026</span><em>80 kg · swipe to delete</em></button><button class=\"settings-row\"><span>September 1, 2026</span><em>81 kg · swipe to delete</em></button></section>" + route("Add body weight", "settings-body-weight");
}

function preference(screen) {
  return heading(screen.preference) + "<section class=\"preference-options native-intent\" aria-label=\"Native picker\">" + screen.choices.map(function (choice, index) { return "<button class=\"preference-row " + (index === 0 ? "is-selected" : "") + "\"><span>" + choice + "</span><b>" + (index === 0 ? "✓" : "") + "</b></button>"; }).join("") + "</section>";
}

function account() {
  return heading("Account") + "<section class=\"account-card\"><p>andrei@example.com</p>" + route("Log out", "auth-sign-in") + "</section>" + settingsSection("Danger zone", "<button class=\"destructive-row native-intent\" data-route=\"state-disabled\"><span>Delete account</span><em>›</em></button>") + "<p class=\"danger-note\">Deletion is separate from preferences and requires clear confirmation.</p>";
}

function auth(screen) {
  const reset = screen.auth === "Reset password";
  const signup = screen.auth === "Create account";
  const titleText = screen.auth;
  const copy = reset ? "We’ll send a reset link if this email has an account." : signup ? "Start with the plan you already know." : "Your workout is ready when you are.";
  const fields = "<label>Email<input placeholder=\"name@example.com\"></label>" + (reset ? "" : "<label>Password<input type=\"password\" placeholder=\"" + (signup ? "At least 6 characters" : "Password") + "\"></label>");
  const action = reset ? "Send reset link" : titleText;
  const links = reset ? "<button class=\"text-link\" data-route=\"auth-sign-in\">Back to sign in</button>" : "<button class=\"text-link\" data-route=\"auth-reset\">Forgot password?</button><button class=\"text-link\" data-route=\"" + (signup ? "auth-sign-in" : "auth-sign-up") + "\">" + (signup ? "Already have an account? Sign in" : "Create account") + "</button>";
  return "<section class=\"auth-screen\"><div class=\"auth-mark\">✓</div><h2>" + titleText + "</h2><p>" + copy + "</p><section class=\"auth-form native-intent\">" + fields + "</section>" + route(action, reset ? "auth-sign-in" : "today-partial", "primary") + (reset ? "" : "<div class=\"auth-divider\"><span>or</span></div><button class=\"google-button native-intent\">G <span>Continue with Google</span></button>") + links + "</section>";
}

function state(screen) {
  if (screen.type === "offline") return heading("Today", "Tuesday, September 8") + "<div class=\"offline-banner\">⌁ <span>Offline — changes will sync when you reconnect.</span></div><div class=\"workout-list\">" + todayRows(3) + "</div>";
  if (screen.type === "loading") return heading("Today") + "<section class=\"loading-state\"><span class=\"spinner\"></span><p>Loading workout</p></section>";
  if (screen.type === "error") return heading("Program") + "<section class=\"empty-state\"><span class=\"error-symbol\">!</span><h3>Couldn’t load program.</h3><p>Your workout data is unavailable right now.</p>" + route("Try again", "program-week", "primary") + "</section>";
  return heading("Delete account") + "<section class=\"alert-card native-intent\"><span class=\"error-symbol\">!</span><h3>Delete account?</h3><p>This removes your account and workout data. This action cannot be undone.</p><div>" + route("Cancel", "settings-account") + "<button class=\"button button-destructive\" disabled>Delete account</button></div></section>";
}

function screenMarkup(screen) {
  const view = { today: today, empty: empty, week: week, month: month, edit: edit, history: history, picker: pickerView, custom: custom, copy: flow, repeat: flow, settings: settings, profile: profile, weight: weight, preference: preference, account: account, auth: auth, loading: state, offline: state, error: state, disabled: state };
  return view[screen.type](screen);
}

function galleryPhone(screen) {
  return "<section class=\"phone-shell gallery-phone\" aria-label=\"iPhone-sized " + screen.label + "\"><div class=\"system-status\" aria-hidden=\"true\"><span>9:41</span><span class=\"status-icons\">● ● ●</span></div><div class=\"app-content\">" + screenMarkup(screen) + "</div><nav class=\"system-tab-bar native-intent\" aria-label=\"Native primary tab navigation\"><button class=\"tab-item " + (screen.tab === "today" ? "is-selected" : "") + "\"><span>✓</span><span>Today</span></button><button class=\"tab-item " + (screen.tab === "program" ? "is-selected" : "") + "\"><span>▦</span><span>Program</span></button><button class=\"tab-item " + (screen.tab === "settings" ? "is-selected" : "") + "\"><span>⚙</span><span>Settings</span></button></nav></section>";
}

function galleryIntent(screen) {
  if (screen.overlay) return "Native intent: compact sheet, menu, or confirmation.";
  if (screen.type === "copy" || screen.untilDate) return "Native intent: DatePicker.";
  if (screen.type === "repeat" || screen.type === "week" || screen.type === "month") return "Native intent: segmented picker and date navigation.";
  if (screen.type === "picker" || screen.type === "preference") return "Native intent: searchable list or picker.";
  return "Native intent: primary navigation where applicable.";
}

function render() {
  picker.value = current.id;
  const view = { today: today, empty: empty, week: week, month: month, edit: edit, history: history, picker: pickerView, custom: custom, copy: flow, repeat: flow, settings: settings, profile: profile, weight: weight, preference: preference, account: account, auth: auth, loading: state, offline: state, error: state, disabled: state };
  app.innerHTML = view[current.type](current);
  document.body.classList.toggle("is-gallery", galleryMode);
  galleryButton.setAttribute("aria-pressed", String(galleryMode));
  picker.disabled = galleryMode;
  galleryRoot.innerHTML = galleryMode ? "<div class=\"gallery\">" + screens.map(function (screen) { return "<article class=\"gallery-card\"><header><p>" + screen.group + "</p><h2>" + screen.label + "</h2><small>" + galleryIntent(screen) + "</small></header>" + galleryPhone(screen) + "</article>"; }).join("") + "</div>" : "";
  document.querySelectorAll(".tab-item").forEach(function (tab) { tab.classList.toggle("is-selected", tab.dataset.tab === current.tab); });
  document.querySelectorAll("[data-set]").forEach(function (row) {
    row.addEventListener("click", function () {
      const completed = row.classList.toggle("is-completed");
      row.setAttribute("aria-pressed", String(completed));
      row.dataset.editor = completed ? "today-set-editor-actual" : "today-set-editor";
      row.setAttribute("aria-label", row.dataset.setName + ", set " + row.dataset.setNumber + ": " + row.dataset.setValue + ", " + (completed ? "completed. Tap to mark incomplete; press and hold or use Shift+F10 to edit actual results." : "incomplete. Tap to complete; press and hold or use Shift+F10 to edit planned values."));
    });
  });
  document.querySelectorAll("#app [data-route]").forEach(function (button) {
    button.addEventListener("click", function (event) {
      event.stopPropagation();
      selectScreen(button.dataset.route);
    });
  });
}

function selectScreen(id) {
  galleryMode = false;
  current = screens.find(function (screen) { return screen.id === id; }) || screens[0];
  render();
}

const groups = {};
screens.forEach(function (screen) { (groups[screen.group] ||= []).push(screen); });
Object.keys(groups).forEach(function (group) {
  const optgroup = document.createElement("optgroup");
  optgroup.label = group;
  groups[group].forEach(function (screen) { optgroup.append(new Option(screen.label, screen.id)); });
  picker.append(optgroup);
});
["today-incomplete", "program-week", "settings-main", "auth-sign-in", "state-offline"].forEach(function (id) {
  const screen = screens.find(function (item) { return item.id === id; });
  shortcuts.insertAdjacentHTML("beforeend", "<button type=\"button\" data-route=\"" + id + "\">" + screen.label + "</button>");
});

document.addEventListener("click", function (event) {
  const routed = event.target.closest("[data-route]");
  const tab = event.target.closest("[data-tab]");
  if (routed) selectScreen(routed.dataset.route);
  if (tab) selectScreen(tab.dataset.tab === "today" ? "today-partial" : tab.dataset.tab === "program" ? "program-week" : "settings-main");
});
document.addEventListener("pointerdown", function (event) {
  const row = event.target.closest("[data-editor]");
  if (!row || galleryMode) return;
  longPressTimer = window.setTimeout(function () { selectScreen(row.dataset.editor); }, 500);
});
document.addEventListener("pointerup", function () { window.clearTimeout(longPressTimer); });
document.addEventListener("pointercancel", function () { window.clearTimeout(longPressTimer); });
document.addEventListener("contextmenu", function (event) {
  const row = event.target.closest("[data-editor]");
  if (row && !galleryMode) { event.preventDefault(); selectScreen(row.dataset.editor); }
});
document.addEventListener("keydown", function (event) {
  const row = event.target.closest("[data-editor]");
  if (row && !galleryMode && event.shiftKey && event.key === "F10") { event.preventDefault(); selectScreen(row.dataset.editor); }
});
document.addEventListener("input", function (event) {
  if (!event.target.matches("[data-picker-search]")) return;
  pickerQuery = event.target.value;
  render();
  const input = document.querySelector("[data-picker-search]");
  if (input) { input.focus(); input.setSelectionRange(pickerQuery.length, pickerQuery.length); }
});
picker.addEventListener("change", function () { selectScreen(picker.value); });
galleryButton.addEventListener("click", function () { galleryMode = !galleryMode; if (galleryMode) pickerQuery = ""; render(); });
document.querySelectorAll("[data-theme-choice]").forEach(function (button) {
  button.addEventListener("click", function () {
    document.documentElement.dataset.theme = button.dataset.themeChoice;
    document.querySelectorAll("[data-theme-choice]").forEach(function (choice) { choice.setAttribute("aria-pressed", String(choice === button)); });
  });
});

render();
