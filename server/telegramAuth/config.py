import os
from dotenv import load_dotenv

# Загрузка переменных окружения из .env файла
load_dotenv()

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN = "8194426358:AAGdJv_U8XkWgI9VAMcqNZ7MIwH1sTj5b90"
BOT_USERNAME = "eshkush_bot"

# Настройки для локальной разработки
WEBHOOK_HOST = "localhost"
WEBHOOK_SSL_CERT = None  # Для локальной разработки SSL не требуется

# Настройки базы данных
DATABASE_PATH = "app/database.db"

# Application Configuration
APP_URL = os.getenv('APP_URL', 'http://localhost:5000')
TOKEN_EXPIRATION_MINUTES = 10  # Время жизни токена авторизации в минутах