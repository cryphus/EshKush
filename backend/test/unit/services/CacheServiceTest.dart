import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/CacheService.dart';

void main() {
  late CacheService cache;

  setUpAll(() async {
    AppConfig.initForTesting();
    cache = CacheService();
    await cache.initialize();
  });

  setUp(() async {
    await cache.flushAll();
  });

  // ── initialize ────────────────────────────────────────────────────────────
  group('initialize', () {
    test('isConnected = true после инициализации', () {
      expect(cache.isConnected, isTrue);
    });
  });

  // ── set / get ─────────────────────────────────────────────────────────────
  group('set / get', () {
    test('сохраняет и возвращает String', () async {
      await cache.set<String>('key_str', 'hello');
      expect(await cache.get<String>('key_str'), 'hello');
    });

    test('сохраняет и возвращает int', () async {
      await cache.set<int>('key_int', 42);
      expect(await cache.get<int>('key_int'), 42);
    });

    test('сохраняет и возвращает double', () async {
      await cache.set<double>('key_dbl', 3.14);
      expect(await cache.get<double>('key_dbl'), 3.14);
    });

    test('сохраняет и возвращает bool', () async {
      await cache.set<bool>('key_bool', true);
      expect(await cache.get<bool>('key_bool'), isTrue);
    });

    test('возвращает null для несуществующего ключа', () async {
      expect(await cache.get<String>('no_such_key'), isNull);
    });

    test('возвращает null после истечения TTL', () async {
      await cache.set<String>('key_ttl', 'expire',
          ttl: const Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(await cache.get<String>('key_ttl'), isNull);
    });

    test('set возвращает true при успехе', () async {
      expect(await cache.set<String>('k', 'v'), isTrue);
    });
  });

  // ── exists ────────────────────────────────────────────────────────────────
  group('exists', () {
    test('true для существующего ключа', () async {
      await cache.set<String>('ex_key', 'value');
      expect(await cache.exists('ex_key'), isTrue);
    });

    test('false для отсутствующего ключа', () async {
      expect(await cache.exists('no_key'), isFalse);
    });

    test('false после истечения TTL', () async {
      await cache.set<String>('ex_ttl', 'v',
          ttl: const Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(await cache.exists('ex_ttl'), isFalse);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет ключ и возвращает true', () async {
      await cache.set<String>('del_key', 'v');
      expect(await cache.delete('del_key'), isTrue);
      expect(await cache.exists('del_key'), isFalse);
    });

    test('возвращает false для несуществующего ключа', () async {
      expect(await cache.delete('missing'), isFalse);
    });
  });

  // ── deleteByPattern ───────────────────────────────────────────────────────
  group('deleteByPattern', () {
    test('удаляет ключи по паттерну и возвращает количество', () async {
      await cache.set<String>('user:1', 'a');
      await cache.set<String>('user:2', 'b');
      await cache.set<String>('order:1', 'c');
      final count = await cache.deleteByPattern('user:*');
      expect(count, 2);
      expect(await cache.exists('user:1'), isFalse);
      expect(await cache.exists('user:2'), isFalse);
      expect(await cache.exists('order:1'), isTrue);
    });

    test('возвращает 0 если паттерн ничего не совпал', () async {
      expect(await cache.deleteByPattern('no_match:*'), 0);
    });
  });

  // ── ttl ───────────────────────────────────────────────────────────────────
  group('ttl', () {
    test('-1 для ключа без TTL (хранится бессрочно)', () async {
      await cache.set<String>('no_ttl_key', 'v');
      expect(await cache.ttl('no_ttl_key'), -1);
    });

    test('-2 для несуществующего ключа', () async {
      expect(await cache.ttl('ghost'), -2);
    });

    test('> 0 для ключа с активным TTL', () async {
      await cache.set<String>('ttl_key', 'v',
          ttl: const Duration(seconds: 60));
      expect(await cache.ttl('ttl_key'), greaterThan(0));
    });
  });

  // ── expire ────────────────────────────────────────────────────────────────
  group('expire', () {
    test('устанавливает TTL для существующего ключа', () async {
      await cache.set<String>('exp_key', 'v');
      expect(await cache.expire('exp_key', const Duration(seconds: 30)), isTrue);
      expect(await cache.ttl('exp_key'), greaterThan(0));
    });

    test('возвращает false для несуществующего ключа', () async {
      expect(
          await cache.expire('no_key', const Duration(seconds: 30)), isFalse);
    });
  });

  // ── flushAll ──────────────────────────────────────────────────────────────
  group('flushAll', () {
    test('очищает весь кеш и возвращает true', () async {
      await cache.set<String>('k1', 'v1');
      await cache.set<String>('k2', 'v2');
      expect(await cache.flushAll(), isTrue);
      expect(await cache.exists('k1'), isFalse);
      expect(await cache.exists('k2'), isFalse);
    });
  });

  // ── getStats ──────────────────────────────────────────────────────────────
  group('getStats', () {
    test('содержит keyspace >= числа добавленных ключей', () async {
      await cache.set<String>('s1', 'v1');
      await cache.set<String>('s2', 'v2');
      final stats = await cache.getStats();
      expect(stats['keyspace'], greaterThanOrEqualTo(2));
      expect(stats['cache_type'], 'memory');
    });

    test('expired_keys > 0 если есть просроченные записи', () async {
      await cache.set<String>('exp', 'v',
          ttl: const Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      final stats = await cache.getStats();
      expect(stats['expired_keys'], greaterThan(0));
    });
  });

  // ── не подключён (после close) ────────────────────────────────────────────
  group('не подключён (после close)', () {
    setUp(() async => cache.close());
    tearDown(() async => cache.initialize());

    test('get возвращает null', () async {
      expect(await cache.get<String>('k'), isNull);
    });

    test('set возвращает false', () async {
      expect(await cache.set<String>('k', 'v'), isFalse);
    });

    test('delete возвращает false', () async {
      expect(await cache.delete('k'), isFalse);
    });

    test('exists возвращает false', () async {
      expect(await cache.exists('k'), isFalse);
    });

    test('flushAll возвращает false', () async {
      expect(await cache.flushAll(), isFalse);
    });

    test('ttl возвращает -1', () async {
      expect(await cache.ttl('k'), -1);
    });

    test('deleteByPattern возвращает 0', () async {
      expect(await cache.deleteByPattern('k*'), 0);
    });

    test('getStats возвращает {}', () async {
      expect(await cache.getStats(), isEmpty);
    });
  });
}
