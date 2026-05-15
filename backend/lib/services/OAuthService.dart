import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';
import '../utils/AppException.dart';

class OAuthService {
  final AppConfig _config;
  final http.Client _client;

  OAuthService(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  // ── Yandex ──────────────────────────────────────────────────────────────────

  String buildYandexAuthUrl({String? state}) {
    final query = <String, String>{
      'response_type': 'code',
      'client_id': _config.yandexClientId,
      'redirect_uri': _config.yandexRedirectUri,
      'force_confirm': 'yes',
    };
    if (state != null && state.isNotEmpty) {
      query['state'] = state;
    }
    return Uri.https('oauth.yandex.ru', '/authorize', query).toString();
  }

  /// Обменивает код авторизации на информацию о пользователе Яндекс.
  /// Возвращает: {id, login, default_email, first_name, last_name, real_name}
  Future<Map<String, dynamic>> handleYandexCode(String code) async {
    final tokenResponse = await _client.post(
      Uri.parse('https://oauth.yandex.ru/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _config.yandexClientId,
        'client_secret': _config.yandexClientSecret,
        'redirect_uri': _config.yandexRedirectUri,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw BadRequestException(
        'Ошибка получения токена Яндекс (HTTP ${tokenResponse.statusCode})',
      );
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final accessToken = tokenData['access_token'] as String;

    final infoResponse = await _client.get(
      Uri.parse('https://login.yandex.ru/info?format=json'),
      headers: {'Authorization': 'OAuth $accessToken'},
    );

    if (infoResponse.statusCode != 200) {
      throw BadRequestException(
        'Ошибка получения данных Яндекс (HTTP ${infoResponse.statusCode})',
      );
    }

    return jsonDecode(infoResponse.body) as Map<String, dynamic>;
  }

  // ── VK ──────────────────────────────────────────────────────────────────────

  String buildVkAuthUrl() {
    return Uri.https('oauth.vk.com', '/authorize', {
      'client_id': _config.vkClientId,
      'redirect_uri': _config.vkRedirectUri,
      'response_type': 'code',
      'scope': 'email',
      'v': '5.131',
    }).toString();
  }

  /// Обменивает код авторизации на информацию о пользователе ВКонтакте.
  /// Возвращает: {id, email, first_name, last_name}
  Future<Map<String, dynamic>> handleVkCode(String code) async {
    final tokenUri = Uri.https('oauth.vk.com', '/access_token', {
      'client_id': _config.vkClientId,
      'client_secret': _config.vkClientSecret,
      'redirect_uri': _config.vkRedirectUri,
      'code': code,
    });

    final tokenResponse = await _client.get(tokenUri);

    if (tokenResponse.statusCode != 200) {
      throw BadRequestException(
        'Ошибка получения токена ВКонтакте (HTTP ${tokenResponse.statusCode})',
      );
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;

    if (tokenData.containsKey('error')) {
      throw BadRequestException(
        'ВКонтакте OAuth ошибка: ${tokenData['error_description'] ?? tokenData['error']}',
      );
    }

    final accessToken = tokenData['access_token'] as String;
    final userId = tokenData['user_id'];
    final email = tokenData['email'] as String?;
    final userIdStr = userId.toString();

    // Получаем имя и фамилию
    final userUri = Uri.https('api.vk.com', '/method/users.get', {
      'user_ids': userIdStr,
      'access_token': accessToken,
      'v': '5.131',
      'fields': 'first_name,last_name',
    });

    final userResponse = await _client.get(userUri);
    final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
    final userInfo =
        ((userData['response'] as List?)?.first as Map<String, dynamic>?) ?? {};

    return {
      'id': userIdStr,
      'email': email,
      'first_name': userInfo['first_name'] as String? ?? '',
      'last_name': userInfo['last_name'] as String? ?? '',
    };
  }
}
