import { existsSync, readFileSync, readdirSync } from "node:fs";
import { loadRegistry, renderMatrix } from "./registry-tools.mjs";

const root = new URL("./", import.meta.url);
const requiredFiles = ["registry.js", "screen-state-matrix.md", "playwright.config.mjs", "tests/visual-regression.spec.mjs", "package.json"];
const missingFiles = requiredFiles.filter((path) => !existsSync(new URL(path, root)));
if (missingFiles.length) {
  console.error(`Missing stabilization files: ${missingFiles.join(", ")}`);
  process.exit(1);
}

const { registry, meta } = loadRegistry();
const errors = [];
const PHASE_5B_FROZEN_COUNT = 64;
const allowed = new Set(["surface", "state", "overlay", "qa"]);
const ids = new Set();
const snapshots = new Set();

for (const entry of registry) {
  if (ids.has(entry.id)) errors.push(`Duplicate review id: ${entry.id}`);
  ids.add(entry.id);
  if (!allowed.has(entry.classification)) errors.push(`Unclassified review entry: ${entry.id}`);
  if (!entry.parent || !entry.trigger) errors.push(`Missing parent/trigger metadata: ${entry.id}`);
  if (entry.userVisible !== (entry.classification !== "qa")) errors.push(`Incorrect userVisible flag: ${entry.id}`);
  if (entry.reviewOnly !== (entry.classification === "qa")) errors.push(`Incorrect reviewOnly flag: ${entry.id}`);
  if (entry.themeCoverage.join(",") !== "light,dark") errors.push(`Incomplete Light/Dark coverage: ${entry.id}`);
  if (!entry.snapshotId || snapshots.has(entry.snapshotId)) errors.push(`Missing or duplicate snapshot id: ${entry.id}`);
  snapshots.add(entry.snapshotId);
  if (!["interaction", "behavior", "data", "preference", "review-variant"].includes(entry.activation)) errors.push(`Missing or invalid activation contract: ${entry.id}`);
  if (!entry.components.length) errors.push(`Missing shared-component dependency metadata: ${entry.id}`);
}

if (meta.frozenCount !== PHASE_5B_FROZEN_COUNT) errors.push(`Phase 5B frozen count must remain ${PHASE_5B_FROZEN_COUNT}; changing it requires explicit user scope approval and contract review`);
if (registry.length !== PHASE_5B_FROZEN_COUNT) errors.push(`Frozen registry must contain exactly ${PHASE_5B_FROZEN_COUNT} entries, registry has ${registry.length}`);
if (registry.length > meta.baselineCount) errors.push(`Registry grew above ${meta.baselineCount} without explicit baseline update`);
for (const item of meta.consolidated) {
  if (ids.has(item.id)) errors.push(`Consolidated duplicate still registered: ${item.id}`);
  if (!ids.has(item.into)) errors.push(`Consolidation target is missing: ${item.into}`);
}

const index = readFileSync(new URL("./index.html", root), "utf8");
const app = readFileSync(new URL("./app.js", root), "utf8");
if (index.indexOf('src="registry.js"') < 0 || index.indexOf('src="registry.js"') > index.indexOf('src="app.js"')) errors.push("index.html must load the canonical registry before app.js");
if (!app.includes("const S=PROTOTYPE_REGISTRY")) errors.push("Normal mode and Gallery must render from PROTOTYPE_REGISTRY");

const expectedMatrix = renderMatrix(registry, meta);
const actualMatrix = readFileSync(new URL("./screen-state-matrix.md", root), "utf8");
if (actualMatrix !== expectedMatrix) errors.push("screen-state-matrix.md is stale");

const pkg = JSON.parse(readFileSync(new URL("./package.json", root), "utf8"));
if (!pkg.scripts?.["visual:verify"] || !pkg.scripts?.["visual:update"]) errors.push("Separate visual:verify and visual:update commands are required");
if (pkg.scripts?.["visual:verify"]?.includes("update-snapshots")) errors.push("visual:verify must never update snapshots");
if (!pkg.scripts?.["visual:update"]?.includes("update-snapshots")) errors.push("visual:update must be the explicit snapshot update operation");
const updater = readFileSync(new URL("./update-snapshots.mjs", root), "utf8");
if (!updater.includes("MAX_TARGETED_ROUTES = 8")) errors.push("Snapshot updates must enforce a small targeted-route ceiling");

for (const platform of ["linux", "win32"]) {
  for (const theme of ["light", "dark"]) {
    const directory = new URL(`./tests/snapshots/${platform}/${theme}/`, root);
    const files = existsSync(directory) ? readdirSync(directory).filter((file) => file.endsWith(".png")) : [];
    if (files.length !== PHASE_5B_FROZEN_COUNT) errors.push(`${platform}/${theme} must contain ${PHASE_5B_FROZEN_COUNT} frozen baselines, found ${files.length}`);
  }
}

const workflow = readFileSync(new URL("../../.github/workflows/prototype-visual-regression.yml", root), "utf8");
if (!workflow.includes("runs-on: ubuntu-latest")) errors.push("Prototype visual CI must be Linux-only");
if (!workflow.includes("'design/prototype/**'")) errors.push("Prototype visual CI must be path-gated");
if (workflow.includes("visual:update") || workflow.includes("update-snapshots")) errors.push("CI must never update visual snapshots");
if (!workflow.includes("if: failure()") || !workflow.includes("test-results/") || !workflow.includes("tests/snapshots/")) errors.push("CI must upload expected/actual/diff evidence on failure");

if (errors.length) {
  console.error("Phase 5B stabilization contract failed.");
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

const counts = Object.fromEntries([...allowed].map((kind) => [kind, registry.filter((entry) => entry.classification === kind).length]));
console.log(`Phase 5B stabilization contract passed: ${registry.length} entries (A ${counts.surface}, B ${counts.state}, C ${counts.overlay}, D ${counts.qa}).`);
