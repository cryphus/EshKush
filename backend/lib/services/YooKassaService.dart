import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/AppConfig.dart';
import '../utils/AppException.dart';

/// Тонкая обёртка над REST API YooKassa (https://yookassa.ru/developers/api).
///
/// Делает только платёжные операции: создание платежа, получение статуса,
/// возврат. Маппинг в доменные сущности (PaymentTransactions) лежит в
/// [PaymentGatewayService].
class YooKassaService {
  static const Duration _requestTimeout = Duration(seconds: 15);
  final AppConfig _config;
  final http.Client _httpClient;
  final Uuid _uuid;

  YooKassaService(
    this._config, {
    http.Client? httpClient,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid();

  /// Создаёт платёж у YooKassa и возвращает JSON-ответ.
  ///
  /// Ключевые поля ответа: `id` (провайдерский transaction id),
  /// `status`, `confirmation.confirmation_url` (ссылка на оплату).
  Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String description,
    required int orderId,
    String currency = 'RUB',
    String? returnUrl,
    bool capture = true,
    Map<String, String>? extraMetadata,
  }) async {
    _assertConfigured();

    final metadata = <String, String>{
      'order_id': orderId.toString(),
      if (extraMetadata != null) ...extraMetadata,
    };

    final body = <String, dynamic>{
      'amount': {
        'value': amount.toStringAsFixed(2),
        'currency': currency,
      },
      'capture': capture,
      'description': description,
      'metadata': metadata,
      'confirmation': {
        'type': 'redirect',
        'return_url': returnUrl ?? _config.yookassaReturnUrl,
      },
    };

    return _post('/payments', body, idempotenceKey: _uuid.v4());
  }

  /// Получить текущий статус платежа у YooKassa.
  Future<Map<String, dynamic>> getPayment(String providerTransactionId) async {
    _assertConfigured();
    final uri = Uri.parse(
        '${_config.yookassaApiBaseUrl}/payments/$providerTransactionId');
    http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: _authHeaders())
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw YooKassaException(
        statusCode: 504,
        message: 'YooKassa timeout while fetching payment status',
      );
    }
    return _decode(response);
  }

  /// Создать возврат по ранее проведённому платежу.
  Future<Map<String, dynamic>> refundPayment({
    required String providerTransactionId,
    required double amount,
    String currency = 'RUB',
    String? description,
  }) async {
    _assertConfigured();

    final body = <String, dynamic>{
      'payment_id': providerTransactionId,
      'amount': {
        'value': amount.toStringAsFixed(2),
        'currency': currency,
      },
      if (description != null) 'description': description,
    };

    return _post('/refunds', body, idempotenceKey: _uuid.v4());
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    required String idempotenceKey,
  }) async {
    final uri = Uri.parse('${_config.yookassaApiBaseUrl}$path');
    http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              ..._authHeaders(),
              'Content-Type': 'application/json',
              'Idempotence-Key': idempotenceKey,
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw YooKassaException(
        statusCode: 504,
        message: 'YooKassa timeout while calling $path',
      );
    }
    return _decode(response);
  }

  Map<String, String> _authHeaders() {
    final credentials = base64Encode(
        utf8.encode('${_config.yookassaShopId}:${_config.yookassaSecretKey}'));
    return {'Authorization': 'Basic $credentials'};
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw YooKassaException(
        statusCode: response.statusCode,
        message: 'Некорректный ответ от YooKassa: ${response.body}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    throw YooKassaException(
      statusCode: response.statusCode,
      message: payload['description']?.toString() ??
          payload['error']?.toString() ??
          'Ошибка YooKassa (${response.statusCode})',
      code: payload['code']?.toString(),
      rawPayload: payload,
    );
  }

  void _assertConfigured() {
    if (!_config.isYookassaConfigured) {
      throw const InternalServerException(
        'YooKassa не сконфигурирована: задайте YOOKASSA_SHOP_ID и YOOKASSA_SECRET_KEY',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class YooKassaException extends AppException {
  final int statusCode;
  final String? code;
  final Map<String, dynamic>? rawPayload;

  YooKassaException({
    required this.statusCode,
    required String message,
    this.code,
    this.rawPayload,
  }) : super(message);

  @override
  String toString() =>
      'YooKassaException($statusCode${code != null ? ", $code" : ""}): $message';
}
