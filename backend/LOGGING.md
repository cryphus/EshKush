Логирование (Backend)

Обзор

- Централизованное логирование реализовано через middleware `LoggingMiddleware` и утилиту `LoggingUtils`.
- Все запросы и ответы логируются в JSON-формате, чувствительные данные маскируются.
- Для корреляции используется `requestId` (берётся из входящего `X-Request-Id` или генерируется) и прокидывается в `Response` тем же заголовком.

Формат логов

- События:
  - request: { ts, level, event, requestId, method, url, headers(masked), clientIp }
  - response: { ts, level, event, requestId, status, headers(masked), durationMs }
  - request_body (для непубличных путей): { ts, level, event, requestId, body(sanitized) }
  - info/error: { ts, level, event, requestId, message, context?/error?/stack? }

Правила

- Тело запроса не логируется для `/auth/*` и `/login`.
- Санитизация: HTML/теги удаляются, поля вроде password/token/cookies/API-keys и данные карт маскируются.
- Заголовки `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key` маскируются в логах.

Конфигурация

- Переменные окружения:
  - `LOG_LEVEL` — debug | info | warn | error (по умолчанию: info)
  - `LOG_JSON` — true/false (по умолчанию: true)
- Управление уровнями производится в `LoggingUtils` (соответствие уровней: debug=10, info=20, warn=30, error=40).

Корреляция

- `LoggingMiddleware` добавляет `requestId` в `Request.context['requestId']`.
- Контроллеры извлекают его через `RequestContextUtils.getRequestId(request)` и передают в `LoggingUtils`.
- Ответ всегда содержит `X-Request-Id` для трейсинга на клиенте/в логах.

Лучшие практики

- Не логируйте PII/секреты вручную; используйте `SafeLoggingUtils.logData` для структур.
- Не вызывайте `response.readAsString()` в контроллерах — это делает middleware/утилиты при необходимости.
- Для критических событий используйте `LoggingUtils.logError`, для бизнес-событий — `logInfo`/`logOrderOperation`.

Примеры

- Лог запроса:
  {"ts":"2025-10-05T12:00:00Z","level":"info","event":"request","requestId":"req-...","method":"POST","url":"/orders","headers":{...},"clientIp":"1.2.3.4"}

- Лог ответа:
  {"ts":"2025-10-05T12:00:00Z","level":"info","event":"response","requestId":"req-...","status":200,"headers":{...},"durationMs":42}

Интеграция с внешними системами

- Логи выводятся в stdout — удобно собирать их Docker/Orchestrator и отправлять в ELK/Loki/Splunk.
- Для парсинга используйте JSON-парсер. Важные ключи: event, requestId, level, method/url/status.


