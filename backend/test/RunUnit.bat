@echo off
REM Запуск unit-тестов (не требуют запущенного сервера).
REM JWT_SECRET и JWT_REFRESH_SECRET нужны для тестов AuthUtils и SecurityMiddleware.

set JWT_SECRET=testsecretforjwttestingatleast32chars
set JWT_REFRESH_SECRET=testrefreshsecretforjwttests32chars__
set BCRYPT_LOG_ROUNDS=10

echo [unit] Запуск unit-тестов...
dart test test/unit --reporter expanded

if %ERRORLEVEL% EQU 0 (
    echo [unit] ВСЕ ТЕСТЫ ПРОЙДЕНЫ
) else (
    echo [unit] ЕСТЬ ПРОВАЛИВШИЕСЯ ТЕСТЫ
    exit /b 1
)