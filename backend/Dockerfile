# ── Stage 1: зависимости + исходный код ────────────────────────────────────
FROM dart:stable AS deps

WORKDIR /app

# Shared-пакет нужен для path: ../shared в pubspec.yaml
COPY shared /shared
COPY backend/pubspec.* ./
RUN dart pub get
COPY backend/ .
RUN dart pub get --offline

# ── Stage 2: unit-тесты (без БД) ────────────────────────────────────────────
#
# docker-compose запускает этот stage как отдельный сервис "unit-tests".
# Если тесты падают — контейнер завершается с ненулевым кодом,
# и сервис "backend" (depends_on: unit-tests: service_completed_successfully)
# не запускается.
FROM deps AS test

CMD ["dart", "test", "test/unit", "--reporter", "expanded"]

# ── Stage 2b: интеграционные тесты репозиториев (нужен postgres-test) ────────
#
# docker-compose: сервис "repo-tests". Зависит от postgres-test: healthy.
# Переменные: TEST_DB_HOST, TEST_DB_PORT, TEST_DB_NAME, TEST_DB_USER, TEST_DB_PASSWORD.
FROM deps AS repo-tests

CMD ["dart", "test", "test/integration/repositories", "test/integration/services", "--reporter", "expanded", "--concurrency=1"]

# ── Stage 2c: e2e-тесты HTTP-уровня (нужен запущенный backend) ───────────────
#
# docker-compose: сервис "e2e-tests". Зависит от backend: healthy.
# Сначала сидирует admin-пользователя в основную БД, затем гоняет тесты.
# Переменные: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD,
#             TEST_BASE_URL, JWT_SECRET, JWT_REFRESH_SECRET.
FROM deps AS e2e-tests

CMD ["sh", "-c", "dart run bin/SeedE2eData.dart && dart test test/integration/RbacAccessTest.dart test/integration/http --reporter expanded --concurrency=1"]

# ── Stage 3: компиляция бинарников ──────────────────────────────────────────
FROM deps AS build

RUN dart compile exe bin/Service.dart -o bin/server
RUN dart compile exe bin/Migrate.dart -o bin/migrate
RUN dart compile exe bin/SeedDemoData.dart -o bin/seed-demo

# ── Stage 4: финальный runtime-образ ────────────────────────────────────────
FROM debian:stable-slim AS runtime
WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server  /app/server
COPY --from=build /app/bin/migrate /app/migrate
COPY --from=build /app/bin/seed-demo /app/seed-demo
COPY --from=build /app/database/migrations /app/database/migrations
COPY --from=build /app/public /app/public
COPY --from=build /app/lib/config/swagger.json /app/lib/config/swagger.json

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health/ || exit 1

CMD ["/app/server"]
