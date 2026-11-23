// @ts-check
// Portal: log in once and save the session, reused by every portal test (project "portal").
import { test as setup, expect } from '@playwright/test';
import { PORTAL_AUTH_FILE } from './support/portal.js';

setup('log in to the QA portal', async ({ page }) => {
  await page.goto('LoginPage');
  const password = page.locator('input[type=password]');
  const app = page.locator('.dxbl-grid, .dxbl-fl, .xaf-sidebar, nav').first();
  await expect(password.or(app).first()).toBeVisible({ timeout: 90_000 });

  // The login page re-renders once the Blazor circuit connects and can wipe typed values, so retry until the app shows.
  for (let attempt = 1; attempt <= 3 && (await password.isVisible()); attempt++) {
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(2_000);
    if (!(await password.isVisible())) break;
    const user = page.locator('input[type=text]:not([readonly])').first();
    await user.fill(/** @type {string} */ (process.env.QA_USERNAME));
    await password.fill(/** @type {string} */ (process.env.QA_PASSWORD));
    await expect(user).toHaveValue(/** @type {string} */ (process.env.QA_USERNAME));
    await page.getByRole('button', { name: 'Log In', exact: true }).click();
    await password.waitFor({ state: 'hidden', timeout: 45_000 }).catch(() => {});
  }

  await expect(password).toBeHidden({ timeout: 60_000 });
  await page.context().storageState({ path: PORTAL_AUTH_FILE });
});
