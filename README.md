# EshKush — запуск и структура

## Структура
- `frontend/` — Flutter-приложение (web/мобильные клиенты), ассеты в `frontend/assets`.
- `backend/` — Dart Shelf API + Swagger (`/swagger`, `lib/config/swagger.json`).
- `shared/` — общие типы (Dart), подключаются как `path: ../shared`.
- `telegramAuth/` — сервис Telegram-бота на Python.
- `docker-compose.yml` — сборка инфраструктуры (Postgres, Redis, backend, Nginx).

## Быстрый старт через Docker
Требования: Docker, Docker Compose.

```bash
# из корня репозитория
docker-compose up -d --build
```

- Backend: http://localhost:8080  
- Swagger UI: http://localhost:8080/swagger  
- Nginx (прокси, если используется): http://localhost:80  
- Postgres: порт хоста `5433`, БД `flutter_auth`, пользователь `postgres`, пароль `TQr132123`  
- Redis: порт хоста `6379`

Остановка и очистка данных (если нужно пересоздать тома БД/Redis):
```bash
docker-compose down -v
```

## Локальный запуск backend (без Docker)
Требования: Dart SDK ≥ 3.0.
```bash
cd backend
dart pub get

# переменные окружения (пример для локального Postgres)
set DB_HOST=localhost
set DB_PORT=5433
set DB_NAME=flutter_auth
set DB_USER=postgres
set DB_PASSWORD=TQr132123
set PORT=8080

dart run bin/Service.dart
```
API будет доступно на `http://localhost:8080`, Swagger — `http://localhost:8080/swagger`.

## Локальный запуск frontend
Требования: Flutter SDK ≥ 3.0, Web/Chrome для веб-сборки.
```bash
cd frontend
flutter pub get

# веб
flutter run -d chrome

# мобильные платформы
flutter run          # gradle wrapper 8.11.1 уже настроен
```
Ассеты указаны в `pubspec.yaml` как подпапки (`assets/icons/`, `assets/images/`, `assets/fonts/`), пути в коде — относительно этих папок, например `icons/star.svg`.

## Сборка frontend (web) в Docker
Используется `frontend/Dockerfile` (Flutter web → Nginx). Пример:
```bash
docker build -t eshkush-frontend -f frontend/Dockerfile .
```
Собранный web кладётся в `/usr/share/nginx/html` образа.

## Shared пакет
- Подключён в `frontend/pubspec.yaml` и `backend/pubspec.yaml` как `path: ../shared`.
- При сборке Docker-образов `shared/` копируется внутрь (см. Dockerfile’ы).

## TelegramAuth сервис
- Код: `telegramAuth/`, зависимости — `requirements.txt`.
```bash
cd telegramAuth
pip install -r requirements.txt
python -m app.bot
```
Настройте `config.py` под свои токены.

## Полезное
- Swagger спецификация: `backend/lib/config/swagger.json` (`openapi: 3.0.0`).
- Nginx конфиг: `nginx.conf` (корень репо).
- Для пересборки и обновления зависимостей в контейнерах перезапускайте `docker-compose up -d --build`.

## Частые проблемы
- **Дублирование `assets/assets/...`**: оставляйте в коде пути вида `icons/xxx.svg`, а в `pubspec.yaml` — подпапки `assets/icons/`, `assets/images/`, `assets/fonts/`.
- **Postgres не стартует после обновления образа**: удалите тома `docker-compose down -v` и поднимите снова на фиксированной версии `postgres:16-alpine`.
- **Gradle version check (Android)**: wrapper обновлён до `8.11.1`; если SDK жалуется — выполните `./gradlew wrapper --gradle-version 8.11.1`.

## Правила коммитов
Используем префиксы по типу изменений:
- `feat:` — новая функциональность.
- `fix:` — исправление багов.
- `docs:` — документация, README, схемы.
- `chore:` — обслуживание, настройки, мелкие правки без логики.
- `refactor:` — переработка кода без изменения поведения.
- `perf:` — оптимизация производительности.
- `test:` — тесты, фикстуры.
- `build:` — сборка, зависимости, Dockerfile, Gradle/Flutter config.
- `ci:` — CI/CD скрипты и пайплайны.
- `revert:` — откат предыдущего коммита.

Формат заголовка: `<prefix>: кратко что сделано`
Примеры:
- `feat: add VK web auth flow`
- `fix: prevent assets/assets svg 404`
- `chore: update docker-compose to postgres 16`
- `build: bump gradle wrapper to 8.11.1`

