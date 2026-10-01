import { readFileSync } from "node:fs";

const source = readFileSync(new URL("./app.js", import.meta.url), "utf8");
const requiredScreens = [
  "today-incomplete", "today-partial", "today-completed", "today-exercise-menu", "today-skipped", "today-rest-day", "today-no-program", "today-set-editor", "today-set-editor-actual", "today-set-editor-lb", "today-set-editor-actual-lb", "today-set-editor-timed", "today-set-editor-timed-actual", "today-set-editor-reps", "today-set-editor-reps-actual", "today-completion", "today-completion-barely", "today-completion-another",
  "program-week", "program-week-prev", "program-week-next", "program-month", "program-month-prev", "program-month-next", "program-edit", "program-history-week-prev", "program-edit-week-next", "program-history-month-prev", "program-edit-month-next", "program-add-set", "program-add-timed-set", "program-set-editor", "program-completed-plan-editor", "program-reorder", "program-set-editor-lb", "program-set-editor-timed", "program-exercise-menu", "program-set-menu", "program-workout-menu", "program-delete-confirm", "program-delete-exercise", "program-delete-workout", "program-history", "program-history-set-editor", "program-history-set-editor-lb", "program-history-set-editor-timed",
  "exercise-picker", "custom-exercise", "copy-workout", "copy-workout-calendar", "repeat-workout", "repeat-workout-until", "repeat-workout-calendar",
  "settings-main", "settings-profile", "settings-body-weight", "settings-appearance", "settings-unit", "settings-account",
  "auth-sign-in", "auth-sign-up", "auth-reset",
  "state-loading", "state-offline", "state-error", "state-disabled"
];

const missing = requiredScreens.filter((id) => !source.includes(`"${id}"`) && !source.includes(`'${id}'`));
const requiredMarkers = ["data-theme-choice", "aria-label", "native-intent", "gallery-mode", "data-route", "Native DatePicker intent", "Skipped exercises · 2", "completionCards", "Trigger:", "Weight ('+unit+')"];
const missingMarkers = requiredMarkers.filter((marker) => !source.includes(marker));
const requiredReachability = [
  "addEventListener('contextmenu'", "[data-set]", "Skip exercise", "Restore Barbell Row", "Restore Cable Face Pull",
  "program-workout-menu", "Delete workout", "program-history", "copy-workout-calendar", "repeat-workout-calendar",
  "Weight ('+unit+')", "Time (sec)", "45 sec", "done:8", "toggleSet", "restoreExercise", "Move exercise", "Move set", "REORDER MODE", "keeps the recorded actual intact", "program-week-prev", "program-month-prev", "data-editor", "completionCards", "pointerdown", "keydown", "data-appearance", "data-unit", "unitPref", "assets/completion-crushed.svg", "assets/completion-barely.svg", "assets/completion-another.svg", "aria-pressed", "summary-icon", "Calendar ›"
];
const missingReachability = requiredReachability.filter((marker) => !source.includes(marker));

if (missing.length || missingMarkers.length || missingReachability.length) {
  console.error("Prototype contract failed.");
  if (missing.length) console.error(`Missing required screen ids: ${missing.join(", ")}`);
  if (missingMarkers.length) console.error(`Missing accessibility/native-intent markers: ${missingMarkers.join(", ")}`);
  if (missingReachability.length) console.error(`Missing reachable interaction markers: ${missingReachability.join(", ")}`);
  process.exit(1);
}

console.log(`Prototype contract passed: ${requiredScreens.length} required screens and semantic markers found.`);
