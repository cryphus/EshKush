# EshKush — запуск, структура и конфигурация

## Автономная демоверсия для показа

```sh
docker compose -f compose.demo.yml up --build -d --wait
```

Откройте http://127.0.0.1:8080/demo: приложение покупателя, кабинет партнёра и администратор. Каталог и история уже наполнены; оплата, соцсети и поддержка работают через локальные заглушки. Внешние ключи и аккаунты не нужны. [Запуск, сценарий показа и проверки](DEMO.md).

## Структура

| Папка | Описание |
|---|---|
| `frontend/` | Flutter-приложение (web / Android / iOS) |
| `backend/` | Dart Shelf API + Swagger (`/swagger`) |
| `shared/` | Общие типы Dart, подключаются как `path: ../shared` |
| `telegramAuth/` | Telegram-бот + Flask API (Python) |
| `partner-web/` | Веб-панель партнёра — Nuxt 3 (Vue), отдельное SPA-приложение |
| `docker-compose.yml` | Инфраструктура: Postgres, Redis, backend, Nginx |
| `scripts/` | Вспомогательные bash-скрипты запуска и сборки |

---

## Переменные окружения

### Структура env-файлов

```
.env.example            ← шаблон (в git)
.env                    ← основной файл, его читает docker-compose (gitignored)
.env.production         ← продакшн (gitignored, создай на сервере)

telegramAuth/.env.example   ← шаблон бота (в git)
telegramAuth/.env           ← разработка (gitignored)
telegramAuth/.env.production ← продакшн (gitignored)
```

> `docker-compose.yml` ссылается на `env_file: - .env`, поэтому именно
> файл `.env` обязателен для запуска через Docker. В репозитории уже создан
> готовый `.env` с рабочими значениями для локальной разработки.

### Первый запуск

```bash
# Backend + Docker — .env уже создан с локальными значениями.
# Если его нет: cp .env.example .env  и заполни секреты.

# TelegramAuth
cp telegramAuth/.env.example telegramAuth/.env
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
| `API_BASE_URL` | URL backend (для Flutter сборки) | `http://localhost:3000` |
| `TELEGRAM_API_URL` | URL Flask-сервиса бота (для Flutter) | `http://localhost:5000/api` |
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 Client ID (для Flutter) | `672295...apps.googleusercontent.com` |
| `IMAGE_BASE_URL` | Базовый URL сервера изображений (для Flutter) | `http://91.186.217.192` |

> **Для продакшна**: сгенерируй секреты командой `openssl rand -base64 48`.

---

## Быстрый старт через Docker

Требования: Docker, Docker Compose.

```bash
# Разработка (docker-compose автоматически читает .env из корня)
docker-compose up -d --build

# Продакшн
docker-compose --env-file .env.production up -d --build
```

Сервисы после запуска:

| Сервис | URL |
|---|---|
| Backend API | http://localhost:3000 |
| Swagger UI | http://localhost:3000/swagger |
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

API будет доступно на `http://localhost:3000`, Swagger — `http://localhost:3000/swagger`.

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
  --dart-define=API_BASE_URL=http://localhost:3000 \
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

### Сборка мобильного приложения (Android)

```bash
cd frontend
flutter pub get

# Debug APK (для тестирования на устройстве)
flutter build apk --debug
# Готово: build/app/outputs/flutter-apk/app-debug.apk

# Release APK (для раздачи) — передай реальные конфиги через --dart-define:
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.eshkush.app \
  --dart-define=IMAGE_BASE_URL=https://media.eshkush.app \
  --dart-define=GOOGLE_CLIENT_ID=ВАШ_CLIENT_ID \
  --dart-define=BOT_USERNAME=eshkush_bot
```

**Особенности Android-сборки:**

| Что | Значение | Где |
|---|---|---|
| Application ID | `com.eshkush.app` | `android/app/build.gradle.kts` |
| `minSdkVersion` | **26** | `android/app/build.gradle.kts` |
| Cleartext HTTP | разрешён (backend/медиа по `http://`) | `android/app/src/main/res/xml/network_security_config.xml` |

> **Подключение к backend с устройства.** На реальном устройстве/эмуляторе
> `localhost` указывает на сам телефон, а не на твой ПК. Для **эмулятора**
> используй `10.0.2.2` вместо `localhost` (скрипт `run_test.sh` подменяет
> автоматически при `-d android`/`emulator`). Для **реального устройства**
> укажи IP компьютера в локальной сети, напр. `--dart-define=API_BASE_URL=http://192.168.1.10:3000`.

> **HTTPS в production.** Cleartext-трафик разрешён для разработки. Перед
> публикацией переведи API и медиа на HTTPS и ужесточи
> `network_security_config.xml` (запретить cleartext).

### Как работают конфиги в Flutter

Flutter **не умеет читать .env в runtime**. Все конфиги вшиваются на этапе компиляции через `--dart-define` и доступны в коде через `AppConfig`:

```dart
// frontend/lib/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
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
| `BACKEND_URL` | URL Dart backend (`http://localhost:3000` / `http://backend:3000`) |
| `APP_URL` | URL frontend-приложения (для deep link) |
| `FLASK_PORT` | Порт Flask API (default: `5000`) |

---

## Веб-панель партнёра (partner-web)

Отдельное SPA-приложение на Nuxt 3 — не часть мобильного/веб-приложения
пользователя. Партнёры и админы управляют точками, предложениями и заказами,
смотрят аналитику с графиками. Аутентификация — логин/пароль через тот же
Dart backend (`POST /login`), доступ только ролям `partner`/`admin`.

```bash
cd partner-web
npm install

# По умолчанию ходит на http://localhost:3000 (см. .env.example)
cp .env.example .env

npm run dev        # http://localhost:3010
npm run build       # продакшн-сборка (.output/)
```

> Backend должен разрешать origin панели в `ALLOWED_ORIGINS` (корневой `.env`).
> Для dev-порта 3010 уже добавлено `http://localhost:3010,http://127.0.0.1:3010`.

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
| `Could not close incremental caches` (Kotlin, Windows) | Уже отключено: `kotlin.incremental=false` в `android/gradle.properties`. Если всплыло снова — `flutter clean` |
| Android: данные/картинки не грузятся (cleartext) | Уже разрешено через `network_security_config.xml`; проверь, что API доступен с устройства (см. раздел Android) |
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
