// @ts-check
// Portal smoke checks: the saved session works and a standard list view opens.
import { test, expect } from '@playwright/test';
import { openView } from '../support/portal.js';

test.describe('Portal smoke', () => {
  test('home page opens with the saved session (no login form)', async ({ page }) => {
    await page.goto('');
    await expect(page.locator('input[type=password]')).toHaveCount(0);
    await expect(page.locator('.dxbl-grid, .dxbl-fl, .xaf-sidebar, nav').first()).toBeVisible({ timeout: 60_000 });
  });

  test('Inventory > Item list view opens', async ({ page }) => {
    await openView(page, 'InvItem_ListView');
    await expect(page.getByPlaceholder('Text to search').first()).toBeVisible();
    await expect(page.locator('table tbody tr').first()).toBeVisible();
  });
});
