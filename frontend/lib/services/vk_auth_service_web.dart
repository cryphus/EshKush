// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

// Реализация для веб-платформы
// Этот файл используется только на веб

class VKAuthService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> signIn() async {
    try {
      debugPrint('Начинаем VK авторизацию...');

      final module =
          globalContext.getProperty<JSObject?>('vkAuthModule'.toJS);
      if (module == null) {
        debugPrint('vkAuthModule не найден');
        throw Exception('VK SDK не найден на странице');
      }

      final jsPromise = module.callMethod<JSPromise>('login'.toJS);
      debugPrint('Получен Promise авторизации');

      final rawResult = await jsPromise.toDart;
      final dartified = rawResult.dartify();
      if (dartified is! Map) {
        throw Exception('Неожиданный ответ VK SDK: $dartified');
      }
      final authResult = Map<String, dynamic>.from(dartified);
      debugPrint('Получен результат авторизации: $authResult');

      final userInfo = authResult['user'];
      if (userInfo == null) {
        throw Exception('Не получены данные пользователя');
      }

      debugPrint('Данные пользователя VK: $userInfo');

      final response = await _sendToBackend(
        Map<String, dynamic>.from(userInfo as Map),
        authResult['email'] as String?,
      );
      debugPrint('Ответ от бэкенда: $response');

      await _saveTokens(response);

      return response;
    } catch (e, stackTrace) {
      debugPrint('Ошибка при авторизации через VK: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(Map<String, dynamic> userInfo, String? email) async {
    try {
      const apiBase = AppConfig.apiBaseUrl;
      final response = await _dio.post(
        '$apiBase/auth/vk',
        data: {
          'username': userInfo['id'].toString(),
          'email': email ?? '${userInfo['id']}@vk.com',
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        final errorMessage = response.data['error'] ?? 'Ошибка при отправке данных на бэкенд';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Ошибка при отправке данных на бэкенд: $e');
      rethrow;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', response['access_token']);
    await prefs.setString('refresh_token', response['refresh_token']);
  }
}
