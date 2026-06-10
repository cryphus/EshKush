import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ErrorLogsRepository.dart';
import 'package:backend/model/entities/ErrorLogs.dart';
import 'package:backend/model/enums/ErrorSeverity.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late ErrorLogsRepository repo;

  ErrorLogs _err({
    ErrorSeverity severity = ErrorSeverity.high,
    String? module,
  }) =>
      ErrorLogs(
        id: 0,
        errorMessage: 'Test error message',
        errorCode: 'ERR_001',
        stackTrace: '#0 main (test.dart:1)',
        time: DateTime.now(),
        severity: severity,
        module: module,
      );

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ErrorLogsRepository(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['error_logs']));

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт лог ошибки с id > 0', () async {
      final result = await repo.create(_err());
      expect(result.id, greaterThan(0));
      expect(result.errorCode, 'ERR_001');
      expect(result.resolved, isFalse);
    });

    test('сохраняет severity', () async {
      final result = await repo.create(_err(severity: ErrorSeverity.critical));
      expect(result.severity, ErrorSeverity.critical);
    });

    test('сохраняет module если передан', () async {
      final result = await repo.create(_err(module: 'auth'));
      expect(result.module, 'auth');
    });
  });

  // ── findBySeverity ────────────────────────────────────────────────────────
  group('findBySeverity', () {
    test('возвращает логи с заданным severity', () async {
      await repo.create(_err(severity: ErrorSeverity.high));
      await repo.create(_err(severity: ErrorSeverity.low));
      final highs = await repo.findBySeverity(ErrorSeverity.high);
      expect(highs.length, 1);
      expect(highs.first.severity, ErrorSeverity.high);
    });

    test('возвращает пустой список если нет совпадений', () async {
      await repo.create(_err(severity: ErrorSeverity.low));
      expect(await repo.findBySeverity(ErrorSeverity.critical), isEmpty);
    });
  });

  // ── findByModule ──────────────────────────────────────────────────────────
  group('findByModule', () {
    test('возвращает логи по модулю', () async {
      await repo.create(_err(module: 'auth'));
      await repo.create(_err(module: 'orders'));
      final authLogs = await repo.findByModule('auth');
      expect(authLogs.length, 1);
      expect(authLogs.first.module, 'auth');
    });

    test('возвращает пустой список для неизвестного модуля', () async {
      expect(await repo.findByModule('unknown'), isEmpty);
    });
  });

  // ── findUnresolved ────────────────────────────────────────────────────────
  group('findUnresolved', () {
    test('возвращает только нерешённые ошибки', () async {
      final err = await repo.create(_err());
      await repo.markAsResolved(err.id, 'admin');
      await repo.create(_err()); // нерешённая
      final unresolved = await repo.findUnresolved();
      expect(unresolved.length, 1);
      expect(unresolved.first.resolved, isFalse);
    });
  });

  // ── findRecent ────────────────────────────────────────────────────────────
  group('findRecent', () {
    test('возвращает не более limit записей', () async {
      for (var i = 0; i < 5; i++) await repo.create(_err());
      final recent = await repo.findRecent(limit: 3);
      expect(recent.length, 3);
    });
  });

  // ── markAsResolved ────────────────────────────────────────────────────────
  group('markAsResolved', () {
    test('помечает ошибку как решённую', () async {
      final created = await repo.create(_err());
      await repo.markAsResolved(created.id, 'admin');
      final unresolved = await repo.findUnresolved();
      expect(unresolved.where((e) => e.id == created.id), isEmpty);
    });
  });
}
