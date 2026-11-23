// @ts-check
import { defineConfig, devices } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

/**
 * Read environment variables from the local, git-ignored .env file (see .env.example).
 * Uses Node's built-in loader, so no extra dependency is needed.
 */
const envFile = path.resolve(__dirname, '.env');
if (fs.existsSync(envFile)) process.loadEnvFile(envFile);

/**
 * Products:
 * - Portal (myShop web, XAF Blazor): automated here, tests in tests/portal, docs in docs/portal.
 * - MacOne app (Windows POS): not drivable by Playwright, docs only in docs/macone-app.
 */
const PORTAL_AUTH_FILE = 'playwright/.auth/portal-user.json';
const portalUse = {
  ...devices['Desktop Chrome'],
  baseURL: process.env.QA_BASE_URL,
  viewport: { width: 1600, height: 1000 },
  actionTimeout: 20_000,
  navigationTimeout: 60_000,
  trace: /** @type {const} */ ('retain-on-failure'),
  screenshot: /** @type {const} */ ('only-on-failure'),
};

/** @see https://playwright.dev/docs/test-configuration */
export default defineConfig({
  testDir: './tests',
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'reports/results.json' }],
  ],

  projects: [
    {
      name: 'portal-setup',
      testDir: './tests/portal',
      testMatch: /portal\.setup\.js/,
      timeout: 180_000,
      use: portalUse,
    },
    {
      name: 'portal',
      testDir: './tests/portal',
      testMatch: /.*\.spec\.js/,
      dependencies: ['portal-setup'],
      /* Tests inside one file run in order; files run in parallel. Grid layouts are shared per user. */
      fullyParallel: false,
      timeout: 300_000,
      expect: { timeout: 15_000 },
      use: { ...portalUse, storageState: PORTAL_AUTH_FILE },
    },
  ],
});
