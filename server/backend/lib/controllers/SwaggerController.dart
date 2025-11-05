import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

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
      final currentDir = Directory.current.path;
      final swaggerFile = File(path.join(currentDir, 'lib', 'config', 'swagger.json'));
      
      if (await swaggerFile.exists()) {
        final spec = await swaggerFile.readAsString();
        return Response.ok(
          spec,
          headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          },
        );
      } else {
        // Р•СЃР»Рё С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ, РІРѕР·РІСЂР°С‰Р°РµРј Р±Р°Р·РѕРІСѓСЋ СЃРїРµС†РёС„РёРєР°С†РёСЋ
        final swaggerJson = {
          'openapi': '3.0.0',
          'info': {
            'title': 'EshKush API',
            'version': '1.0.0',
            'description': 'API РґРѕРєСѓРјРµРЅС‚Р°С†РёСЏ РґР»СЏ EshKush'
          },
          'paths': {
            '/auth/google': {
              'post': {
                'summary': 'РђСѓС‚РµРЅС‚РёС„РёРєР°С†РёСЏ С‡РµСЂРµР· Google',
                'responses': {
                  '200': {
                    'description': 'РЈСЃРїРµС€РЅР°СЏ Р°СѓС‚РµРЅС‚РёС„РёРєР°С†РёСЏ'
                  }
                }
              }
            },
            '/auth/register': {
              'post': {
                'summary': 'Р РµРіРёСЃС‚СЂР°С†РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ',
                'responses': {
                  '200': {
                    'description': 'РЈСЃРїРµС€РЅР°СЏ СЂРµРіРёСЃС‚СЂР°С†РёСЏ'
                  }
                }
              }
            }
          }
        };

        return Response.ok(
          jsonEncode(swaggerJson),
          headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          },
        );
      }
    } catch (e) {
      print('РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё swagger.json: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё РґРѕРєСѓРјРµРЅС‚Р°С†РёРё API'}),
      );
    }
  }

  Future<Response> _getSwaggerUI(Request request) async {
    print('=== РћС‚РїСЂР°РІР»СЏРµРј Swagger UI ===');
    
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
            console.log('Swagger UI Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ...');
            SwaggerUIBundle({
                url: "/swagger/swagger.json",
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

    return Response.ok(
      swaggerUI,
      headers: {
        'Content-Type': 'text/html',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      },
    );
  }

  Handler get handler => _router.call;
} 
