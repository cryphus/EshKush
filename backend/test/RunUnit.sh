#!/usr/bin/env bash
# Запуск unit-тестов (не требуют запущенного сервера).
# JWT_SECRET и JWT_REFRESH_SECRET нужны для тестов AuthUtils и SecurityMiddleware.

export JWT_SECRET="testsecretforjwttestingatleast32chars"
export JWT_REFRESH_SECRET="testrefreshsecretforjwttests32chars__"
export BCRYPT_LOG_ROUNDS=10

echo "[unit] Запуск unit-тестов..."
dart test test/unit --reporter expanded

if [ $? -eq 0 ]; then
  echo "[unit] ВСЕ ТЕСТЫ ПРОЙДЕНЫ"
else
  echo "[unit] ЕСТЬ ПРОВАЛИВШИЕСЯ ТЕСТЫ"
  exit 1
fi