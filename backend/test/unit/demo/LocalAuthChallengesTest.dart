import 'package:backend/demo/LocalAuthChallenges.dart';
import 'package:test/test.dart';

void main() {
  late DateTime time;
  late LocalAuthChallenges service;
  setUp(() {
    time = DateTime.utc(2026, 10, 15);
    service = LocalAuthChallenges(clock: () => time);
  });
  test('normalizes Russian phone number and binds role to challenge', () {
    final c = service.issue('8 (999) 123-45-67', 'partner');
    expect(c['phone'], '+79991234567');
    expect(service.verify(c['challenge_id'], c['code_preview']), 'partner');
  });
  test('rejects malformed phones and unsupported roles', () {
    expect(() => service.issue('123', 'user'), throwsArgumentError);
    expect(() => service.issue('+79991234567', 'admin'), throwsArgumentError);
  });
  test('rejects a wrong code and accepts the correct one', () {
    final c = service.issue('+79991234567', 'user');
    expect(
        () => service.verify(c['challenge_id'], 'wrong'), throwsArgumentError);
    expect(service.verify(c['challenge_id'], c['code_preview']), 'user');
  });
  test('a code cannot be replayed after verification', () {
    final c = service.issue('+79991234567', 'user');
    service.verify(c['challenge_id'], c['code_preview']);
    expect(() => service.verify(c['challenge_id'], c['code_preview']),
        throwsArgumentError);
  });
  test('expired code is rejected', () {
    final c = service.issue('+79991234567', 'user');
    time = time.add(const Duration(minutes: 3));
    expect(() => service.verify(c['challenge_id'], c['code_preview']),
        throwsArgumentError);
  });
  test('resending invalidates the previous code and enforces cooldown', () {
    final first = service.issue('+79991234567', 'user');
    expect(() => service.issue('+79991234567', 'user'), throwsStateError);
    time = time.add(const Duration(seconds: 30));
    final second = service.issue('+79991234567', 'user');
    expect(() => service.verify(first['challenge_id'], first['code_preview']),
        throwsArgumentError);
    expect(
        service.verify(second['challenge_id'], second['code_preview']), 'user');
  });
  test('too many incorrect attempts invalidate challenge', () {
    final c = service.issue('+79991234567', 'user');
    for (var i = 0; i < 5; i++) {
      expect(() => service.verify(c['challenge_id'], '000000'),
          throwsArgumentError);
    }
    expect(() => service.verify(c['challenge_id'], c['code_preview']),
        throwsStateError);
  });
}
