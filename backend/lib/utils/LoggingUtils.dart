import 'dart:io';

class LoggingUtils {
  static Future<void> logRequest(String method, String path, Map<String, String> headers, String? body) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] REQUEST: $method $path');
    print('Headers: $headers');
    if (body != null) {
      print('Body: $body');
    }
  }

  static Future<void> logResponse(int statusCode, Map<String, String> headers, String body) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] RESPONSE: $statusCode');
    print('Headers: $headers');
    print('Body: $body');
  }

  static Future<void> logError(String message, dynamic error) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ERROR: $message');
    print('Error: $error');
    if (error is Exception) {
      print('Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> logInfo(String message, {Map<String, dynamic>? context}) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] INFO: $message');
    if (context != null) {
      print('Context: $context');
    }
  }

  static Future<void> logOrderOperation(String operation, int orderHistoryId, Map<String, dynamic> payload) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ORDER_HISTORY $operation: id=$orderHistoryId payload=$payload');
  }
}