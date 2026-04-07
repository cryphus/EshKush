# EshKush Backend

Dart/Shelf REST API с PostgreSQL, JWT-аутентификацией, RBAC, rate limiting и health check.

---

## Быстрый старт

```bash
# 1. Скопировать конфиг и заполнить значения
cp .env.example .env.test

# 2. Запустить (БД + бэкенд + nginx)
docker compose --env-file .env.test up -d --build

# 3. Проверить готовность
curl http://localhost:8080/health
```

---

## Переменные окружения

Все переменные задаются через `.env`-файл (передаётся в `docker compose --env-file`).  
Шаблон: [`.env.example`](../.env.example) в корне проекта.

| Переменная | Обязательна | По умолчанию | Описание |
|---|---|---|---|
| `ENVIRONMENT` | — | `development` | `development` / `production` / `test` |
| `PORT` | — | `8080` | Порт HTTP-сервера |
| `JWT_SECRET` | **да** | — | Секрет access-токена (≥32 символа) |
| `JWT_REFRESH_SECRET` | **да** | — | Секрет refresh-токена (≥32 символа) |
| `DB_HOST` | — | `localhost` | Хост PostgreSQL |
| `DB_PORT` | — | `5432` | Порт PostgreSQL |
| `DB_NAME` | — | `flutter_auth` | Имя базы данных |
| `DB_USER` | — | `postgres` | Пользователь БД |
| `DB_PASSWORD` | **да** в prod | — | Пароль БД (в `production` обязателен) |
| `ALLOWED_ORIGINS` | — | `http://localhost:3000` | CORS: список origin через запятую |
| `RATE_LIMIT_REQUESTS` | — | `100` | Макс. запросов в окне rate limiter |
| `RATE_LIMIT_WINDOW_MINUTES` | — | `1` | Размер окна rate limiter (минуты) |
| `REDIS_HOST` | — | `redis` | Хост Redis |
| `REDIS_PORT` | — | `6379` | Порт Redis |
| `REDIS_PASSWORD` | — | — | Пароль Redis (пусто = без пароля) |
| `LOG_LEVEL` | — | `info` | `debug` / `info` / `warn` / `error` |
| `LOG_JSON` | — | `true` | `true` — JSON-строки, `false` — текст |
| `RUN_TESTS` | — | `false` | Запустить API-тесты при старте сервера |

> Генерация секретов: `openssl rand -base64 48`

---

## Миграции БД

Миграции находятся в `database/migrations/`. Каждый файл — версионированный SQL-скрипт.  
Применённые версии хранятся в таблице `schema_migrations`.

### Применить миграции

```bash
# Через Docker (рекомендуется)
docker compose --env-file .env.test --profile migrate run --rm migrate

# Локально (нужен dart и доступная БД)
cd backend
DB_HOST=localhost DB_PASSWORD=secret dart run bin/migrate.dart
```

### Добавить новую миграцию

1. Создать файл `database/migrations/002_описание.sql`
2. Написать идемпотентный SQL (`IF NOT EXISTS`, `CREATE OR REPLACE` и т.п.)
3. Запустить `dart run bin/migrate.dart` — применится только новый файл

```sql
-- Пример: database/migrations/002_add_avatar_thumb.sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url_thumb TEXT;
```

> **Важно:** никогда не редактировать уже применённые миграции — создавайте новые.

---

## Health Check

```
GET /health
```

Не требует JWT. Используется балансировщиком/оркестратором для проверки готовности.

**Пример ответа (200 OK):**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 3742,
  "checks": {
    "database": "ok",
    "cache": "ok"
  }
}
```

| Код | Статус | Описание |
|---|---|---|
| `200` | `ok` / `degraded` | Сервис работает |
| `503` | `error` | БД недоступна — сервис не готов |

```bash
curl -s http://localhost:8080/health | jq .
```

---

## Безопасность: доступ к логам

Доступ к логам приложения должен быть ограничен: только уполномоченный персонал (операторы, DevOps) должен иметь возможность читать логи. Рекомендуется настройка политик доступа в среде развёртывания (Kubernetes, Docker, ОС).

Подробнее: [LOGGING.md](LOGGING.md)
