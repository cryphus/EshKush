import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/UserFavoriteService.dart';
import 'package:backend/repositories/UserFavoriteRepository.dart';
import 'package:backend/model/entities/UserFavorite.dart';

import 'UserFavoriteServiceTest.mocks.dart';

@GenerateMocks([UserFavoriteRepository])
void main() {
  late MockUserFavoriteRepository repo;
  late UserFavoriteService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockUserFavoriteRepository();
    sut  = UserFavoriteService(repo);
  });

  UserFavorite _fav({int userId = 1, int pointId = 10}) =>
      UserFavorite(userId: userId, pointId: pointId, createdAt: DateTime(2024));

  // ── addToFavorites ─────────────────────────────────────────────────────────
  group('addToFavorites', () {
    test('бросает если место уже добавлено в избранное', () async {
      when(repo.exists(1, 10)).thenAnswer((_) async => true);
      expect(() => sut.addToFavorites(_fav()), throwsA(isA<Exception>()));
    });

    test('успешно добавляет если не существует', () async {
      when(repo.exists(1, 10)).thenAnswer((_) async => false);
      when(repo.create(any)).thenAnswer((_) async => _fav());
      final result = await sut.addToFavorites(_fav());
      expect(result.userId, 1);
      verify(repo.create(any)).called(1);
    });
  });

  // ── removeFromFavorites ────────────────────────────────────────────────────
  group('removeFromFavorites', () {
    test('делегирует удаление в репозиторий', () async {
      when(repo.delete(1, 10)).thenAnswer((_) async {});
      await expectLater(sut.removeFromFavorites(1, 10), completes);
      verify(repo.delete(1, 10)).called(1);
    });
  });

  // ── isFavorite ─────────────────────────────────────────────────────────────
  group('isFavorite', () {
    test('возвращает true если добавлено', () async {
      when(repo.exists(1, 10)).thenAnswer((_) async => true);
      expect(await sut.isFavorite(1, 10), isTrue);
    });

    test('возвращает false если не добавлено', () async {
      when(repo.exists(1, 99)).thenAnswer((_) async => false);
      expect(await sut.isFavorite(1, 99), isFalse);
    });
  });

  // ── getByUserId ────────────────────────────────────────────────────────────
  group('getByUserId', () {
    test('возвращает избранные точки пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_fav(), _fav(pointId: 20)]);
      final result = await sut.getByUserId(1);
      expect(result.length, 2);
    });
  });
}
