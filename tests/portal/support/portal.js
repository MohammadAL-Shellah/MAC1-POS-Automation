// @ts-check
// Shared helpers for the myShop portal (DevExpress XAF Blazor). Keep story-specific page objects
// in tests/portal/<story-slug>/support/ and only generic XAF helpers here.
import { expect } from '@playwright/test';

/** @typedef {import('@playwright/test').Page} Page */
/** @typedef {import('@playwright/test').Locator} Locator */

/** Saved login session, written by portal.setup.js. */
export const PORTAL_AUTH_FILE = 'playwright/.auth/portal-user.json';

/** One id per run, used to make test data unique: QA_AUTO_<RUN_ID>_<tag>. */
export const RUN_ID = (process.env.PORTAL_RUN_ID ??= Date.now().toString(36).toUpperCase());

/** @param {string} tag */
export const uniqueName = (tag) => `QA_AUTO_${RUN_ID}_${tag}`;

/** Popups (modal dialogs), excluding DevExpress dropdowns that also use role=dialog. */
export const POPUP = '[role=dialog]:not(dxbl-dropdown-dialog)';

/** @param {Page} page @param {number} ms */
export const pause = (page, ms) => page.waitForTimeout(ms);

/** Wait until an XAF view (list or detail) has rendered. @param {Page} page */
export async function waitForApp(page) {
  await expect(page.locator('.dxbl-grid, .dxbl-fl').first()).toBeVisible({ timeout: 60_000 });
  await pause(page, 1_000);
}

/** Open a view by its XAF id, e.g. "InvItem_ListView". @param {Page} page @param {string} viewId */
export async function openView(page, viewId) {
  await page.goto(viewId);
  await waitForApp(page);
}

/** Toolbar / grid button by its exact accessible name. @param {Page | Locator} scope @param {string} name */
export const button = (scope, name) => scope.getByRole('button', { name, exact: true }).first();

/** Type into the grid's "Text to search" box and run the search. @param {Page | Locator} scope @param {string} text */
export async function searchGrid(scope, text) {
  const box = scope.getByPlaceholder('Text to search').first();
  await box.fill(text);
  await box.press('Enter');
  await pause(/** @type {Page} */ ('page' in scope ? scope.page() : scope), 1_800);
}

/** Grid row that contains a cell with exactly this text. @param {Page | Locator} scope @param {string} text */
export const rowWithCell = (scope, text) =>
  scope.locator('tr').filter({ has: scope.getByRole('cell', { name: text, exact: true }) });

/** Texts of the XAF toast messages currently shown. @param {Page} page */
export const readAlerts = async (page) => (await page.locator('.xaf-alert-message').allInnerTexts()).map((t) => t.trim());
