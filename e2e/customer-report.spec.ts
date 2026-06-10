import { test, expect } from '@playwright/test';

async function login(page: import('@playwright/test').Page) {
  await page.goto('/user/spree_user/sign_in');
  await page.waitForSelector('#spree_user_email', { timeout: 10_000 });
  await page.fill('#spree_user_email', 'admin@example.org');
  await page.fill('#spree_user_password', 'ofn123');
  await page.click('input[type="submit"]');
  await page.waitForTimeout(3000);
}

async function runReport(page: import('@playwright/test').Page): Promise<string> {
  await page.selectOption('#report_format', 'csv');

  await page.locator('#report-go button[type="submit"]').click();

  const downloadLink = page.locator('.download a');
  await expect(downloadLink).toBeVisible({ timeout: 30_000 });

  const href = await downloadLink.getAttribute('href');
  const csv = await page.evaluate(async (url) => {
    const response = await fetch(url);
    return response.text();
  }, href);
  return csv;
}

function parseCSV(csv: string): string[][] {
  return csv.trim().split('\n').map(row => {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;
    for (const ch of row) {
      if (ch === '"') { inQuotes = !inQuotes; continue; }
      if (ch === ',' && !inQuotes) { result.push(current.trim()); current = ''; continue; }
      current += ch;
    }
    result.push(current.trim());
    return result;
  });
}

test.describe('Customer Report - Balance Due & Credit Due', () => {
  test('report includes Balance Due and Credit Due columns with correct values', async ({ page }) => {
    await login(page);
    await page.goto('/admin/reports/customers');
    await page.waitForSelector('#report_format', { timeout: 15_000 });

    const csv = await runReport(page);
    const rows = parseCSV(csv);

    // Verify header includes the two new columns
    const header = rows[0];
    expect(header).toContain('Balance Due ($)');
    expect(header).toContain('Available Credit ($)');

    // Find column indices
    const balanceIdx = header.indexOf('Balance Due ($)');
    const creditIdx = header.indexOf('Available Credit ($)');
    expect(balanceIdx).toBeGreaterThanOrEqual(0);
    expect(creditIdx).toBeGreaterThanOrEqual(0);

    // Verify each data row has valid non-negative numeric values in both columns.
    // Non-zero value assertions are covered by customer-report-journey.spec.ts,
    // which sets up its own test data rather than relying on seed data.
    for (let i = 1; i < rows.length; i++) {
      const balanceNum = parseFloat(rows[i][balanceIdx].replace(/[$,]/g, ''));
      const creditNum = parseFloat(rows[i][creditIdx].replace(/[$,]/g, ''));
      expect(isNaN(balanceNum)).toBe(false);
      expect(isNaN(creditNum)).toBe(false);
      expect(balanceNum).toBeGreaterThanOrEqual(0);
      expect(creditNum).toBeGreaterThanOrEqual(0);
    }
  });
});
