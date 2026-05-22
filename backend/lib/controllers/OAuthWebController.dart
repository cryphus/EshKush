import 'dart:convert';
import 'package:crypto/crypto.dart';

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
  static const int _oauthStateMaxAgeSeconds = 600;
  static final RegExp _oauthStateRegex = RegExp(r'^[A-Za-z0-9_-]{32,128}$');
  static final RegExp _oauthCodeRegex = RegExp(r'^[A-Za-z0-9._~-]{8,512}$');
  static final RegExp _oauthErrorRegex = RegExp(r'^[a-z0-9_]{1,64}$');

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
    final signedStateCookieValue = _buildSignedOAuthStateCookieValue(
      provider: 'yandex',
      state: state,
    );
    return Response.found(
      _oauthService.buildYandexAuthUrl(state: state),
      headers: {
        'set-cookie': _buildOAuthStateCookie(
          provider: 'yandex',
          state: signedStateCookieValue,
          secure: _config.isProduction,
        ),
      },
    );
  }

  Future<Response> _yandexCallback(Request request) async {
    try {
      final code = request.url.queryParameters['code'];
      final error = _normalizeOAuthError(request.url.queryParameters['error'],
          fallback: null);
      final actualState = request.url.queryParameters['state'];
      final expectedState = _readAndValidateOAuthStateCookie(
        request: request,
        provider: 'yandex',
      );

      if (actualState == null ||
          !_oauthStateRegex.hasMatch(actualState) ||
          expectedState == null ||
          !_constantTimeEquals(actualState, expectedState)) {
        return _clearOAuthStateCookie(
          _redirectWithError('invalid_state'),
          provider: 'yandex',
        );
      }

      if (error != null || code == null || !_oauthCodeRegex.hasMatch(code)) {
        return _clearOAuthStateCookie(
          _redirectWithError(error ?? 'no_code'),
          provider: 'yandex',
        );
      }

      final yandexUser = await _oauthService.handleYandexCode(code);
      final yandexId = yandexUser['id']?.toString() ?? '';
      final rawEmail = yandexUser['default_email'] as String?;
      final email = rawEmail != null && rawEmail.trim().isNotEmpty
          ? rawEmail.trim()
          : null;

      if (yandexId.isEmpty) {
        return _clearOAuthStateCookie(
          _redirectWithError('no_id'),
          provider: 'yandex',
        );
      }

      var user = await _userRepository.findByYandexId(yandexId);

      if (user == null) {
        if (email == null || email.isEmpty) {
          return _clearOAuthStateCookie(
            _redirectWithError('no_email'),
            provider: 'yandex',
          );
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
      return _clearOAuthStateCookie(
        _redirectWithTokens(bundle),
        provider: 'yandex',
      );
    } catch (e) {
      await LoggingUtils.logError('Yandex OAuth callback error', e);
      return _clearOAuthStateCookie(
        _redirectWithError('oauth_failed'),
        provider: 'yandex',
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
      final error = _normalizeOAuthError(request.url.queryParameters['error'],
          fallback: null);

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
    final base = Uri.parse(_config.frontendUrl);
    final redirectUrl = base
        .replace(
          path: base.path.isEmpty ? '/' : base.path,
          fragment: fragment,
        )
        .toString();
    return Response.found(
      redirectUrl,
      headers: const {
        'Cache-Control': 'no-store',
        'Pragma': 'no-cache',
      },
    );
  }

  Response _redirectWithError(String error) {
    final base = Uri.parse(_config.frontendUrl);
    final redirectUrl = base.replace(
      path: base.path.isEmpty ? '/' : base.path,
      queryParameters: {
        'oauth_error': _normalizeOAuthError(error) ?? 'oauth_failed'
      },
    ).toString();
    return Response.found(
      redirectUrl,
      headers: const {
        'Cache-Control': 'no-store',
        'Pragma': 'no-cache',
      },
    );
  }

  String _oauthStateCookieName(String provider) => 'oauth_state_$provider';

  String _buildOAuthStateCookie({
    required String provider,
    required String state,
    required bool secure,
    bool clear = false,
  }) {
    final encodedState = Uri.encodeComponent(state);
    final maxAge = clear ? 0 : _oauthStateMaxAgeSeconds;
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

  String? _normalizeOAuthError(String? raw,
      {String? fallback = 'oauth_failed'}) {
    final normalized = raw?.toLowerCase().trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    if (_oauthErrorRegex.hasMatch(normalized)) {
      return normalized;
    }
    return fallback;
  }

  Response _clearOAuthStateCookie(Response response,
      {required String provider}) {
    return _attachCookie(
      response,
      _buildOAuthStateCookie(
        provider: provider,
        state: '',
        secure: _config.isProduction,
        clear: true,
      ),
    );
  }

  String _buildSignedOAuthStateCookieValue({
    required String provider,
    required String state,
  }) {
    final issuedAt = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final signature = _signOAuthState(
      provider: provider,
      state: state,
      issuedAt: issuedAt,
    );
    final payload = '$state|$issuedAt|$signature';
    return base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
  }

  String? _readAndValidateOAuthStateCookie({
    required Request request,
    required String provider,
  }) {
    final raw = _readCookieValue(request, _oauthStateCookieName(provider));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(raw)));
      final parts = decoded.split('|');
      if (parts.length != 3) return null;

      final state = parts[0];
      final issuedAt = int.tryParse(parts[1]);
      final signature = parts[2];
      if (issuedAt == null || !_oauthStateRegex.hasMatch(state)) return null;

      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      if (issuedAt > now + 5) return null;
      if (now - issuedAt > _oauthStateMaxAgeSeconds) return null;

      final expectedSignature = _signOAuthState(
        provider: provider,
        state: state,
        issuedAt: issuedAt,
      );

      if (!_constantTimeEquals(signature, expectedSignature)) return null;
      return state;
    } catch (_) {
      return null;
    }
  }

  String _signOAuthState({
    required String provider,
    required String state,
    required int issuedAt,
  }) {
    final payload = '$provider|$state|$issuedAt';
    final digest = Hmac(sha256, utf8.encode(_config.jwtSecret))
        .convert(utf8.encode(payload))
        .bytes;
    return base64Url.encode(digest).replaceAll('=', '');
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
