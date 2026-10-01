import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { loadRegistry } from "./registry-tools.mjs";

const routeFlag = process.argv.indexOf("--routes");
const requested = routeFlag >= 0 ? process.argv[routeFlag + 1]?.split(",").map((id) => id.trim()).filter(Boolean) : [];
if (!requested.length) {
  console.error("Refusing a mass snapshot update. Pass explicitly approved IDs, for example:");
  console.error("npm run visual:update -- --routes today-partial,program-week");
  process.exit(2);
}

const { registry } = loadRegistry();
const known = new Set(registry.map((entry) => entry.id));
const MAX_TARGETED_ROUTES = 8;
const unknown = requested.filter((id) => !known.has(id));
if (unknown.length) {
  console.error(`Unknown frozen review IDs: ${unknown.join(", ")}`);
  process.exit(2);
}
if (requested.length > MAX_TARGETED_ROUTES) {
  console.error(`Refusing a broad snapshot update of ${requested.length} routes. The targeted limit is ${MAX_TARGETED_ROUTES}; treat this as a regression and explain the scope before proceeding.`);
  process.exit(2);
}

const escaped = requested.map((id) => id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
const require = createRequire(import.meta.url);
const result = spawnSync(process.execPath, [require.resolve("playwright/cli"), "test", "--update-snapshots=changed", "--grep", `(${escaped.join("|")})$`], { stdio: "inherit" });
process.exit(result.status ?? 1);
