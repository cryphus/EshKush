FROM dart:stable AS build

WORKDIR /app

# Копирование shared пакета (должен быть на уровень выше для path: ../shared)
COPY shared /shared
COPY backend/pubspec.* ./

RUN dart pub get

COPY backend/ .
# Тестовый файл лежит рядом с backend/ на уровне проекта
COPY test/ApiTest.dart test/ApiTest.dart

RUN dart pub get --offline

# Компиляция сервера
RUN dart compile exe bin/Service.dart -o bin/server

# Компиляция тест-бинарника (только dart:io + dart:convert — внешние пакеты не нужны)
RUN dart compile exe test/ApiTest.dart -o bin/api_test

FROM debian:stable-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/server
COPY --from=build /app/bin/api_test /app/api_test
COPY --from=build /app/lib/config/swagger.json /app/lib/config/swagger.json

EXPOSE 8080

CMD ["/app/server"] 