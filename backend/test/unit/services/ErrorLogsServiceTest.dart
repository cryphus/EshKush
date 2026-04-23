import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ErrorLogsService.dart';
import 'package:backend/repositories/ErrorLogsRepository.dart';
import 'package:backend/model/entities/ErrorLogs.dart';
import 'package:backend/model/enums/ErrorSeverity.dart';

import 'ErrorLogsServiceTest.mocks.dart';

@GenerateMocks([ErrorLogsRepository])
void main() {
  late MockErrorLogsRepository repo;
  late ErrorLogsService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockErrorLogsRepository();
    sut  = ErrorLogsService(repo);
  });

  ErrorLogs _log({int id = 1, ErrorSeverity severity = ErrorSeverity.high}) =>
      ErrorLogs(
        id: id,
        errorMessage: 'Something went wrong',
        errorCode: 'ERR_001',
        stackTrace: '#0 main()',
        time: DateTime(2024),
        severity: severity,
      );

  group('logError', () {
    test('создаёт запись об ошибке', () async {
      when(repo.create(any)).thenAnswer((_) async => _log());
      final result = await sut.logError(
        errorMessage: 'Something went wrong',
        errorCode: 'ERR_001',
        stackTrace: '#0 main()',
        severity: ErrorSeverity.high,
      );
      expect(result.errorCode, 'ERR_001');
      verify(repo.create(any)).called(1);
    });
  });

  group('getErrorsBySeverity', () {
    test('возвращает ошибки по уровню', () async {
      when(repo.findBySeverity(ErrorSeverity.critical))
          .thenAnswer((_) async => [_log(severity: ErrorSeverity.critical)]);
      final result = await sut.getErrorsBySeverity(ErrorSeverity.critical);
      expect(result.length, 1);
    });
  });

  group('getErrorsByModule', () {
    test('возвращает ошибки по модулю', () async {
      when(repo.findByModule('auth')).thenAnswer((_) async => [_log()]);
      expect((await sut.getErrorsByModule('auth')).length, 1);
    });
  });

  group('getUnresolvedErrors', () {
    test('возвращает нерешённые ошибки', () async {
      when(repo.findUnresolved()).thenAnswer((_) async => [_log(), _log(id: 2)]);
      expect((await sut.getUnresolvedErrors()).length, 2);
    });
  });

  group('markErrorAsResolved', () {
    test('делегирует в репозиторий', () async {
      when(repo.markAsResolved(1, 'admin')).thenAnswer((_) async {});
      await expectLater(sut.markErrorAsResolved(1, 'admin'), completes);
      verify(repo.markAsResolved(1, 'admin')).called(1);
    });
  });
}
