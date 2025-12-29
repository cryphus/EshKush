# Этап 1: Сборка
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

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
RUN flutter build web --release

# Этап 2: Настройка Nginx
FROM nginx:stable-alpine

# Копирование собранных файлов и конфигурации
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY frontend/nginx.conf /etc/nginx/nginx.conf

# Экспорт порта
EXPOSE 80

# Запуск Nginx
CMD ["nginx", "-g", "daemon off;"] 