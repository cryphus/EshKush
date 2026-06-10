import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:resp_client/resp_server.dart';

/// Абстракция хранилища для rate limiter.
///
/// Позволяет использовать разные бэкенды:
///   - [InMemoryRateLimiterStore] — по умолчанию, один инстанс / dev
///   - [RedisRateLimiterStore] — production, несколько инстансов
abstract class RateLimiterStore {
  Future<int> increment(String key, Duration window);
  Future<void> close() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// In-Memory реализация (один инстанс / dev / тесты)
// ─────────────────────────────────────────────────────────────────────────────

class InMemoryRateLimiterStore implements RateLimiterStore {
  final Map<String, List<DateTime>> _windows = {};

  @override
  Future<int> increment(String key, Duration window) async {
    final now = DateTime.now();
    final times = _windows[key]?.where((t) => now.difference(t) < window).toList() ?? [];
    times.add(now);
    _windows[key] = times;
    return times.length;
  }

  @override
  Future<void> close() async => _windows.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// Redis реализация (production / несколько инстансов)
// ─────────────────────────────────────────────────────────────────────────────

/// Rate limiter на базе Redis (resp_client 1.x).
/// INCR + PEXPIRE — атомарный счётчик с автоистечением.
/// Счётчики не теряются при перезапуске сервера.
class RedisRateLimiterStore implements RateLimiterStore {
  final RespCommandsTier1 _commands;
  final RespServerConnection _connection;

  RedisRateLimiterStore._(this._commands, this._connection);

  static Future<RedisRateLimiterStore> connect(
    String host,
    int port, {
    String? password,
    int db = 0,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final conn = await connectSocket(host, port: port, timeout: timeout);
    final client = RespClient(conn);
    final commands = RespCommandsTier1(client);

    if (password != null && password.isNotEmpty) {
      await commands.auth(password);
    }
    if (db != 0) {
      await commands.select(db);
    }
    return RedisRateLimiterStore._(commands, conn);
  }

  @override
  Future<int> increment(String key, Duration window) async {
    final redisKey = 'rl:$key';
    // INCR атомарен — безопасно при конкурентных запросах
    final incrResult = await _commands.incr(redisKey);
    final count = (incrResult as RespInteger).payload;
    if (count == 1) {
      // Первый запрос в окне — устанавливаем TTL через PEXPIRE
      await _commands.pexpire(redisKey, window);
    }
    return count;
  }

  @override
  Future<void> close() async => await _connection.close();
}