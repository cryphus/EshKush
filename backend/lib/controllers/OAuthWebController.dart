import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/AppConfig.dart';
import '../middleware/SecurityMiddleware.dart';
import '../model/entities/UserSessions.dart';
import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../services/OAuthService.dart';
import '../utils/AuthUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/SecurityUtils.dart';

class OAuthWebController {
  final AppConfig _config;
  final OAuthService _oauthService;
  final UserRepository _userRepository;
  final UserSessionRepository _userSessionRepository;

  OAuthWebController(
    this._config,
    this._oauthService,
    this._userRepository,
    this._userSessionRepository,
  );

  Router get router {
    final router = Router();

    router.get('/auth/yandex', _yandexStart);
    router.get('/auth/yandex/callback', _yandexCallback);
    router.get('/auth/vk', _vkStart);
    router.get('/auth/vk/callback', _vkCallback);

    return router;
  }

  Response _yandexStart(Request request) {
    if (!_config.isYandexConfigured) {
      return Response(
        503,
        body: jsonEncode({'error': 'Яндекс OAuth не настроен'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final state = SecurityUtils.generateSecureRandomString(48);
    return Response.found(
      _oauthService.buildYandexAuthUrl(state: state),
      headers: {
        'set-cookie': _buildOAuthStateCookie(
          provider: 'yandex',
          state: state,
          secure: _config.isProduction,
        ),
      },
    );
  }

  Future<Response> _yandexCallback(Request request) async {
    try {
      final code = request.url.queryParameters['code'];
      final error = request.url.queryParameters['error'];
      final actualState = request.url.queryParameters['state'];
      final expectedState =
          _readCookieValue(request, _oauthStateCookieName('yandex'));

      if (actualState == null ||
          expectedState == null ||
          actualState != expectedState) {
        return _attachCookie(
          _redirectWithError('invalid_state'),
          _buildOAuthStateCookie(
            provider: 'yandex',
            state: '',
            secure: _config.isProduction,
            clear: true,
          ),
        );
      }

      if (error != null || code == null) {
        return _attachCookie(
          _redirectWithError(error ?? 'no_code'),
          _buildOAuthStateCookie(
            provider: 'yandex',
            state: '',
            secure: _config.isProduction,
            clear: true,
          ),
        );
      }

      final yandexUser = await _oauthService.handleYandexCode(code);
      final yandexId = yandexUser['id']?.toString() ?? '';
      final rawEmail = yandexUser['default_email'] as String?;
      final email = rawEmail != null && rawEmail.trim().isNotEmpty
          ? rawEmail.trim()
          : null;

      if (yandexId.isEmpty) {
        return _attachCookie(
          _redirectWithError('no_id'),
          _buildOAuthStateCookie(
            provider: 'yandex',
            state: '',
            secure: _config.isProduction,
            clear: true,
          ),
        );
      }

      var user = await _userRepository.findByYandexId(yandexId);

      if (user == null) {
        if (email == null || email.isEmpty) {
          return _redirectWithError('no_email');
        }

        if (email.isNotEmpty) {
          try {
            user = await _userRepository.findByEmail(email);
            if (user != null) {
              await _userRepository.linkYandexId(user.id, yandexId);
            }
          } catch (_) {}
        }

        if (user == null) {
          final login = (yandexUser['login'] as String?) ?? 'ya_$yandexId';
          user = await _userRepository.createOAuthUser(
            baseUsername: login,
            email: email,
            yandexId: yandexId,
            firstName: yandexUser['first_name'] as String?,
            lastName: yandexUser['last_name'] as String?,
          );
        }
      }

      final bundle =
          await _createSessionBundle(request, user.id, user.role.name);
      return _attachCookie(
        _redirectWithTokens(bundle),
        _buildOAuthStateCookie(
          provider: 'yandex',
          state: '',
          secure: _config.isProduction,
          clear: true,
        ),
      );
    } catch (e) {
      await LoggingUtils.logError('Yandex OAuth callback error', e);
      return _attachCookie(
        _redirectWithError('oauth_failed'),
        _buildOAuthStateCookie(
          provider: 'yandex',
          state: '',
          secure: _config.isProduction,
          clear: true,
        ),
      );
    }
  }

  Response _vkStart(Request request) {
    if (!_config.isVkConfigured) {
      return Response(
        503,
        body: jsonEncode({'error': 'ВКонтакте OAuth не настроен'}),
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.found(_oauthService.buildVkAuthUrl());
  }

  Future<Response> _vkCallback(Request request) async {
    try {
      final code = request.url.queryParameters['code'];
      final error = request.url.queryParameters['error'];

      if (error != null || code == null) {
        return _redirectWithError(error ?? 'no_code');
      }

      final vkUser = await _oauthService.handleVkCode(code);
      final vkId = vkUser['id']?.toString() ?? '';

      if (vkId.isEmpty) {
        return _redirectWithError('no_id');
      }

      var user = await _userRepository.findByVkId(vkId);

      if (user == null) {
        final rawEmail = vkUser['email'] as String?;
        final email = rawEmail != null && rawEmail.trim().isNotEmpty
            ? rawEmail.trim()
            : null;
        if (email == null || email.isEmpty) {
          return _redirectWithError('no_email');
        }

        if (email.isNotEmpty) {
          try {
            user = await _userRepository.findByEmail(email);
            if (user != null) {
              await _userRepository.linkVkId(user.id, vkId);
            }
          } catch (_) {}
        }

        if (user == null) {
          final firstName = vkUser['first_name'] as String? ?? '';
          final lastName = vkUser['last_name'] as String? ?? '';
          final baseUsername = firstName.isNotEmpty
              ? '${firstName.toLowerCase()}_vk'
              : 'vk_$vkId';

          user = await _userRepository.createOAuthUser(
            baseUsername: baseUsername,
            email: email,
            vkId: vkId,
            firstName: firstName.isNotEmpty ? firstName : null,
            lastName: lastName.isNotEmpty ? lastName : null,
          );
        }
      }

      final bundle =
          await _createSessionBundle(request, user.id, user.role.name);
      return _redirectWithTokens(bundle);
    } catch (e) {
      await LoggingUtils.logError('VK OAuth callback error', e);
      return _redirectWithError('oauth_failed');
    }
  }

  Future<Map<String, Object>> _createSessionBundle(
    Request request,
    int userId,
    String roleName,
  ) async {
    final bundle =
        AuthUtils.generateTokenBundle(userId, roleName.toLowerCase());
    final refreshJti = bundle['refresh_jti'] as String;
    final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

    await _userSessionRepository.create(
      UserSessions(
        id: 0,
        userId: userId,
        createdAt: DateTime.now(),
        expiresAt: refreshExpiresAt,
        lastActive: DateTime.now(),
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: SecurityMiddleware.extractClientIp(request),
        token: bundle['access_token'] as String,
        refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
      ),
    );

    return {
      'access_token': bundle['access_token'] as String,
      'refresh_token': bundle['refresh_token'] as String,
    };
  }

  Response _redirectWithTokens(Map<String, Object> tokens) {
    final fragmentParams = {
      'access_token': tokens['access_token'] as String,
      'refresh_token': tokens['refresh_token'] as String,
    };

    final fragment = Uri(queryParameters: fragmentParams).query;
    final redirectUrl = Uri.parse(_config.frontendUrl)
        .replace(queryParameters: const {}, fragment: fragment).toString();
    return Response.found(redirectUrl);
  }

  Response _redirectWithError(String error) {
    final base = Uri.parse(_config.frontendUrl);
    final redirectUrl = base.replace(
      path: base.path.isEmpty ? '/' : base.path,
      queryParameters: {'oauth_error': error},
    ).toString();
    return Response.found(redirectUrl);
  }

  String _oauthStateCookieName(String provider) => 'oauth_state_$provider';

  String _buildOAuthStateCookie({
    required String provider,
    required String state,
    required bool secure,
    bool clear = false,
  }) {
    final encodedState = Uri.encodeComponent(state);
    final maxAge = clear ? 0 : 600;
    final secureFlag = secure ? '; Secure' : '';
    return '${_oauthStateCookieName(provider)}=$encodedState; Max-Age=$maxAge; Path=/auth/$provider/callback; HttpOnly; SameSite=Lax$secureFlag';
  }

  Response _attachCookie(Response response, String cookie) {
    return response.change(
      headers: {
        ...response.headers,
        'set-cookie': cookie,
      },
    );
  }

  String? _readCookieValue(Request request, String cookieName) {
    final cookieHeader = request.headers['cookie'];
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }

    for (final rawPart in cookieHeader.split(';')) {
      final part = rawPart.trim();
      final equalsIndex = part.indexOf('=');
      if (equalsIndex <= 0) continue;
      final name = part.substring(0, equalsIndex).trim();
      if (name != cookieName) continue;
      final value = part.substring(equalsIndex + 1).trim();
      return Uri.decodeComponent(value);
    }

    return null;
  }
}
