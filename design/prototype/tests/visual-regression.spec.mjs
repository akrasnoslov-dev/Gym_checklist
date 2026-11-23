import { expect, test } from "playwright/test";
import { loadRegistry } from "../registry-tools.mjs";

const { registry } = loadRegistry();
const themes = ["light", "dark"];

async function openEntry(page, entry, theme) {
  const externalRequests = [];
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.hostname !== "127.0.0.1") externalRequests.push(request.url());
  });
  await page.goto("/");
  await page.addStyleTag({ content: "*,*::before,*::after{animation:none!important;transition:none!important;scroll-behavior:auto!important}" });
  await page.locator(`[data-theme-choice="${theme}"]`).click();
  await page.locator("#screen-picker").selectOption(entry.id);
  await page.locator(".app-content").evaluate((element) => { element.scrollTop = 0; element.scrollLeft = 0; });
  await page.evaluate(() => scrollTo(0, 0));
  await expect(page.locator("#screen-picker")).toHaveValue(entry.id);
  expect(externalRequests, `${entry.id} must have no network dependency`).toEqual([]);
}

async function expectStructuralBounds(page, entry) {
  const shell = page.locator(".prototype-stage > .phone-shell");
  const box = await shell.boundingBox();
  expect(box, `${entry.id} phone shell`).not.toBeNull();
  expect(Math.round(box.width)).toBe(390);
  expect(Math.round(box.height)).toBe(844);

  const layout = await page.locator(".app-content").evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth,
    paddingBottom: Number.parseFloat(getComputedStyle(element).paddingBottom),
  }));
  expect(layout.scrollWidth, `${entry.id} horizontal content overflow`).toBeLessThanOrEqual(layout.clientWidth + 1);

  const tab = page.locator(".prototype-stage > .phone-shell > .system-tab-bar");
  if (await tab.count()) {
    const tabBox = await tab.boundingBox();
    expect(layout.paddingBottom, `${entry.id} tab-bar clearance`).toBeGreaterThanOrEqual(tabBox.height);
  }

  const escapedMetadata = await page.locator(".prototype-stage > .phone-shell").getByText(/^Trigger:/).count();
  expect(escapedMetadata, `${entry.id} reviewer metadata leaked into app UI`).toBe(0);

  const boundedSelectors = ".sheet,.context-menu,.alert-card,.completion-overlay,.native-calendar";
  for (const overlay of await page.locator(boundedSelectors).all()) {
    const overlayBox = await overlay.boundingBox();
    if (!overlayBox) continue;
    expect(overlayBox.x).toBeGreaterThanOrEqual(box.x - 1);
    expect(overlayBox.y).toBeGreaterThanOrEqual(box.y - 1);
    expect(overlayBox.x + overlayBox.width).toBeLessThanOrEqual(box.x + box.width + 1);
    expect(overlayBox.y + overlayBox.height).toBeLessThanOrEqual(box.y + box.height + 1);
  }

  expect(await page.locator(".prototype-stage > .phone-shell button:visible").count(), `${entry.id} retains at least one usable control`).toBeGreaterThan(0);
}

for (const entry of registry) {
  for (const theme of themes) {
    test(`${theme} · ${entry.id}`, async ({ page }) => {
      await openEntry(page, entry, theme);
      await expectStructuralBounds(page, entry);
      await expect(page.locator(".prototype-stage > .phone-shell")).toHaveScreenshot([theme, `${entry.snapshotId}.png`]);
    });
  }
}

test("Gallery and normal mode use the same frozen registry", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("#screen-picker option")).toHaveCount(registry.length);
  await page.locator("#gallery-mode").click();
  await expect(page.locator(".gallery-card")).toHaveCount(registry.length);
  expect(await page.locator(".gallery-card").evaluateAll((cards) => cards.map((card) => card.dataset.reviewId))).toEqual(registry.map((entry) => entry.id));
  await expect(page.locator(".gallery-phone").getByText(/^Trigger:/)).toHaveCount(0);
});

test("shared-component dependencies include every frozen screenshot consumer", async () => {
  const consumers = new Map();
  for (const entry of registry) {
    for (const component of entry.components) {
      const ids = consumers.get(component) || new Set();
      ids.add(entry.id);
      consumers.set(component, ids);
    }
  }
  expect(consumers.size).toBeGreaterThan(0);
  const covered = new Set([...consumers.values()].flatMap((ids) => [...ids]));
  expect([...covered].sort()).toEqual(registry.map((entry) => entry.id).sort());
  for (const [component, ids] of consumers) expect(ids.size, `${component} consumer coverage`).toBeGreaterThan(0);
});

test("every interaction-backed entry is reachable through the rendered route graph", async ({ page }) => {
  await page.goto("/");
  const edges = new Map();
  const remember = (target, edge) => { if (target && !edges.has(target)) edges.set(target, edge); };

  for (const source of registry) {
    await page.locator("#screen-picker").selectOption(source.id);
    for (const route of await page.locator("[data-route]").evaluateAll((elements) => elements.map((element) => element.dataset.route))) remember(route, { source: source.id, kind: "route", target: route });
    for (const editor of await page.locator("[data-editor]").evaluateAll((elements) => elements.map((element) => element.dataset.editor))) remember(editor, { source: source.id, kind: "editor", target: editor });
  }
  remember("today-partial", { source: "program-week", kind: "tab", target: "today" });
  remember("program-week", { source: "today-partial", kind: "tab", target: "program" });
  remember("settings-main", { source: "today-partial", kind: "tab", target: "settings" });

  const expected = registry.filter((entry) => entry.activation === "interaction");
  const missing = expected.filter((entry) => !edges.has(entry.id)).map((entry) => entry.id);
  expect(missing, "interaction entries without a rendered trigger").toEqual([]);

  for (const entry of expected) {
    const edge = edges.get(entry.id);
    await page.locator("#screen-picker").selectOption(edge.source);
    if (edge.kind === "route") await page.locator(`[data-route="${entry.id}"]`).first().click();
    if (edge.kind === "editor") await page.locator(`[data-editor="${entry.id}"]`).first().dispatchEvent("contextmenu");
    if (edge.kind === "tab") await page.locator(`[data-tab="${edge.target}"]`).click();
    await expect(page.locator("#screen-picker"), `${entry.id} from ${edge.source}`).toHaveValue(entry.id);
  }
});

test("normal interaction paths remain reachable", async ({ page }) => {
  await page.goto("/");
  await page.locator("#screen-picker").selectOption("today-incomplete");
  for (const set of await page.locator("[data-set]").all()) await set.click();
  await expect(page.locator(".completion-overlay")).toBeVisible();
  await page.locator("#screen-picker").selectOption("today-partial");
  const set = page.locator("[data-set]").first();
  const before = await set.getAttribute("aria-pressed");
  await set.click();
  await expect(set).toHaveAttribute("aria-pressed", before === "true" ? "false" : "true");
  await page.locator("[data-tab=program]").click();
  await expect(page.locator("#screen-picker")).toHaveValue("program-week");
  await page.locator("[data-route=program-workout-menu]").click();
  await expect(page.locator("#screen-picker")).toHaveValue("program-workout-menu");
  await page.locator(".context-menu [data-route=program-edit]").click();
  await page.locator("[data-tab=settings]").click();
  await page.locator("[data-route=settings-profile]").click();
  await expect(page.locator("#screen-picker")).toHaveValue("settings-profile");
});


test("final Phase 5B interaction semantics are stable", async ({ page }) => {
  await page.goto("/");
  await page.locator("#screen-picker").selectOption("today-exercise-menu");
  await expect(page.locator(".context-menu")).toBeVisible();
  const lockedOverflow = await page.locator(".app-content").evaluate((element) => getComputedStyle(element).overflowY);
  expect(lockedOverflow).toBe("hidden");
  const menuScroll = await page.locator(".context-menu").evaluate((element) => ({ client: element.clientHeight, scroll: element.scrollHeight }));
  expect(menuScroll.scroll).toBeLessThanOrEqual(menuScroll.client);

  await page.locator("#screen-picker").selectOption("program-week");
  const weekStates = await page.locator(".day-cell i").allTextContents();
  expect(weekStates).toEqual(expect.arrayContaining(["\u25CB", "\u2022", "\u25D0", "\u2713", "!"]));

  await page.locator("#screen-picker").selectOption("program-edit");
  await expect(page.locator(".editor-row em")).toHaveCount(0);

  await page.locator("#screen-picker").selectOption("program-reorder");
  await expect(page.getByRole("heading", { name: "Reorder exercises" })).toBeVisible();
  await expect(page.locator(".drag-handle")).toHaveCount(2);
  await expect(page.getByText("REORDER MODE", { exact: true })).toHaveCount(0);
  await expect(page.locator(".segmented")).toHaveCount(0);
  await expect(page.locator(".system-tab-bar")).toHaveCount(0);

  await page.locator("#screen-picker").selectOption("program-set-menu");
  await page.getByRole("button", { name: "Reorder sets" }).click();
  await expect(page.getByRole("heading", { name: "Reorder sets" })).toBeVisible();
  await expect(page.locator(".drag-handle")).toHaveCount(3);

  await page.locator("#screen-picker").selectOption("today-completed");
  await page.locator("[data-set]").first().click();
  await page.locator("[data-set]").first().click();
  await expect(page.locator(".completion-overlay")).toBeVisible();
  await expect(page.locator(".app-content")).toHaveAttribute("data-lock-scroll", "");

  await page.locator("#screen-picker").selectOption("auth-sign-in");
  const authAlignment = await page.locator(".auth-screen .form-card label").first().evaluate((label) => ({
    label: getComputedStyle(label).textAlign,
    input: getComputedStyle(label.querySelector("input")).textAlign,
  }));
  expect(authAlignment).toEqual({ label: "left", input: "left" });
});
