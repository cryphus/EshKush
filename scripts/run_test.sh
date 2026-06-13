#!/usr/bin/env bash
# ============================================================
# Запуск Flutter-приложения в режиме разработки (test).
# Читает переменные из .env.test (или .env, если первого нет)
# и передаёт их как --dart-define флаги.
#
# Использование:
#   bash scripts/run_test.sh                      # Chrome (web)
#   bash scripts/run_test.sh -d emulator-5554     # Android-эмулятор
#   bash scripts/run_test.sh -d <android-device>  # реальное устройство
#
# Для Android-эмулятора localhost хоста недоступен — скрипт
# автоматически подменяет localhost/127.0.0.1 на 10.0.2.2.
# ============================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ENV_FILE="$ROOT_DIR/.env.test"
if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE="$ROOT_DIR/.env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Не найден ни .env.test, ни .env в корне проекта."
  echo "Скопируй .env.example в .env и заполни значения."
  exit 1
fi

# Читаем env-файл, пропуская комментарии и пустые строки
set -a
# shellcheck disable=SC1090
source <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
set +a

API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
TELEGRAM_API_URL="${TELEGRAM_API_URL:-http://localhost:5000/api}"
IMAGE_BASE_URL="${IMAGE_BASE_URL:-http://91.186.217.192}"

# Для Android-эмулятора localhost указывает на сам эмулятор, а не на хост.
# Подменяем на 10.0.2.2 (специальный alias хоста в Android-эмуляторе).
ARGS="$*"
if [[ "$ARGS" == *"android"* || "$ARGS" == *"emulator"* ]]; then
  API_BASE_URL="${API_BASE_URL//localhost/10.0.2.2}"
  API_BASE_URL="${API_BASE_URL//127.0.0.1/10.0.2.2}"
  TELEGRAM_API_URL="${TELEGRAM_API_URL//localhost/10.0.2.2}"
  TELEGRAM_API_URL="${TELEGRAM_API_URL//127.0.0.1/10.0.2.2}"
  echo "Android-режим: API_BASE_URL=$API_BASE_URL"
fi

cd "$ROOT_DIR/frontend"

exec flutter run \
  "${@:--d chrome}" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=TELEGRAM_API_URL="$TELEGRAM_API_URL" \
  --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" \
  --dart-define=BOT_USERNAME="${BOT_USERNAME:-eshkush_bot}" \
  --dart-define=IMAGE_BASE_URL="$IMAGE_BASE_URL"
