import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/OAuthWebController.dart';
import 'package:backend/services/OAuthService.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'OAuthControllerTest.mocks.dart';

void main() {
  late AppConfig config;
  late OAuthService oauthService;
  late MockUserRepository userRepository;
  late MockUserSessionRepository userSessionRepository;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    config = AppConfig();
    oauthService = OAuthService(config);
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
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/yandex/callback?state=actual'),
        headers: {'cookie': 'oauth_state_yandex=expected'},
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
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/auth/yandex/callback?state=ok'),
        headers: {'cookie': 'oauth_state_yandex=ok'},
      ),
    );

    expect(response.statusCode, 302);
    expect(
      response.headers['location'],
      'http://localhost:3000/?oauth_error=no_code',
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
}
