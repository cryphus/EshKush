import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ChangesService.dart';
import 'package:backend/repositories/ChangesRepository.dart';
import 'package:backend/model/entities/Changes.dart';
import 'package:backend/model/enums/EntityType.dart';
import 'package:backend/model/enums/ChangeType.dart';

import 'ChangesServiceTest.mocks.dart';

@GenerateMocks([ChangesRepository])
void main() {
  late MockChangesRepository repo;
  late ChangesService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockChangesRepository();
    sut  = ChangesService(repo);
  });

  Changes _change({int id = 1}) => Changes(
    id: id, entityType: 'order', entityId: 1,
    changeType: 'update', fieldName: 'status',
    oldValue: 'pending', newValue: 'completed',
    createdAt: DateTime(2024),
  );

  group('createChange', () {
    test('создаёт запись об изменении', () async {
      when(repo.create(any)).thenAnswer((_) async => _change());
      final result = await sut.createChange(
        entityType: 'order',
        entityId: 1,
        changeType: 'update',
        fieldName: 'status',
        oldValue: 'pending',
        newValue: 'completed',
      );
      expect(result.fieldName, 'status');
      verify(repo.create(any)).called(1);
    });
  });

  group('getEntityChanges', () {
    test('возвращает изменения сущности', () async {
      when(repo.findByEntity(EntityType.order, 1)).thenAnswer((_) async => [_change()]);
      final result = await sut.getEntityChanges(EntityType.order, 1);
      expect(result.length, 1);
    });
  });

  group('getUserChanges', () {
    test('возвращает изменения пользователя', () async {
      when(repo.findByUser(1)).thenAnswer((_) async => [_change()]);
      expect((await sut.getUserChanges(1)).length, 1);
    });
  });

  group('getChangeTypeChanges', () {
    test('возвращает изменения по типу', () async {
      when(repo.findByChangeType(ChangeType.update)).thenAnswer((_) async => [_change()]);
      expect((await sut.getChangeTypeChanges(ChangeType.update)).length, 1);
    });
  });

  group('revertChange', () {
    test('делегирует откат в репозиторий', () async {
      when(repo.revertChange(1, 2, comment: anyNamed('comment'))).thenAnswer((_) async {});
      await expectLater(sut.revertChange(1, 2, comment: 'mistake'), completes);
      verify(repo.revertChange(1, 2, comment: 'mistake')).called(1);
    });
  });
}
