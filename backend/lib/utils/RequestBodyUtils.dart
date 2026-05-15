import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'AppException.dart';

class RequestBodyUtils {
  static const String _emptyBodyMessage = 'Пустое тело запроса';
  static const String _invalidJsonMessage = 'Некорректный JSON в теле запроса';
  static const String _invalidJsonObjectMessage =
      'Ожидается JSON-объект в теле запроса';

  static Future<String> readRequiredBody(Request request) async {
    final body = await request.readAsString();
    if (body.trim().isEmpty) {
      throw const BadRequestException(_emptyBodyMessage);
    }
    return body;
  }

  static Map<String, dynamic> decodeJsonObject(String rawBody) {
    if (rawBody.trim().isEmpty) {
      throw const BadRequestException(_emptyBodyMessage);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException {
      throw const BadRequestException(_invalidJsonMessage);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const BadRequestException(_invalidJsonObjectMessage);
  }

  static Future<Map<String, dynamic>> readJsonObject(Request request) async {
    final rawBody = await readRequiredBody(request);
    return decodeJsonObject(rawBody);
  }
}
