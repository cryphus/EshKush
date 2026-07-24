import os
from dotenv import load_dotenv

# python-dotenv читает .env из текущей директории.
# Для разработки: cp .env.test .env
# Для продакшна:  cp .env.production .env
load_dotenv()

# ── Telegram Bot ──────────────────────────────────────────────────────────────
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '')
BOT_USERNAME = os.getenv('BOT_USERNAME', 'eshkush_bot')

# ── Webhook (только для продакшна) ────────────────────────────────────────────
WEBHOOK_HOST = os.getenv('WEBHOOK_HOST', '')
WEBHOOK_SSL_CERT = os.getenv('WEBHOOK_SSL_CERT') or None

# ── База данных бота (SQLite) ─────────────────────────────────────────────────
DATABASE_PATH = os.getenv('DATABASE_PATH', 'app/database.db')

# ── Сервисы ───────────────────────────────────────────────────────────────────
# URL frontend-приложения для формирования deep link
APP_URL = os.getenv('APP_URL', 'http://localhost:3000')
# URL основного Dart Shelf backend
BACKEND_URL = os.getenv('BACKEND_URL', 'http://localhost:3000')
# Общий секрет для сервис-to-сервис вызова POST /auth/telegram на основном backend
TELEGRAM_SERVICE_SECRET = os.getenv('TELEGRAM_SERVICE_SECRET', '')

# ── Прочее ────────────────────────────────────────────────────────────────────
TOKEN_EXPIRATION_MINUTES = int(os.getenv('TOKEN_EXPIRATION_MINUTES', '10'))
FLASK_PORT = int(os.getenv('FLASK_PORT', '5000'))

# ── Валидация ─────────────────────────────────────────────────────────────────
if not TELEGRAM_BOT_TOKEN:
    raise RuntimeError(
        'TELEGRAM_BOT_TOKEN не задан. '
        'Скопируй telegramAuth/.env.example в telegramAuth/.env и заполни.'
    )
