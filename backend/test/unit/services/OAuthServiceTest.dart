import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OAuthService.dart';
import 'package:backend/utils/AppException.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  group('OAuthService.handleYandexCode', () {
    test('throws BadRequestException when token response JSON is invalid',
        () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('not-json', 200);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleYandexCode('bad-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws BadRequestException when token payload misses access_token',
        () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('{"token_type":"bearer"}', 200);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleYandexCode('bad-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws BadRequestException when token exchange fails', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('{"error":"invalid_grant"}', 400);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleYandexCode('bad-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws BadRequestException when profile fetch fails', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('{"access_token":"token-1"}', 200);
        }
        if (request.url.toString() ==
            'https://login.yandex.ru/info?format=json') {
          return http.Response('{"error":"forbidden"}', 403);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleYandexCode('ok-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('returns Yandex profile payload on success', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('{"access_token":"token-1"}', 200);
        }
        if (request.url.toString() ==
            'https://login.yandex.ru/info?format=json') {
          return http.Response(
            '{"id":"ya-1","login":"ivan","default_email":"ivan@example.com","first_name":"Ivan","last_name":"Petrov"}',
            200,
          );
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      final profile = await service.handleYandexCode('ok-code');

      expect(profile['id'], 'ya-1');
      expect(profile['default_email'], 'ivan@example.com');
      expect(profile['first_name'], 'Ivan');
      expect(profile['last_name'], 'Petrov');
    });

    test('throws BadRequestException when profile response JSON is invalid',
        () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://oauth.yandex.ru/token') {
          return http.Response('{"access_token":"token-1"}', 200);
        }
        if (request.url.toString() ==
            'https://login.yandex.ru/info?format=json') {
          return http.Response('not-json', 200);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleYandexCode('ok-code'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('OAuthService.handleVkCode', () {
    test('throws BadRequestException when token exchange fails', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'oauth.vk.com' &&
            request.url.path == '/access_token') {
          return http.Response('{"error":"bad_request"}', 400);
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleVkCode('bad-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws BadRequestException when VK responds with OAuth error',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'oauth.vk.com' &&
            request.url.path == '/access_token') {
          return http.Response(
            '{"error":"invalid_grant","error_description":"bad code"}',
            200,
          );
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      expect(
        () => service.handleVkCode('bad-code'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('maps VK token + users.get payload into unified user map', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'oauth.vk.com' &&
            request.url.path == '/access_token') {
          return http.Response(
            '{"access_token":"vk-token","user_id":12345,"email":"vk@example.com"}',
            200,
          );
        }
        if (request.url.host == 'api.vk.com' &&
            request.url.path == '/method/users.get') {
          return http.Response(
            '{"response":[{"id":12345,"first_name":"Pavel","last_name":"Durov"}]}',
            200,
          );
        }
        fail('Unexpected URL: ${request.url}');
      });

      final service = OAuthService(AppConfig(), client: client);
      final user = await service.handleVkCode('ok-code');

      expect(user['id'], '12345');
      expect(user['email'], 'vk@example.com');
      expect(user['first_name'], 'Pavel');
      expect(user['last_name'], 'Durov');
    });
  });
}
