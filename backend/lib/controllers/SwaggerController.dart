import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SwaggerController {
  final Router _router = Router();

  SwaggerController() {
    _setupRoutes();
  }

  void _setupRoutes() {
    _router.get('/swagger.json', _getSwaggerJson);
    _router.get('/swagger-ui', _getSwaggerUi);
  }

  Future<Response> _getSwaggerJson(Request request) async {
    // TODO: Реализовать генерацию swagger.json на основе ваших эндпоинтов
    final swaggerJson = {
      'openapi': '3.0.0',
      'info': {
        'title': 'EshKush API',
        'version': '1.0.0',
        'description': 'API документация для EshKush'
      },
      'paths': {
        '/auth/google': {
          'post': {
            'summary': 'Аутентификация через Google',
            'responses': {
              '200': {
                'description': 'Успешная аутентификация'
              }
            }
          }
        },
        '/auth/register': {
          'post': {
            'summary': 'Регистрация пользователя',
            'responses': {
              '200': {
                'description': 'Успешная регистрация'
              }
            }
          }
        }
      }
    };

    return Response.ok(
      jsonEncode(swaggerJson),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getSwaggerUi(Request request) async {
    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Swagger UI</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4/swagger-ui.css">
    <script src="https://unpkg.com/swagger-ui-dist@4/swagger-ui-bundle.js"></script>
</head>
<body>
    <div id="swagger-ui"></div>
    <script>
        window.onload = function() {
            SwaggerUIBundle({
                url: "/swagger.json",
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                ],
            });
        }
    </script>
</body>
</html>
''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html'},
    );
  }

  Handler get handler => _router.call;
} 