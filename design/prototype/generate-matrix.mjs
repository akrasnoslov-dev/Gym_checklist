import { readFileSync, writeFileSync } from "node:fs";
import { loadRegistry, renderMatrix } from "./registry-tools.mjs";

const output = new URL("./screen-state-matrix.md", import.meta.url);
const { registry, meta } = loadRegistry();
const expected = renderMatrix(registry, meta);
const normalized = (value) => value.replaceAll("\r\n", "\n");

if (process.argv.includes("--write")) {
  writeFileSync(output, expected, "utf8");
  console.log(`Wrote screen-state-matrix.md from ${registry.length} frozen entries.`);
} else {
  const actual = readFileSync(output, "utf8");
  if (normalized(actual) !== normalized(expected)) {
    console.error("screen-state-matrix.md is stale. Run: node design/prototype/generate-matrix.mjs --write");
    process.exit(1);
  }
  console.log(`Screen/state matrix is current for ${registry.length} frozen entries.`);
}
