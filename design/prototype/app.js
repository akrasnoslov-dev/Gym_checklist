const screens = [
  { id: "today-incomplete", group: "Today", label: "Incomplete", tab: "today", type: "today", done: 0 },
  { id: "today-partial", group: "Today", label: "Partial", tab: "today", type: "today", done: 3 },
  { id: "today-completed", group: "Today", label: "Completed", tab: "today", type: "today", done: 7 },
  { id: "today-skipped", group: "Today", label: "Skipped / restore", tab: "today", type: "today", done: 3, skipped: true },
  { id: "today-rest-day", group: "Today", label: "Rest day", tab: "today", type: "empty", state: "rest" },
  { id: "today-no-program", group: "Today", label: "No program", tab: "today", type: "empty", state: "no-program" },
  { id: "today-set-editor", group: "Today", label: "Long-press planned set editor", tab: "today", type: "today", done: 0, overlay: "editor-planned" },
  { id: "today-set-editor-actual", group: "Today", label: "Long-press actual set editor", tab: "today", type: "today", done: 3, overlay: "editor-actual" },
  { id: "today-completion", group: "Today", label: "Workout completion overlay", tab: "today", type: "today", done: 7, overlay: "completion" },
  { id: "program-week", group: "Program", label: "Week", tab: "program", type: "week" },
  { id: "program-month", group: "Program", label: "Month", tab: "program", type: "month" },
  { id: "program-edit", group: "Program", label: "Selected-date editing", tab: "program", type: "edit" },
  { id: "program-history", group: "Program", label: "Historical workout editing", tab: "program", type: "history" },
  { id: "exercise-picker", group: "Workout flows", label: "Exercise picker", tab: "program", type: "picker" },
  { id: "custom-exercise", group: "Workout flows", label: "Custom exercise", tab: "program", type: "custom" },
  { id: "copy-workout", group: "Workout flows", label: "Copy workout", tab: "program", type: "copy" },
  { id: "repeat-workout", group: "Workout flows", label: "Repeat workout", tab: "program", type: "repeat" },
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
let current = screens[1];

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
      return "<button class=\"set-row " + (completed ? "is-completed" : "") + "\" data-set aria-pressed=\"" + completed + "\" aria-label=\"" + exercise[0] + ", set " + (index + 1) + ": " + value + ", " + (completed ? "completed. Tap to undo." : "incomplete. Tap to complete.") + "\"><span class=\"completion-icon\" aria-hidden=\"true\"></span><span>" + value + "</span></button>";
    }).join("");
    return "<section class=\"exercise-group\"><header class=\"exercise-header\"><h3>" + exercise[0] + "</h3><button class=\"icon-button native-intent\" data-route=\"today-skipped\" aria-label=\"System intent: " + exercise[0] + " actions\">•••</button></header><div class=\"set-list\">" + rows + "</div></section>";
  }).join("");
}

function today(screen) {
  let extra = screen.skipped ? "<button class=\"restore-row native-intent\" data-route=\"today-incomplete\">Skipped exercises <span>Restore Barbell Row ›</span></button>" : "";
  if (screen.overlay === "editor-planned" || screen.overlay === "editor-actual") extra += editorOverlay(screen.overlay === "editor-actual");
  if (screen.overlay === "completion") extra += completionOverlay();
  return heading("Today", "Tuesday, September 8") + "<div class=\"workout-list\">" + todayRows(screen.done, screen.skipped ? "Barbell Row" : "") + extra + "</div>";
}

function empty(screen) {
  const rest = screen.state === "rest";
  return heading("Today", "Tuesday, September 8") + "<section class=\"empty-state app-owned\"><span class=\"empty-symbol\" aria-hidden=\"true\">" + (rest ? "☀" : "✓") + "</span><h3>" + (rest ? "Rest day." : "No workout planned yet.") + "</h3><p>" + (rest ? "See you tomorrow." : "Create a workout when you are ready.") + "</p>" + route(rest ? "View program" : "Create workout", "program-week", "primary") + "</section>";
}

function editorOverlay(actual) {
  const titleText = actual ? "Edit actual" : "Edit set";
  const note = actual ? "Actual results · completion stays checked" : "Planned set · before completion";
  return "<div class=\"sheet-scrim\"><section class=\"sheet native-intent\" aria-label=\"System intent: compact " + (actual ? "actual" : "planned") + " set editor\"><div class=\"sheet-grabber\"></div><header><button data-route=\"today-partial\">Cancel</button><h3>" + titleText + "</h3><button class=\"accent-action\" data-route=\"today-partial\">Save</button></header><p>" + note + "</p><div class=\"form-card\"><label>Reps<input value=\"8\"></label><label>Weight<input value=\"60 kg\"></label></div></section></div>";
}

function completionOverlay() {
  return "<div class=\"sheet-scrim\"><section class=\"completion-overlay app-owned\"><span class=\"completion-burst\" aria-hidden=\"true\">✓</span><h3>Gym survived. Barely.</h3><p>Another one done.</p>" + route("Done", "today-completed", "primary") + "</section></div>";
}

function dayStrip() {
  const dates = [["M", "7", "empty", "○"], ["T", "8", "partial workout", "◐"], ["W", "9", "planned workout", "•"], ["T", "10", "completed workout", "✓"], ["F", "11", "incomplete workout", "!"], ["S", "12", "skipped workout", "–"], ["S", "13", "empty", "○"]];
  return "<div class=\"day-strip\">" + dates.map(function (item, index) {
    return "<button class=\"day-cell " + (index === 1 ? "is-selected" : "") + "\" aria-label=\"September " + item[1] + ", " + item[2] + (index === 1 ? ", selected" : "") + "\"><span>" + item[0] + "</span><strong>" + item[1] + "</strong><i aria-hidden=\"true\">" + item[3] + "</i></button>";
  }).join("") + "</div>";
}

function detail(historical, editable) {
  const actual = historical ? "7 reps × 65 kg · actual" : "8 reps × 60 kg";
  return "<section class=\"program-detail\"><p class=\"selected-date-label\">" + (historical ? "Friday, September 4 · History" : "Tuesday, September 8") + "</p><section class=\"program-exercise\"><header><h3>Bench Press</h3><button class=\"icon-button native-intent\" aria-label=\"System intent: exercise actions\">•••</button></header><div class=\"editor-list\"><button class=\"editor-row\" data-route=\"program-edit\"><span>1</span><strong>8 reps × 60 kg</strong><em>Edit</em></button><button class=\"editor-row is-completed\" data-route=\"" + (historical ? "program-history" : "program-edit") + "\"><span>2</span><strong>" + actual + "</strong><em>" + (historical ? "Edit actual" : "Edit") + "</em></button><button class=\"editor-row\" data-route=\"program-edit\"><span>3</span><strong>6 reps × 60 kg</strong><em>Edit</em></button></div>" + (editable ? "<div class=\"inline-actions\">" + route("+ Add set", "program-edit") + route("+ Add exercise", "exercise-picker") + "</div>" : "") + "</section>" + (editable ? "<button class=\"destructive-row native-intent\">Remove workout <em>System confirmation required</em></button>" : "") + "</section>";
}

function week() {
  return heading("Program", "", "<button class=\"add-button\" data-route=\"program-edit\">+</button>") + "<div class=\"segmented native-intent\"><button class=\"is-selected\">Week</button><button data-route=\"program-month\">Month</button></div><div class=\"calendar-nav native-intent\"><button>‹</button><strong>Sep 7 – Sep 13</strong><button>›</button></div>" + dayStrip() + detail(false, false);
}

function month() {
  const dayNames = ["M", "T", "W", "T", "F", "S", "S"].map(function (day) { return "<span>" + day + "</span>"; }).join("");
  const states = { 1: ["planned workout", "•"], 8: ["partial workout", "◐"], 11: ["completed workout", "✓"], 18: ["incomplete workout", "!"], 22: ["skipped workout", "–"] };
  const cells = Array.from({ length: 35 }, function (_, i) {
    const day = i;
    const status = states[day] || ["empty", "○"];
    return "<button class=\"" + (day === 8 ? "is-selected " : "") + (day === 0 || day > 30 ? "is-muted" : "") + "\" aria-label=\"September " + (day || 31) + ", " + status[0] + (day === 8 ? ", selected" : "") + "\">" + (day || 31) + "<i aria-hidden=\"true\">" + status[1] + "</i></button>";
  }).join("");
  return heading("Program") + "<div class=\"segmented native-intent\"><button data-route=\"program-week\">Week</button><button class=\"is-selected\">Month</button></div><div class=\"calendar-nav native-intent\"><button>‹</button><strong>September 2026</strong><button>›</button></div><section class=\"month-grid\">" + dayNames + cells + "</section>" + detail(false, false);
}

function edit() {
  return heading("Edit workout", "Tuesday, September 8", "<button class=\"add-button\" data-route=\"exercise-picker\">+</button>") + "<p class=\"system-caption native-intent\">System intent: List editing, menus, sheets and confirmation dialog</p>" + detail(false, true) + "<section class=\"edit-actions native-intent\"><strong>Exercise menu · Bench Press</strong><button>↕ Move exercise</button><button class=\"is-destructive\">Delete exercise</button></section><section class=\"edit-actions native-intent\"><strong>Set menu · Set 2</strong><button>↕ Move set</button><button class=\"is-destructive\">Delete set</button></section><p class=\"system-caption native-intent\">Destructive choices open a native confirmation naming the exercise or set.</p><div class=\"editor-tools\"><button data-route=\"copy-workout\">Copy workout</button><button data-route=\"repeat-workout\">Repeat workout</button></div>";
}

function history() {
  return heading("Workout", "Friday, September 4") + "<p class=\"history-note\">Actual results remain editable. Planned changes do not overwrite them.</p>" + detail(true, false);
}

function pickerView() {
  const names = ["Bench Press", "Barbell Row", "Cable Face Pull", "Goblet Squat"];
  return heading("Add exercise") + "<div class=\"search native-intent\">⌕ <span>Search exercises</span></div><p class=\"list-label\">COMMON</p><section class=\"grouped-list\">" + names.map(function (name) { return "<button class=\"list-row\" data-route=\"program-edit\">" + name + "<span>+</span></button>"; }).join("") + "</section>" + route("Add custom exercise", "custom-exercise");
}

function custom() {
  return heading("New exercise") + "<p class=\"system-caption native-intent\">System intent: focused form sheet</p><section class=\"form-card\"><label>Exercise name<input placeholder=\"e.g. Romanian Deadlift\"></label><label>Category<select><option>Optional</option><option>Legs</option><option>Back</option></select></label></section><button class=\"button button-primary\" disabled>Save exercise</button>";
}

function flow(screen) {
  const copy = screen.type === "copy";
  const form = copy ? "<label>Destination date<input value=\"September 15, 2026\"></label><p>Completion state is not copied.</p>" : "<label>Repeat every<select><option>1 week</option><option>2 weeks</option><option>3 weeks</option><option>4 weeks</option></select></label><label>For<select><option>4 weeks</option><option>8 weeks</option><option>Until date</option></select></label><p>Generated workouts are independent.</p>";
  return heading(copy ? "Copy workout" : "Repeat workout") + "<section class=\"flow-summary\"><span>▦</span><div><strong>Tuesday, September 8</strong><p>3 exercises · 7 sets</p></div></section><section class=\"form-card native-intent\">" + form + "</section>" + route(copy ? "Copy workout" : "Create repeats", "program-week", "primary");
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
  return heading(screen.preference) + "<p class=\"system-caption native-intent\">System intent: native picker</p><section class=\"preference-options\">" + screen.choices.map(function (choice, index) { return "<button class=\"preference-row " + (index === 0 ? "is-selected" : "") + "\"><span>" + choice + "</span><b>" + (index === 0 ? "✓" : "") + "</b></button>"; }).join("") + "</section>";
}

function account() {
  return heading("Account") + "<section class=\"account-card\"><p>andrei@example.com</p>" + route("Log out", "auth-sign-in") + "</section>" + settingsSection("Danger zone", "<button class=\"destructive-row native-intent\" data-route=\"state-disabled\"><span>Delete account</span><em>System confirmation ›</em></button>") + "<p class=\"danger-note\">Deletion is separate from preferences and requires clear confirmation.</p>";
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

function render() {
  picker.value = current.id;
  const view = { today: today, empty: empty, week: week, month: month, edit: edit, history: history, picker: pickerView, custom: custom, copy: flow, repeat: flow, settings: settings, profile: profile, weight: weight, preference: preference, account: account, auth: auth, loading: state, offline: state, error: state, disabled: state };
  app.innerHTML = view[current.type](current);
  document.querySelectorAll(".tab-item").forEach(function (tab) { tab.classList.toggle("is-selected", tab.dataset.tab === current.tab); });
  document.querySelectorAll("[data-set]").forEach(function (row) {
    row.addEventListener("click", function () {
      const completed = row.classList.toggle("is-completed");
      row.setAttribute("aria-pressed", String(completed));
    });
  });
}

function selectScreen(id) {
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
picker.addEventListener("change", function () { selectScreen(picker.value); });
document.querySelectorAll("[data-theme-choice]").forEach(function (button) {
  button.addEventListener("click", function () {
    document.documentElement.dataset.theme = button.dataset.themeChoice;
    document.querySelectorAll("[data-theme-choice]").forEach(function (choice) { choice.setAttribute("aria-pressed", String(choice === button)); });
  });
});

render();
