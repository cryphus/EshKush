import 'dart:io';
import 'dart:async';

/// Константы тестовой среды.
/// Тесты JWT запускать с:
///   JWT_SECRET=testsecretforjwttestingatleast32chars \
///   JWT_REFRESH_SECRET=testrefreshsecretforjwttests32chars \
///   dart test

const String kTestJwtSecret = 'testsecretforjwttestingatleast32chars';
const String kTestRefreshSecret = 'testrefreshsecretforjwttests32chars__';

/// Базовый URL для интеграционных тестов.
String get integrationBase =>
    Platform.environment['TEST_BASE_URL'] ?? 'http://localhost:3000';

/// Учётные данные администратора для интеграционных тестов.
const String kAdminUser = 'adminuser';
const String kAdminPass = 'Admin@1234';

/// Ожидает, пока интеграционный backend станет доступен по HTTP.
/// Возвращает true, если сервер отвечает на GET / любым кодом < 500 в течение timeout.
Future<bool> waitForIntegrationServer({
  Duration timeout = const Duration(seconds: 120),
  Duration pollInterval = const Duration(milliseconds: 700),
}) async {
  final deadline = DateTime.now().add(timeout);
  final probeUri = Uri.parse('$integrationBase/');

  while (DateTime.now().isBefore(deadline)) {
    final client = HttpClient();
    try {
      final rq =
          await client.getUrl(probeUri).timeout(const Duration(seconds: 2));
      rq.headers.set('Accept', 'application/json');
      final rs = await rq.close().timeout(const Duration(seconds: 2));
      await rs.drain();
      if (rs.statusCode >= 200 && rs.statusCode < 500) {
        return true;
      }
    } catch (_) {
      // Ждём следующую попытку.
    } finally {
      client.close(force: true);
    }

    await Future<void>.delayed(pollInterval);
  }

  return false;
}

/// Проверяет наличие JWT-переменных окружения.
bool get jwtEnvReady =>
    (Platform.environment['JWT_SECRET']?.isNotEmpty ?? false) &&
    (Platform.environment['JWT_REFRESH_SECRET']?.isNotEmpty ?? false);

const String kJwtSkipReason = 'Нужны JWT_SECRET и JWT_REFRESH_SECRET. '
    'Запуск: JWT_SECRET=$kTestJwtSecret JWT_REFRESH_SECRET=$kTestRefreshSecret dart test';
