import { readFileSync } from "node:fs";
import { loadRegistry } from "./registry-tools.mjs";

const app = readFileSync(new URL("./app.js", import.meta.url), "utf8");
const registrySource = readFileSync(new URL("./registry.js", import.meta.url), "utf8");
const { registry } = loadRegistry();
const source = `${registrySource}\n${app}`;

const requiredMarkers = ["data-theme-choice", "aria-label", "native-intent", "gallery-mode", "data-route", "Native DatePicker intent", "Skipped exercises · 2", "completionCards", "Trigger:", "Weight ('+unit+')"];
const missingMarkers = requiredMarkers.filter((marker) => !source.includes(marker));
const requiredReachability = [
  "addEventListener('contextmenu'", "[data-set]", "Skip exercise", "Restore Barbell Row", "Restore Cable Face Pull",
  "program-workout-menu", "Delete workout", "program-history", "copy-workout-calendar", "repeat-workout-calendar",
  "Weight ('+unit+')", "Time (sec)", "45 sec", "toggleSet", "restoreExercise",
  "Reorder exercises", "Reorder sets", "drag-handle", "keeps the recorded actual intact",
  "program-week-prev", "program-month-prev", "data-editor", "completionCards", "pointerdown", "keydown",
  "data-appearance", "data-unit", "unitPref", "assets/completion-crushed.svg", "assets/completion-barely.svg",
  "assets/completion-another.svg", "aria-pressed", "summary-icon", "Calendar ›", "data-lock-scroll",
];
const missingReachability = requiredReachability.filter((marker) => !source.includes(marker));
const forbiddenMarkers = ["REORDER MODE"];
const presentForbidden = forbiddenMarkers.filter((marker) => source.includes(marker));

if (missingMarkers.length || missingReachability.length || presentForbidden.length) {
  console.error("Prototype contract failed.");
  if (missingMarkers.length) console.error(`Missing accessibility/native-intent markers: ${missingMarkers.join(", ")}`);
  if (missingReachability.length) console.error(`Missing reachable interaction markers: ${missingReachability.join(", ")}`);
  if (presentForbidden.length) console.error(`Forbidden legacy markers still present: ${presentForbidden.join(", ")}`);
  process.exit(1);
}

console.log(`Prototype contract passed: ${registry.length} canonical review entries and semantic markers found.`);
