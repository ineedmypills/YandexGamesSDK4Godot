const { test, expect } = require('@playwright/test');

test.describe('Yandex Games SDK integration', () => {
  const base = process.env.YANDEX_GAME_URL || process.env.YANDEX_BASE_URL || 'http://localhost:8000';

  test.beforeEach(async ({ page }) => {
    await page.goto(base, { waitUntil: 'domcontentloaded' });
  });

  test('SDK is present on window', async ({ page }) => {
    const sdkExists = await page.evaluate(() => {
      return !!(window.yaGames || window.YandexGames || window.ya);
    });
    expect(sdkExists).toBeTruthy();
  });

  test('SDK init (if present) should initialize with Game ID', async ({ page }) => {
    const hasInit = await page.evaluate(() => {
      const sdk = window.yaGames || window.YandexGames || window.ya;
      if (!sdk) return 'no-sdk';
      return typeof sdk.init === 'function' ? 'has-init' : 'no-init';
    });
    if (hasInit !== 'has-init') test.skip('SDK init not available in this build');

    const result = await page.evaluate(async (gameId) => {
      const sdk = window.yaGames || window.YandexGames || window.ya;
      try {
        // Many Yandex SDKs accept init() or similar. Adjust as needed.
        await sdk.init({ gameId });
        return { ok: true };
      } catch (e) {
        return { ok: false, err: String(e) };
      }
    }, process.env.YANDEX_GAME_ID || '');

    expect(result.ok).toBeTruthy();
  });

  test('Optional: server API endpoint reachable with API key', async ({ request }) => {
    if (!process.env.YANDEX_API_KEY || !process.env.YANDEX_API_ENDPOINT) test.skip();
    const res = await request.get(process.env.YANDEX_API_ENDPOINT, {
      headers: { Authorization: `Bearer ${process.env.YANDEX_API_KEY}` }
    });
    expect(res.ok()).toBeTruthy();
  });
});
