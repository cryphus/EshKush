// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: uri_does_not_exist

import 'dart:async';
import 'dart:js' as js;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Реализация для веб-платформы
// Этот файл используется только на веб

class VKAuthService {
  static const String _baseUrl = 'http://localhost:8080';
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> signIn() async {
    try {
      print('Начинаем VK авторизацию...');
      
      if (!js.context.hasProperty('vkAuthModule')) {
        print('vkAuthModule не найден');
        throw Exception('VK SDK не найден на странице');
      }

      final jsPromise = js.context['vkAuthModule'].callMethod('login');
      print('Получен Promise авторизации');

      final completer = Completer<Map<String, dynamic>>();
      
      final successCallback = js_util.allowInterop((result) {
        print('Promise resolved: $result');
        completer.complete(js_util.dartify(result as Object) as Map<String, dynamic>);
      });

      final errorCallback = js_util.allowInterop((error) {
        print('Promise rejected: $error');
        completer.completeError(error.toString());
      });

      jsPromise.callMethod('then', [successCallback]).callMethod('catch', [errorCallback]);

      final authResult = await completer.future;
      print('Получен результат авторизации: $authResult');

      final userInfo = authResult['user'];
      if (userInfo == null) {
        throw Exception('Не получены данные пользователя');
      }

      print('Данные пользователя VK: $userInfo');

      final response = await _sendToBackend(userInfo, authResult['email']);
      print('Ответ от бэкенда: $response');

      await _saveTokens(response);

      return response;
    } catch (e, stackTrace) {
      print('Ошибка при авторизации через VK: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(Map<String, dynamic> userInfo, String? email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/vk',
        data: {
          'username': userInfo['id'].toString(),
          'password': 'vk_${userInfo['id']}',
          'email': email ?? '${userInfo['id']}@vk.com',
          'displayName': '${userInfo['first_name']} ${userInfo['last_name']}',
          'phone': '',
          'role': 'user',
          'sumCO2': 0,
          'money': 0,
          'favoriteIds': [],
          'purchases': [],
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
      print('Ошибка при отправке данных на бэкенд: $e');
      rethrow;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', response['access_token']);
    await prefs.setString('refresh_token', response['refresh_token']);
  }
}

