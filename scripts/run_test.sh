#!/usr/bin/env bash
# ============================================================
# Запуск Flutter-приложения в режиме разработки (test).
# Читает переменные из корневого .env.test и передаёт их
# как --dart-define флаги.
#
# Использование:
#   bash scripts/run_test.sh           # Chrome (web)
#   bash scripts/run_test.sh -d emulator-5554  # Android-эмулятор
# ============================================================
set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env.test"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Файл $ENV_FILE не найден."
  echo "Скопируй .env.example в .env.test и заполни значения."
  exit 1
fi

# Читаем .env.test, пропуская комментарии и пустые строки
set -a
# shellcheck disable=SC1090
source <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
set +a

cd "$(dirname "$0")/../frontend"

exec flutter run \
  "${@:--d chrome}" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:3000}" \
  --dart-define=TELEGRAM_API_URL="${TELEGRAM_API_URL:-http://localhost:5000/api}" \
  --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" \
  --dart-define=BOT_USERNAME="${BOT_USERNAME:-eshkush_bot}" \
  --dart-define=IMAGE_BASE_URL="${IMAGE_BASE_URL:-http://91.186.217.192}"
