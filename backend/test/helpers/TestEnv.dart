import 'dart:io';

/// Константы тестовой среды.
/// Тесты JWT запускать с:
///   JWT_SECRET=testsecretforjwttestingatleast32chars \
///   JWT_REFRESH_SECRET=testrefreshsecretforjwttests32chars \
///   dart test

const String kTestJwtSecret    = 'testsecretforjwttestingatleast32chars';
const String kTestRefreshSecret = 'testrefreshsecretforjwttests32chars__';

/// Базовый URL для интеграционных тестов.
String get integrationBase =>
    Platform.environment['TEST_BASE_URL'] ?? 'http://localhost:3000';

/// Учётные данные администратора для интеграционных тестов.
const String kAdminUser = 'adminuser';
const String kAdminPass = 'Admin@1234';

/// Проверяет наличие JWT-переменных окружения.
bool get jwtEnvReady =>
    (Platform.environment['JWT_SECRET']?.isNotEmpty ?? false) &&
    (Platform.environment['JWT_REFRESH_SECRET']?.isNotEmpty ?? false);

const String kJwtSkipReason =
    'Нужны JWT_SECRET и JWT_REFRESH_SECRET. '
    'Запуск: JWT_SECRET=$kTestJwtSecret JWT_REFRESH_SECRET=$kTestRefreshSecret dart test';
