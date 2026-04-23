import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/ChangesController.dart';
import 'package:backend/services/ChangesService.dart';
import 'package:backend/model/entities/Changes.dart';

import 'ChangesControllerTest.mocks.dart';

@GenerateMocks([ChangesService])
void main() {
  late MockChangesService changesService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    changesService = MockChangesService();
    handler = ChangesController(changesService).router.call;
  });

  Changes _change({int id = 1}) => Changes(
    id: id,
    entityType: 'user',
    entityId: 1,
    changeType: 'update',
    fieldName: 'name',
    oldValue: 'old',
    newValue: 'new',
    createdAt: DateTime(2024),
  );

  Request _get(String path) =>
      Request('GET', Uri.parse('http://localhost/$path'));

  Request _post(String path, Map<String, dynamic> body) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  // ── GET / (recent) ────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 возвращает список изменений', () async {
      when(changesService.getRecentChanges(limit: anyNamed('limit')))
          .thenAnswer((_) async => [_change(), _change(id: 2)]);
      final resp = await handler(_get(''));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as List;
      expect(body.length, 2);
    });
  });

  // ── GET /entity/<entityType>/<entityId> ───────────────────────────────────
  group('GET /entity/<entityType>/<entityId>', () {
    test('200 возвращает изменения сущности', () async {
      when(changesService.getEntityChanges(any, 1))
          .thenAnswer((_) async => [_change()]);
      final resp = await handler(_get('entity/user/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /user/<userId> ────────────────────────────────────────────────────
  group('GET /user/<userId>', () {
    test('200 возвращает изменения пользователя', () async {
      when(changesService.getUserChanges(1))
          .thenAnswer((_) async => [_change()]);
      final resp = await handler(_get('user/1'));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /type/<changeType> ────────────────────────────────────────────────
  group('GET /type/<changeType>', () {
    test('200 возвращает изменения по типу', () async {
      when(changesService.getChangeTypeChanges(any))
          .thenAnswer((_) async => [_change()]);
      final resp = await handler(_get('type/update'));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /<changeId>/revert ───────────────────────────────────────────────
  group('POST /<changeId>/revert', () {
    test('200 при откате изменения', () async {
      when(changesService.revertChange(1, any, comment: anyNamed('comment')))
          .thenAnswer((_) async {});
      final resp = await handler(_post('1/revert', {'comment': 'тест'}));
      expect(resp.statusCode, 200);
    });
  });
}
