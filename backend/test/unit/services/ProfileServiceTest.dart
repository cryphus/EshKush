import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/ProfileService.dart';
import 'package:backend/repositories/ProfileRepository.dart';
import 'package:backend/model/entities/Profile.dart';

import 'ProfileServiceTest.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository repo;
  late ProfileService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockProfileRepository();
    sut  = ProfileService(repo);
  });

  Profile _profile({int id = 1, int userId = 1}) => Profile(
    id: id, userId: userId,
    firstName: 'John', lastName: 'Doe',
    sumCO2: 0, savedMoney: 0.0, countBuy: 0,
    createdAt: DateTime(2024), updatedAt: DateTime(2024),
  );

  group('getProfile', () {
    test('возвращает профиль пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => _profile());
      expect((await sut.getProfile(1))?.userId, 1);
    });
    test('авто-создаёт профиль если не найден', () async {
      final created = _profile(userId: 99);
      when(repo.findByUserId(99)).thenAnswer((_) async => null);
      when(repo.create(any)).thenAnswer((_) async => created);
      final result = await sut.getProfile(99);
      expect(result, isNotNull);
      expect(result!.userId, 99);
    });
  });

  group('getProfileById', () {
    test('возвращает профиль по id', () async {
      when(repo.findById(1)).thenAnswer((_) async => _profile());
      expect((await sut.getProfileById(1))?.id, 1);
    });
  });

  group('createProfile', () {
    test('делегирует в репозиторий', () async {
      final p = _profile();
      when(repo.create(p)).thenAnswer((_) async => p);
      final result = await sut.createProfile(p);
      expect(result.firstName, 'John');
    });
  });

  group('update', () {
    test('делегирует в репозиторий', () async {
      final p = _profile();
      when(repo.update(p)).thenAnswer((_) async => p);
      final result = await sut.update(p);
      expect(result.id, 1);
    });
  });

  group('deleteProfile', () {
    test('делегирует в репозиторий', () async {
      when(repo.delete(1)).thenAnswer((_) async {});
      await expectLater(sut.deleteProfile(1), completes);
      verify(repo.delete(1)).called(1);
    });
  });
}
