import 'package:shelf/shelf.dart';

/// CORS middleware: allowlist origins, restricted methods/headers, preflight handling.
/// Uses [allowedOrigins] from config (e.g. prod, staging, dev). Does not send
/// Access-Control-Allow-Origin for disallowed origins.
class CorsMiddleware {
  static const String _allowMethods = 'GET, POST, PUT, DELETE, OPTIONS';
  static const String _allowHeaders = 'Origin, Content-Type, Accept, Authorization';

  final List<String> allowedOrigins;
  final bool devMode;

  CorsMiddleware({required this.allowedOrigins, this.devMode = false});

  bool _isAllowed(String? origin) {
    if (origin == null || origin.isEmpty) return false;
    if (allowedOrigins.any((o) => o == origin)) return true;
    if (devMode) {
      final uri = Uri.tryParse(origin);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        return true;
      }
    }
    return false;
  }

  Middleware call() {
    return (Handler innerHandler) {
      return (Request request) async {
        final origin = request.headers['origin'];
        final allowed = _isAllowed(origin);

        if (request.method == 'OPTIONS') {
          final headers = <String, String>{
            'Access-Control-Allow-Methods': _allowMethods,
            'Access-Control-Allow-Headers': _allowHeaders,
            'Access-Control-Max-Age': '86400',
          };
          if (allowed) {
            headers['Access-Control-Allow-Origin'] = origin!;
          }
          return Response(204, headers: headers);
        }

        final response = await innerHandler(request);
        if (!allowed) return response;

        final existing = response.headers;
        return response.change(headers: {
          ...existing,
          'Access-Control-Allow-Origin': origin!,
          'Access-Control-Allow-Methods': _allowMethods,
          'Access-Control-Allow-Headers': _allowHeaders,
        });
      };
    };
  }
}
