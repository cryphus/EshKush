import 'package:shelf/shelf.dart';

/// CORS middleware: allowlist origins, restricted methods/headers, preflight handling.
/// Uses [allowedOrigins] from config (e.g. prod, staging, dev). Does not send
/// Access-Control-Allow-Origin for disallowed origins.
class CorsMiddleware {
  static const String _allowMethods = 'GET, POST, PUT, DELETE, OPTIONS';
  static const String _allowHeaders = 'Origin, Content-Type, Accept, Authorization';

  final List<String> allowedOrigins;

  CorsMiddleware({required this.allowedOrigins});

  Middleware call() {
    return (Handler innerHandler) {
      return (Request request) async {
        final origin = request.headers['origin'];
        final allowed = origin != null &&
            origin.isNotEmpty &&
            allowedOrigins.any((o) => o == origin);

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
