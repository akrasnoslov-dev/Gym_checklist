import { readFileSync } from "node:fs";

const source = readFileSync(new URL("./app.js", import.meta.url), "utf8");
const requiredScreens = [
  "today-incomplete", "today-partial", "today-completed", "today-skipped", "today-rest-day", "today-no-program", "today-set-editor", "today-set-editor-actual", "today-completion",
  "program-week", "program-month", "program-edit", "program-history",
  "exercise-picker", "custom-exercise", "copy-workout", "repeat-workout",
  "settings-main", "settings-profile", "settings-body-weight", "settings-appearance", "settings-unit", "settings-account",
  "auth-sign-in", "auth-sign-up", "auth-reset",
  "state-loading", "state-offline", "state-error", "state-disabled"
];

const missing = requiredScreens.filter((id) => !source.includes(`id: "${id}"`));
const requiredMarkers = ["data-theme-choice", "aria-label", "native-intent"];
const missingMarkers = requiredMarkers.filter((marker) => !source.includes(marker));

if (missing.length || missingMarkers.length) {
  console.error("Prototype contract failed.");
  if (missing.length) console.error(`Missing required screen ids: ${missing.join(", ")}`);
  if (missingMarkers.length) console.error(`Missing accessibility/native-intent markers: ${missingMarkers.join(", ")}`);
  process.exit(1);
}

console.log(`Prototype contract passed: ${requiredScreens.length} required screens and semantic markers found.`);
