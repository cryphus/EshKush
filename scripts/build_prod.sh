#!/usr/bin/env bash
# ============================================================
# Сборка Flutter web для продакшна.
# Читает переменные из корневого .env.production и передаёт
# их как --dart-define флаги.
#
# Использование:
#   bash scripts/build_prod.sh
#
# Собранные файлы окажутся в frontend/build/web/
# ============================================================
set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env.production"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Файл $ENV_FILE не найден."
  echo "Скопируй .env.example в .env.production и заполни значения."
  exit 1
fi

# Проверяем, что секреты заменены
if grep -q "REPLACE_WITH" "$ENV_FILE"; then
  echo "ОШИБКА: в $ENV_FILE есть незаполненные значения (REPLACE_WITH_...)."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
set +a

cd "$(dirname "$0")/../frontend"

flutter build web \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=TELEGRAM_API_URL="${TELEGRAM_API_URL}" \
  --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID}" \
  --dart-define=BOT_USERNAME="${BOT_USERNAME:-eshkush_bot}" \
  --dart-define=IMAGE_BASE_URL="${IMAGE_BASE_URL}"

echo ""
echo "Сборка завершена: frontend/build/web/"
