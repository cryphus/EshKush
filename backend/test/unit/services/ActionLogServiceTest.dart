import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ActionLogService.dart';
import 'package:backend/repositories/ActionLogRepository.dart';
import 'package:backend/model/entities/ActionLog.dart';
import 'package:backend/model/enums/ActionType.dart';
import 'package:backend/model/enums/EntityType.dart';

import 'ActionLogServiceTest.mocks.dart';

@GenerateMocks([ActionLogRepository])
void main() {
  late MockActionLogRepository repo;
  late ActionLogService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockActionLogRepository();
    sut  = ActionLogService(repo);
  });

  ActionLog _log({int id = 1}) => ActionLog(
    id: id, userId: 1,
    actionType: ActionType.create,
    targetEntity: EntityType.order,
    targetId: 10,
    details: 'Created order',
    timestamp: DateTime(2024),
    ipAddress: '127.0.0.1',
    isSuccess: true,
  );

  group('logAction', () {
    test('создаёт лог действия', () async {
      when(repo.create(any)).thenAnswer((_) async => _log());
      final result = await sut.logAction(
        userId: 1,
        actionType: ActionType.create,
        targetEntity: EntityType.order,
        targetId: 10,
        details: 'Created order',
        ipAddress: '127.0.0.1',
      );
      expect(result.userId, 1);
      verify(repo.create(any)).called(1);
    });
  });

  group('logFailedAction', () {
    test('создаёт лог неудачного действия', () async {
      when(repo.create(any)).thenAnswer((_) async => _log());
      await expectLater(
        sut.logFailedAction(
          userId: 1,
          actionType: ActionType.delete,
          targetEntity: EntityType.order,
          targetId: 5,
          details: 'Failed to delete',
          ipAddress: '127.0.0.1',
          errorMessage: 'Not found',
        ),
        completes,
      );
      verify(repo.create(any)).called(1);
    });
  });

  group('getUserLogs', () {
    test('возвращает логи пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_log(), _log(id: 2)]);
      expect((await sut.getUserLogs(1)).length, 2);
    });
  });

  group('getEntityLogs', () {
    test('возвращает логи сущности', () async {
      when(repo.findByEntity(EntityType.order, 10)).thenAnswer((_) async => [_log()]);
      expect((await sut.getEntityLogs(EntityType.order, 10)).length, 1);
    });
  });

  group('getRecentLogs', () {
    test('возвращает последние логи', () async {
      when(repo.findRecent(limit: anyNamed('limit'))).thenAnswer((_) async => [_log()]);
      expect((await sut.getRecentLogs()).length, 1);
    });
  });
}
