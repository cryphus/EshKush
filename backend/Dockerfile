FROM dart:stable AS build

WORKDIR /app

# Копирование shared пакета (должен быть на уровень выше для path: ../shared)
COPY shared /shared

COPY backend/pubspec.* ./

RUN dart pub get

COPY backend/ .

RUN dart pub get --offline

RUN dart compile exe bin/Service.dart -o bin/server

FROM debian:stable-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/server
COPY --from=build /app/lib/config/swagger.json /app/lib/config/swagger.json

EXPOSE 8080

CMD ["/app/server"] 