import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OAuthService.dart';

void main() {
  setUpAll(() {
    AppConfig.initForTesting();
  });

  group('OAuthService.buildYandexAuthUrl', () {
    test('adds state query parameter when provided', () {
      final service = OAuthService(AppConfig());
      final url = service.buildYandexAuthUrl(state: 'state-123');
      final uri = Uri.parse(url);

      expect(uri.host, 'oauth.yandex.ru');
      expect(uri.path, '/authorize');
      expect(uri.queryParameters['state'], 'state-123');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['force_confirm'], 'yes');
    });

    test('does not include state when omitted', () {
      final service = OAuthService(AppConfig());
      final url = service.buildYandexAuthUrl();
      final uri = Uri.parse(url);

      expect(uri.queryParameters.containsKey('state'), isFalse);
    });
  });
}
