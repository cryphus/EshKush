import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/snackbar.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // Поменяй на адрес бэкенда
  static const String baseUrl = 'http://localhost:3000';

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_RefreshInterceptor(dio));
    dio.interceptors.add(_NetworkErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }
}

/// Добавляет Authorization header к каждому запросу
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// При 401 пытается обновить токен и повторить запрос
class _RefreshInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _RefreshInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        _isRefreshing = false;
        return handler.next(err);
      }

      // Запрос на обновление токена (без interceptors чтобы не зациклиться)
      final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      final response = await refreshDio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['access_token'] as String;
      await prefs.setString('access_token', newAccessToken);

      // Повторяем оригинальный запрос с новым токеном
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(opts);
      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      _isRefreshing = false;
      // Refresh тоже не сработал — разлогиниваем
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      return handler.next(err);
    }
  }
}

/// Глобально показывает снэкбар при сетевых ошибках (нет связи, таймаут).
/// HTTP-ошибки (4xx/5xx) пропускает — их обрабатывают экраны.
class _NetworkErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isNetwork = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
    if (isNetwork) {
      showSnack(
        err.type == DioExceptionType.connectionError
            ? 'Нет подключения к серверу'
            : 'Сервер не отвечает',
        kind: SnackKind.error,
      );
    }
    handler.next(err);
  }
}

/// Хелпер для обработки ошибок API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    String message = 'Ошибка сети';

    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Сервер не отвечает';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Нет подключения к серверу';
    }

    return ApiException(message, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
