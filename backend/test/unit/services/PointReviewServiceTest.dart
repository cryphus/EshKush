import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PointReviewService.dart';
import 'package:backend/repositories/PointReviewRepository.dart';
import 'package:backend/model/entities/PointReview.dart';

import 'PointReviewServiceTest.mocks.dart';

@GenerateMocks([PointReviewRepository])
void main() {
  late MockPointReviewRepository repo;
  late PointReviewService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockPointReviewRepository();
    sut  = PointReviewService(repo);
  });

  PointReview _review({int id = 1, double rating = 4.5}) =>
      PointReview(id: id, pointId: 1, userId: 1, createdAt: DateTime(2024), rating: rating);

  group('getById', () {
    test('возвращает отзыв', () async {
      when(repo.findById(1)).thenAnswer((_) async => _review());
      expect((await sut.getById(1))?.id, 1);
    });
    test('возвращает null если не найден', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(await sut.getById(99), isNull);
    });
  });

  group('getByPointId', () {
    test('возвращает отзывы точки', () async {
      when(repo.findByPointId(1)).thenAnswer((_) async => [_review(id: 1), _review(id: 2)]);
      expect((await sut.getByPointId(1)).length, 2);
    });
  });

  group('getByUserId', () {
    test('возвращает отзывы пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_review()]);
      expect((await sut.getByUserId(1)).length, 1);
    });
  });

  group('create', () {
    test('делегирует в репозиторий', () async {
      final r = _review();
      when(repo.create(r)).thenAnswer((_) async => r);
      expect((await sut.create(r)).rating, 4.5);
    });
  });

  group('update', () {
    test('делегирует в репозиторий', () async {
      final r = _review(rating: 3.0);
      when(repo.update(r)).thenAnswer((_) async => r);
      expect((await sut.update(r)).rating, 3.0);
    });
  });

  group('delete', () {
    test('делегирует в репозиторий', () async {
      when(repo.delete(1)).thenAnswer((_) async {});
      await expectLater(sut.delete(1), completes);
      verify(repo.delete(1)).called(1);
    });
  });
}
