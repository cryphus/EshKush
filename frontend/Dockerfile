# Этап 1: Сборка
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

ARG API_BASE_URL=http://localhost:3000
ARG TELEGRAM_API_URL=http://localhost:5000/api
ARG GOOGLE_CLIENT_ID=

# Установка рабочей директории
WORKDIR /app

# Копирование shared пакета (должен быть на уровень выше frontend для path: ../shared)
COPY shared /shared

# Копирование файлов проекта
COPY frontend/ .

# Получение зависимостей и сборка
RUN flutter config --enable-web
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=TELEGRAM_API_URL=${TELEGRAM_API_URL} \
    --dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}

# Этап 2: Настройка Nginx
FROM nginx:stable-alpine

# Копирование собранных файлов и конфигурации
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/nginx.conf

# Экспорт порта
EXPOSE 80

# Запуск Nginx
CMD ["nginx", "-g", "daemon off;"] 
