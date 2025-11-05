FROM dart:stable AS build

WORKDIR /app

COPY pubspec.* ./

RUN dart pub get

COPY . .

RUN dart pub get --offline

RUN dart compile exe bin/Service.dart -o bin/server

FROM debian:stable-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/server

EXPOSE 8080

CMD ["/app/server"] 