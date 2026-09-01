// Basic Playwright config for Yandex integration tests
module.exports = {
  timeout: 60000,
  use: {
    headless: true,
    baseURL: process.env.YANDEX_BASE_URL || '',
    actionTimeout: 10000
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } }
  ],
  testDir: 'tests'
};
