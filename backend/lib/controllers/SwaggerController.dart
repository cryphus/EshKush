import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';

class SwaggerController {
  final Router _router = Router();

  SwaggerController() {
    _setupRoutes();
  }

  void _setupRoutes() {
    _router.get('/swagger.json', _getSwaggerJson);
    _router.get('/', _getSwaggerUI);
  }

  Future<Response> _getSwaggerJson(Request request) async {
    try {
      // Пытаемся найти swagger.json в разных местах
      File? swaggerFile;
      
      // Вариант 1: относительно рабочей директории (для Docker)
      final workDirFile = File(path.join(Directory.current.path, 'lib', 'config', 'swagger.json'));
      if (await workDirFile.exists()) {
        swaggerFile = workDirFile;
      } else {
        // Вариант 2: относительно исполняемого файла (для локального запуска)
        final scriptPath = Platform.script.toFilePath();
        final projectRoot = path.dirname(path.dirname(scriptPath));
        final scriptFile = File(path.join(projectRoot, 'lib', 'config', 'swagger.json'));
        if (await scriptFile.exists()) {
          swaggerFile = scriptFile;
        } else {
          // Вариант 3: абсолютный путь в Docker
          final dockerFile = File('/app/lib/config/swagger.json');
          if (await dockerFile.exists()) {
            swaggerFile = dockerFile;
          }
        }
      }
      
      if (swaggerFile != null && await swaggerFile.exists()) {
        final spec = await swaggerFile.readAsString();
        return Response.ok(
          spec,
          headers: {'content-type': 'application/json'},
        );
      } else {
        // Если файл не найден, возвращаем базовую спецификацию
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
                    'description': 'Пользователь зарегистрирован'
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
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        requestId: RequestContextUtils.getRequestId(request),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _getSwaggerUI(Request request) async {
    const swaggerUI = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EshKush API Documentation</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.17.14/swagger-ui.css">
    <script src="https://unpkg.com/swagger-ui-dist@5.17.14/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@5.17.14/swagger-ui-standalone-preset.js"></script>
</head>
<body>
    <div id="swagger-ui"></div>
    <script>
        window.onload = function() {
            console.log('Swagger UI загружается...');
            fetch("/swagger/swagger.json")
                .then(response => response.json())
                .then(spec => {
                    SwaggerUIBundle({
                        spec: spec,
                        dom_id: '#swagger-ui',
                        deepLinking: true,
                        validatorUrl: null,
                        presets: [
                            SwaggerUIBundle.presets.apis,
                            SwaggerUIStandalonePreset
                        ],
                        layout: "BaseLayout",
                        docExpansion: "list",
                        defaultModelsExpandDepth: 3,
                        defaultModelExpandDepth: 3,
                        displayRequestDuration: true,
                        filter: true,
                        showExtensions: true,
                        showCommonExtensions: true,
                        syntaxHighlight: {
                            activate: true,
                            theme: "monokai"
                        }
                    });
                })
                .catch(error => {
                    console.error('Ошибка загрузки Swagger спецификации:', error);
                    document.getElementById('swagger-ui').innerHTML = '<div style="padding: 20px; color: red;">Ошибка загрузки спецификации API. Проверьте консоль браузера.</div>';
                });
        };
    </script>
</body>
</html>
''';

    return Response.ok(
      swaggerUI,
      headers: {'Content-Type': 'text/html'},
    );
  }

  Handler get handler => _router.call;
  Router get router => _router;
} 
