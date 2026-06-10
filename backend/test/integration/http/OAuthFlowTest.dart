import 'dart:io';

import 'package:test/test.dart';

import '../../helpers/TestEnv.dart';

Future<(int, Map<String, String>)> httpGet(
  String path, {
  Map<String, String>? headers,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$integrationBase$path');
    final rq = await client.getUrl(uri);
    rq.followRedirects = false;
    headers?.forEach(rq.headers.set);
    final rs = await rq.close();
    await rs.drain();
    final responseHeaders = <String, String>{};
    rs.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });
    return (rs.statusCode, responseHeaders);
  } finally {
    client.close(force: true);
  }
}

Future<bool> _serverAvailable() async {
  final ready = await (_serverReadyFuture ??= waitForIntegrationServer());
  if (!ready) {
    throw StateError('Integration server is unavailable: $integrationBase');
  }
  return true;
}

Future<bool>? _serverReadyFuture;

void main() {
  group('OAuth callbacks', () {
    test('GET /auth/yandex/callback without cookie state -> invalid_state',
        () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен: $integrationBase');
        return;
      }

      final (code, headers) =
          await httpGet('/auth/yandex/callback?state=abc&code=test');
      expect(code, 302);
      expect(
        headers['location'],
        'http://localhost:3000/?oauth_error=invalid_state',
      );
    });

    test('GET /auth/yandex/callback with state mismatch -> invalid_state',
        () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен: $integrationBase');
        return;
      }

      final (code, headers) = await httpGet(
        '/auth/yandex/callback?state=actual&code=test',
        headers: {'cookie': 'oauth_state_yandex=expected'},
      );
      expect(code, 302);
      expect(
        headers['location'],
        'http://localhost:3000/?oauth_error=invalid_state',
      );
    });

    test('GET /auth/vk/callback with provider error -> oauth_error redirect',
        () async {
      if (!await _serverAvailable()) {
        markTestSkipped('Сервер недоступен: $integrationBase');
        return;
      }

      final (code, headers) =
          await httpGet('/auth/vk/callback?error=access_denied');
      expect(code, 302);
      expect(
        headers['location'],
        'http://localhost:3000/?oauth_error=access_denied',
      );
    });
  });
}
