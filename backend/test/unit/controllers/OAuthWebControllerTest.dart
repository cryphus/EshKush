import 'dart:convert';

import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/OAuthWebController.dart';
import 'package:backend/services/OAuthService.dart';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

import 'OAuthControllerTest.mocks.dart';

class _FakeOAuthService extends OAuthService {
  _FakeOAuthService(super.config);

  Map<String, dynamic> Function(String code)? yandexHandler;
  Map<String, dynamic> Function(String code)? vkHandler;

  @override
  Future<Map<String, dynamic>> handleYandexCode(String code) async {
    final handler = yandexHandler;
    if (handler == null) {
      throw StateError('yandexHandler is not configured in test');
    }
    return handler(code);
  }

  @override
  Future<Map<String, dynamic>> handleVkCode(String code) async {
    final handler = vkHandler;
    if (handler == null) {
      throw StateError('vkHandler is not configured in test');
    }
    return handler(code);
  }
}

String _buildSignedStateCookieValue(
  AppConfig config,
  String provider,
  String state, {
  int? issuedAt,
}) {
  final iat = issuedAt ?? DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = '$provider|$state|$iat';
  final digest = Hmac(sha256, utf8.encode(config.jwtSecret))
      .convert(utf8.encode(payload))
      .bytes;
  final signature = base64Url.encode(digest).replaceAll('=', '');
  final cookiePayload = '$state|$iat|$signature';
  return base64Url.encode(utf8.encode(cookiePayload)).replaceAll('=', '');
}

String _cookieHeaderFromSignedValue(String provider, String value) {
  return 'oauth_state_$provider=${Uri.encodeComponent(value)}';
}

void main() {
  late AppConfig config;
  late _FakeOAuthService oauthService;
  late MockUserRepository userRepository;
  late MockUserSessionRepository userSessionRepository;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    config = AppConfig();
    oauthService = _FakeOAuthService(config);
    userRepository = MockUserRepository();
    userSessionRepository = MockUserSessionRepository();

    handler = OAuthWebController(
      config,
      oauthService,
      userRepository,
      userSessionRepository,
    ).router.call;
  });

  test('GET /auth/yandex returns 503 when Yandex OAuth is not configured',
      () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/auth/yandex')),
    );

    expect(response.statusCode, 503);
  });

  test(
      'GET /auth/yandex/callback redirects with invalid_state on state mismatch',
      () async {
    const expectedState = 'a2345678901234567890123456789012345678901234567';
    const actualState = 'b2345678901234567890123456789012345678901234567';
    final signedCookie =
        _buildSignedStateCookieValue(config, 'yandex', expectedState);

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/yandex/callback?state=$actualState'),
        headers: {
          'cookie': _cookieHeaderFromSignedValue('yandex', signedCookie)
        },
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=invalid_state',
    );
  });

  test(
      'GET /auth/yandex/callback redirects with no_code when state is valid but code missing',
      () async {
    const state = 'a2345678901234567890123456789012345678901234567';
    final signedCookie = _buildSignedStateCookieValue(config, 'yandex', state);

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/yandex/callback?state=$state'),
        headers: {
          'cookie': _cookieHeaderFromSignedValue('yandex', signedCookie)
        },
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=no_code',
    );
  });

  test(
      'GET /auth/yandex/callback redirects with invalid_state when signed cookie is expired',
      () async {
    const state = 'a2345678901234567890123456789012345678901234567';
    final expiredIssuedAt =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - 3600;
    final signedCookie = _buildSignedStateCookieValue(
      config,
      'yandex',
      state,
      issuedAt: expiredIssuedAt,
    );

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/yandex/callback?state=$state'),
        headers: {
          'cookie': _cookieHeaderFromSignedValue('yandex', signedCookie)
        },
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=invalid_state',
    );
  });

  test('GET /auth/vk returns 503 when VK OAuth is not configured', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/auth/vk')),
    );

    expect(response.statusCode, 503);
  });

  test('GET /auth/vk/callback redirects with provider error', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/vk/callback?error=access_denied'),
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=access_denied',
    );
  });

  test(
      'GET /auth/yandex/callback redirects with no_email when provider has no email',
      () async {
    const state = 'a2345678901234567890123456789012345678901234567';
    final signedCookie = _buildSignedStateCookieValue(config, 'yandex', state);

    oauthService.yandexHandler = (_) => {
          'id': 'ya-123',
          'login': 'test_ya',
          'default_email': '',
        };
    when(userRepository.findByYandexId('ya-123')).thenAnswer((_) async => null);

    final response = await handler(
      Request(
        'GET',
        Uri.parse(
            'http://localhost/auth/yandex/callback?state=$state&code=code-12345'),
        headers: {
          'cookie': _cookieHeaderFromSignedValue('yandex', signedCookie)
        },
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=no_email',
    );
  });

  test(
      'GET /auth/vk/callback redirects with no_email when provider has no email',
      () async {
    oauthService.vkHandler = (_) => {
          'id': 'vk-321',
          'email': '',
          'first_name': 'Test',
          'last_name': 'User',
        };
    when(userRepository.findByVkId('vk-321')).thenAnswer((_) async => null);

    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/vk/callback?code=code-1'),
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=no_email',
    );
  });

  test(
      'GET /auth/yandex/callback redirects with oauth_failed on provider failure',
      () async {
    const state = 'a2345678901234567890123456789012345678901234567';
    final signedCookie = _buildSignedStateCookieValue(config, 'yandex', state);

    oauthService.yandexHandler = (_) => throw Exception('provider boom');

    final response = await handler(
      Request(
        'GET',
        Uri.parse(
            'http://localhost/auth/yandex/callback?state=$state&code=code-12345'),
        headers: {
          'cookie': _cookieHeaderFromSignedValue('yandex', signedCookie)
        },
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=oauth_failed',
    );
  });
}
