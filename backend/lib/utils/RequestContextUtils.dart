import 'package:shelf/shelf.dart';

class RequestContextUtils {
  static String? getRequestId(Request request) {
    final value = request.context['requestId'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}


