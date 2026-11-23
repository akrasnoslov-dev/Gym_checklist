import { defineConfig } from "playwright/test";

export default defineConfig({
  testDir: "./tests",
  outputDir: "./test-results",
  snapshotPathTemplate: `{testDir}/snapshots/${process.platform}/{arg}{ext}`,
  timeout: 30_000,
  expect: { timeout: 5_000, toHaveScreenshot: { animations: "disabled", caret: "hide", scale: "css", threshold: 0.1, maxDiffPixelRatio: 0.005 } },
  fullyParallel: true,
  forbidOnly: true,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: process.env.CI ? [["line"], ["html", { outputFolder: "playwright-report", open: "never" }]] : "line",
  use: {
    baseURL: "http://127.0.0.1:4173",
    browserName: "chromium",
    viewport: { width: 1280, height: 1000 },
    deviceScaleFactor: 1,
    locale: "en-US",
    timezoneId: "Europe/Copenhagen",
    colorScheme: "light",
    reducedMotion: "reduce",
    serviceWorkers: "block",
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "node server.mjs",
    url: "http://127.0.0.1:4173",
    reuseExistingServer: !process.env.CI,
    timeout: 20_000,
  },
});
