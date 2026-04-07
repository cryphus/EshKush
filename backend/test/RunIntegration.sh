#!/usr/bin/env bash
# Запуск интеграционных тестов.
# Требует запущенного сервера (docker compose up или dart run bin/Service.dart).

export TEST_BASE_URL="${TEST_BASE_URL:-http://localhost:8080}"

echo "[integration] Базовый URL: $TEST_BASE_URL"
echo "[integration] Запуск интеграционных тестов..."
dart test test/integration --reporter expanded

if [ $? -eq 0 ]; then
  echo "[integration] ВСЕ ТЕСТЫ ПРОЙДЕНЫ"
else
  echo "[integration] ЕСТЬ ПРОВАЛИВШИЕСЯ ТЕСТЫ"
  exit 1
fi