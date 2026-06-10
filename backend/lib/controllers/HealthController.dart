import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/CacheService.dart';

class HealthController {
  final PostgreSQLConnection _connection;
  final CacheService _cache;
  final DateTime _startTime = DateTime.now();
  static const String _version = '1.0.0';

  HealthController(this._connection, this._cache);

  Router get router {
    final r = Router();
    r.get('/', _handle);
    return r;
  }

  Future<Response> _handle(Request request) async {
    final dbStatus = await _checkDb();
    final cacheStatus = _checkCache();

    final allOk = dbStatus == 'ok' && cacheStatus == 'ok';
    final anyError = dbStatus == 'error';
    final overallStatus = anyError ? 'error' : (allOk ? 'ok' : 'degraded');

    final body = jsonEncode({
      'status': overallStatus,
      'version': _version,
      'uptime': DateTime.now().difference(_startTime).inSeconds,
      'checks': {
        'database': dbStatus,
        'cache': cacheStatus,
      },
    });

    final statusCode = overallStatus == 'error' ? HttpStatus.serviceUnavailable : HttpStatus.ok;
    return Response(statusCode, body: body, headers: {'Content-Type': 'application/json'});
  }

  Future<String> _checkDb() async {
    try {
      await _connection.query('SELECT 1');
      return 'ok';
    } catch (_) {
      return 'error';
    }
  }

  String _checkCache() => _cache.isConnected ? 'ok' : 'error';
}
