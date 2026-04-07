@echo off
setlocal enabledelayedexpansion

REM ═══════════════════════════════════════════════════════════════
REM  RunAll.bat — запускает все тесты (unit + integration)
REM  и выводит сводку ошибок в конце.
REM
REM  Использование:
REM    test\RunAll.bat                        (только unit)
REM    test\RunAll.bat --integration          (unit + integration)
REM    TEST_BASE_URL=http://... RunAll.bat --integration
REM ═══════════════════════════════════════════════════════════════

set JWT_SECRET=testsecretforjwttestingatleast32chars
set JWT_REFRESH_SECRET=testrefreshsecretforjwttests32chars__
set BCRYPT_LOG_ROUNDS=10
if "%TEST_BASE_URL%"=="" set TEST_BASE_URL=http://localhost:8080

set RUN_INTEGRATION=0
if "%1"=="--integration" set RUN_INTEGRATION=1

set UNIT_FAILED=0
set INTEGRATION_FAILED=0
set UNIT_LOG=%TEMP%\eshkush_unit_tests.log
set INTEGRATION_LOG=%TEMP%\eshkush_integration_tests.log

REM ───────────────────────────── UNIT ─────────────────────────────
echo.
echo ╔══════════════════════════════════════════════╗
echo ║           UNIT-ТЕСТЫ                         ║
echo ╚══════════════════════════════════════════════╝
dart test test/unit --reporter expanded 2>&1 > "%UNIT_LOG%"
set UNIT_EXIT=!ERRORLEVEL!
type "%UNIT_LOG%"
if not !UNIT_EXIT! EQU 0 set UNIT_FAILED=1

REM ───────────────────────────── INTEGRATION ──────────────────────
if "%RUN_INTEGRATION%"=="1" (
    echo.
    echo ╔══════════════════════════════════════════════╗
    echo ║           ИНТЕГРАЦИОННЫЕ ТЕСТЫ               ║
    echo ║           Сервер: %TEST_BASE_URL%
    echo ╚══════════════════════════════════════════════╝
    dart test test/integration --reporter expanded 2>&1 > "%INTEGRATION_LOG%"
    set INTEGRATION_EXIT=!ERRORLEVEL!
    type "%INTEGRATION_LOG%"
    if not !INTEGRATION_EXIT! EQU 0 set INTEGRATION_FAILED=1
)

REM ───────────────────────────── СВОДКА ───────────────────────────
echo.
echo ╔══════════════════════════════════════════════╗
echo ║                  СВОДКА                      ║
echo ╚══════════════════════════════════════════════╝

REM Вытащить провалившиеся тесты из лога unit-тестов
echo.
echo [unit] Провалившиеся тесты:
set FOUND_UNIT=0
for /f "usebackq tokens=*" %%L in ("%UNIT_LOG%") do (
    echo %%L | findstr /C:"[E]" >nul 2>&1
    if not errorlevel 1 (
        echo   ✗ %%L
        set FOUND_UNIT=1
    )
)
if "%FOUND_UNIT%"=="0" echo   (нет)

REM Вытащить провалившиеся тесты из лога integration-тестов
if "%RUN_INTEGRATION%"=="1" (
    echo.
    echo [integration] Провалившиеся тесты:
    set FOUND_INT=0
    for /f "usebackq tokens=*" %%L in ("%INTEGRATION_LOG%") do (
        echo %%L | findstr /C:"[E]" >nul 2>&1
        if not errorlevel 1 (
            echo   ✗ %%L
            set FOUND_INT=1
        )
    )
    if "!FOUND_INT!"=="0" echo   (нет)
)

REM ───────────────────────────── ИТОГ ─────────────────────────────
echo.
if "%UNIT_FAILED%"=="0" (
    echo [unit]         ВСЕ ТЕСТЫ ПРОЙДЕНЫ ✓
) else (
    echo [unit]         ЕСТЬ ОШИБКИ ✗
)

if "%RUN_INTEGRATION%"=="1" (
    if "%INTEGRATION_FAILED%"=="0" (
        echo [integration] ВСЕ ТЕСТЫ ПРОЙДЕНЫ ✓
    ) else (
        echo [integration] ЕСТЬ ОШИБКИ ✗
    )
)

echo.
if "%UNIT_FAILED%"=="1" exit /b 1
if "%INTEGRATION_FAILED%"=="1" exit /b 1
exit /b 0