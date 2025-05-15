import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class SwaggerController {
  Router get router {
    final router = Router();

    router.get('/', (Request request) {
      print('=== Получен запрос на / ===');
      return _getSwaggerUI(request);
    });

    return router;
  }

  Future<Response> _getSwaggerUI(Request request) async {
    print('=== Отправляем Swagger UI ===');
    
    // Читаем спецификацию
    final currentDir = Directory.current.path;
    final swaggerFile = File(path.join(currentDir, 'lib', 'config', 'swagger.json'));
    final spec = await swaggerFile.readAsString();
    
    const swaggerUI = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EshKush API Documentation</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.1.3/swagger-ui.css">
    <script src="https://unpkg.com/swagger-ui-dist@4.1.3/swagger-ui-bundle.js"></script>
</head>
<body>
    <div id="swagger-ui"></div>
    <script>
        window.onload = function() {
            console.log('Swagger UI загружается...');
            const spec = SPEC_PLACEHOLDER;
            SwaggerUIBundle({
                spec: spec,
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
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
        };
    </script>
</body>
</html>
''';

    // Заменяем плейсхолдер на реальную спецификацию
    final html = swaggerUI.replaceFirst('SPEC_PLACEHOLDER', spec);

    return Response.ok(
      html,
      headers: {
        'Content-Type': 'text/html',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      },
    );
  }
} 