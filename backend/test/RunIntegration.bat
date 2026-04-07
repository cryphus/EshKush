@echo off
REM Запуск интеграционных тестов.
REM Требует запущенного сервера (docker compose up или dart run bin/Service.dart).
REM TEST_BASE_URL по умолчанию: http://localhost:8080

if "%TEST_BASE_URL%"=="" set TEST_BASE_URL=http://localhost:8080

echo [integration] Базовый URL: %TEST_BASE_URL%
echo [integration] Запуск интеграционных тестов...
dart test test/integration --reporter expanded

if %ERRORLEVEL% EQU 0 (
    echo [integration] ВСЕ ТЕСТЫ ПРОЙДЕНЫ
) else (
    echo [integration] ЕСТЬ ПРОВАЛИВШИЕСЯ ТЕСТЫ
    exit /b 1
)
