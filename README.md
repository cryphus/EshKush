# EshKush — запуск, структура и конфигурация

## Структура

| Папка | Описание |
|---|---|
| `frontend/` | Flutter-приложение (web / Android / iOS) |
| `backend/` | Dart Shelf API + Swagger (`/swagger`) |
| `shared/` | Общие типы Dart, подключаются как `path: ../shared` |
| `telegramAuth/` | Telegram-бот + Flask API (Python) |
| `docker-compose.yml` | Инфраструктура: Postgres, Redis, backend, Nginx |
| `scripts/` | Вспомогательные bash-скрипты запуска и сборки |

---

## Переменные окружения

### Структура env-файлов

```
.env.example            ← шаблон (в git)
.env.test               ← разработка / CI (gitignored, создай локально)
.env.production         ← продакшн (gitignored, создай на сервере)

telegramAuth/.env.example   ← шаблон бота (в git)
telegramAuth/.env.test      ← разработка (gitignored)
telegramAuth/.env.production ← продакшн (gitignored)
```

### Первый запуск

```bash
# Backend + Docker
cp .env.example .env.test
# Отредактируй .env.test — все значения уже заполнены для локальной работы

# TelegramAuth
cp telegramAuth/.env.example telegramAuth/.env.test
# Вставь TELEGRAM_BOT_TOKEN от @BotFather
```

### Ключевые переменные (корневой .env)

| Переменная | Описание | Пример (test) |
|---|---|---|
| `ENVIRONMENT` | `test` / `production` | `test` |
| `DB_PASSWORD` | Пароль PostgreSQL | `TQr132123` |
| `JWT_SECRET` | Секрет для access-токенов (≥32 символа) | `EshKushDev2024...` |
| `JWT_REFRESH_SECRET` | Секрет для refresh-токенов | `EshKushDev2024...` |
| `ALLOWED_ORIGINS` | Разрешённые CORS-origin через запятую | `http://localhost:3000` |
| `API_BASE_URL` | URL backend (для Flutter сборки) | `http://localhost:8080` |
| `TELEGRAM_API_URL` | URL Flask-сервиса бота (для Flutter) | `http://localhost:5000/api` |
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 Client ID (для Flutter) | `672295...apps.googleusercontent.com` |
| `IMAGE_BASE_URL` | Базовый URL сервера изображений (для Flutter) | `http://91.186.217.192` |

> **Для продакшна**: сгенерируй секреты командой `openssl rand -base64 48`.

---

## Быстрый старт через Docker

Требования: Docker, Docker Compose.

```bash
# Разработка
docker-compose --env-file .env.test up -d --build

# Продакшн
docker-compose --env-file .env.production up -d --build
```

Сервисы после запуска:

| Сервис | URL |
|---|---|
| Backend API | http://localhost:8080 |
| Swagger UI | http://localhost:8080/swagger |
| Nginx | http://localhost:80 |
| Postgres | localhost:**5433** (БД `flutter_auth`) |
| Redis | localhost:6379 |

Остановка и полная очистка данных:
```bash
docker-compose down -v
```

---

## Локальный запуск backend (без Docker)

Требования: Dart SDK ≥ 3.0, локальный PostgreSQL.

```bash
cd backend
dart pub get

# Создай backend/.env на основе корневого .env.test
cp ../.env.test .env
# Измени DB_HOST=localhost и DB_EXTERNAL_PORT=5432 если Postgres на стандартном порту

dart run bin/Service.dart
```

API будет доступно на `http://localhost:8080`, Swagger — `http://localhost:8080/swagger`.

---

## Запуск frontend (Flutter)

### Разработка (через скрипт)

Скрипт читает переменные из `.env.test` и передаёт их как `--dart-define`:

```bash
bash scripts/run_test.sh              # Chrome
bash scripts/run_test.sh -d android   # Android-устройство
```

### Разработка (вручную)

```bash
cd frontend
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=TELEGRAM_API_URL=http://localhost:5000/api \
  --dart-define=GOOGLE_CLIENT_ID=ВАШ_CLIENT_ID \
  --dart-define=BOT_USERNAME=eshkush_bot \
  --dart-define=IMAGE_BASE_URL=http://91.186.217.192
```

### Сборка web для продакшна

```bash
# Заполни .env.production, затем:
bash scripts/build_prod.sh
# Готово: frontend/build/web/
```

### Как работают конфиги в Flutter

Flutter **не умеет читать .env в runtime**. Все конфиги вшиваются на этапе компиляции через `--dart-define` и доступны в коде через `AppConfig`:

```dart
// frontend/lib/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');
  // ...
}
```

---

## TelegramAuth сервис

```bash
cd telegramAuth
pip install -r requirements.txt

# Выбор окружения
cp .env.test .env          # или .env.production

python -m app.bot
```

### Ключевые переменные бота

| Переменная | Описание |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Токен от @BotFather |
| `BACKEND_URL` | URL Dart backend (`http://localhost:8080` / `http://backend:8080`) |
| `APP_URL` | URL frontend-приложения (для deep link) |
| `FLASK_PORT` | Порт Flask API (default: `5000`) |

---

## Сборка frontend в Docker

```bash
docker build -t eshkush-frontend -f frontend/Dockerfile \
  --build-arg API_BASE_URL=https://api.eshkush.ru \
  --build-arg TELEGRAM_API_URL=https://tgauth.eshkush.ru/api \
  --build-arg GOOGLE_CLIENT_ID=ВАШ_CLIENT_ID \
  --build-arg IMAGE_BASE_URL=https://cdn.eshkush.ru \
  .
```

> `frontend/Dockerfile` должен принимать `ARG` и передавать их как `--dart-define` в `flutter build web`.

---

## Shared пакет

Подключён в `frontend/pubspec.yaml` и `backend/pubspec.yaml` как `path: ../shared`. При Docker-сборке `shared/` копируется в образ (см. Dockerfile'ы).

---

## Полезное

- Swagger: `backend/lib/config/swagger.json` (`openapi: 3.0.0`)
- Nginx конфиг: `nginx.conf` (корень репо)
- Пересборка с обновлением зависимостей: `docker-compose --env-file .env.test up -d --build`

---

## Частые проблемы

| Проблема | Решение |
|---|---|
| `TELEGRAM_BOT_TOKEN не задан` | Создай `telegramAuth/.env` из `telegramAuth/.env.example` |
| `JWT_SECRET не установлен` | Создай `backend/.env` или передай через `--env-file` в docker-compose |
| Postgres не стартует | `docker-compose down -v`, затем снова `up --build` (сбросит тома) |
| `assets/assets/...` 404 | В коде путь `icons/xxx.svg`, в `pubspec.yaml` — `assets/icons/` |
| Gradle version check (Android) | `./gradlew wrapper --gradle-version 8.11.1` |
| Flutter конфиг не применяется | Убедись что передаёшь `--dart-define` при `flutter run` / `flutter build` |

---

## Правила коммитов

Используем префиксы по типу изменений:

| Префикс | Когда |
|---|---|
| `feat:` | Новая функциональность |
| `fix:` | Исправление багов |
| `docs:` | Документация, README |
| `chore:` | Обслуживание, настройки |
| `refactor:` | Переработка кода без изменения поведения |
| `perf:` | Оптимизация |
| `test:` | Тесты, фикстуры |
| `build:` | Сборка, зависимости, Dockerfile |
| `ci:` | CI/CD скрипты |
| `revert:` | Откат коммита |

Формат: `<prefix>: кратко что сделано`

Примеры:
```
feat: add VK web auth flow
fix: prevent assets/assets svg 404
chore: move secrets to .env files
build: bump gradle wrapper to 8.11.1
```
