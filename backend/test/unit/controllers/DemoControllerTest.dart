import 'package:backend/controllers/DemoController.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/services/AuthService.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test(
    'demo endpoints stay unavailable without DEMO_MODE, with no DB connection',
    () async {
      final db = PostgreSQLConnection('unused.invalid', 5432, 'unused');
      final controller = DemoController(
        AuthService(UserRepository(db), UserSessionRepository(db)),
        db,
      );
      for (final path in [
        'session',
        'status',
        'state',
        'reset',
        'media/food-0.svg',
      ]) {
        final response = await controller.router(
          Request('GET', Uri.parse('http://localhost/$path')),
        );
        expect(response.statusCode, 404, reason: path);
      }
    },
  );
}
