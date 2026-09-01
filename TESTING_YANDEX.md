Интеграционные тесты Yandex (Playwright)

Коротко:
- Playwright запускает сборку страницы игры (web export) и проверяет наличие Yandex SDK и простые API-запросы.
- CI использует GitHub Actions — секреты хранятся в repo secrets.

Необходимые secrets (в Settings → Secrets):
- YANDEX_GAME_URL — полный URL до веб-версии игры (например https://staging.example.com/)
- YANDEX_BASE_URL — базовый URL API (опционально)
- YANDEX_GAME_ID — Game ID в Yandex Games
- YANDEX_API_KEY — (опционально) ключ для серверных API
- YANDEX_API_ENDPOINT — (опционально) endpoint для тестового GET-запроса

Локально:
1. Установить зависимости: npm ci
2. Установить браузеры: npx playwright install
3. Экспортировать Godot web build и запустить локальный сервер (например: python3 -m http.server 8000 в папке с index.html)
4. Выполнить: YANDEX_GAME_URL=http://localhost:8000 npm run test:integration

Что тестируется (можно расширить):
- Наличие глобального SDK объекта (window.yaGames / window.YandexGames / window.ya)
- Вызов init() с Game ID (если реализовано в билде)
- Доступность внешнего API с API key (опционально)

Безопасность:
- Никогда не коммитить реальные креды в репозиторий — только GitHub Secrets
- Выдавать временные ключи или тестовые аккаунты с минимальными правами

Дальше:
- Если готовы дать temporary credentials — можно добавить тест входа через SDK и проверку leaderboards/payments.
- Могу автоматически создать PR с готовым скелетом тестов (и инструкции по secrets).