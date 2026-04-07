import 'dart:io';
import 'package:test/test.dart';
import 'package:backend/utils/AuthUtils.dart';
import '../../helpers/TestEnv.dart';

void main() {
  final skip = jwtEnvReady ? null : kJwtSkipReason;

  // ─── hashPassword / verifyPassword ──────────────────────────────────────────
  group('hashPassword / verifyPassword', () {
    test('хэш корректного пароля непустой и длиннее исходного', () {
      const pw = 'Secret@1234';
      final hash = AuthUtils.hashPassword(pw);
      expect(hash, isNotEmpty);
      expect(hash.length, greaterThan(pw.length));
    });

    test('verifyPassword: правильный пароль → true', () {
      const pw = 'Secret@1234';
      final hash = AuthUtils.hashPassword(pw);
      expect(AuthUtils.verifyPassword(pw, hash), isTrue);
    });

    test('verifyPassword: неверный пароль → false', () {
      final hash = AuthUtils.hashPassword('Secret@1234');
      expect(AuthUtils.verifyPassword('WrongPass!1', hash), isFalse);
    });

    test('два хэша одного пароля отличаются (соль уникальна)', () {
      const pw = 'Secret@1234';
      final h1 = AuthUtils.hashPassword(pw);
      final h2 = AuthUtils.hashPassword(pw);
      expect(h1, isNot(equals(h2)));
    });
  });

  // ─── generateTokens / verifyToken ───────────────────────────────────────────
  group('generateTokens / verifyToken', skip: skip, () {
    test('генерирует пару access_token + refresh_token', () {
      final tokens = AuthUtils.generateTokens(42, 'admin');
      expect(tokens['access_token'], isNotEmpty);
      expect(tokens['refresh_token'], isNotEmpty);
    });

    test('access_token состоит из трёх частей (header.payload.sig)', () {
      final tokens = AuthUtils.generateTokens(1, 'user');
      expect(tokens['access_token']!.split('.').length, equals(3));
    });

    test('verifyToken(access): payload содержит id, role, type=access, jti', () {
      final tokens = AuthUtils.generateTokens(7, 'partner');
      final payload = AuthUtils.verifyToken(tokens['access_token']!);
      expect(payload['id'], equals(7));
      expect(payload['role'], equals('partner'));
      expect(payload['type'], equals('access'));
      expect(payload['jti'], isNotNull);
    });

    test('verifyToken(refresh): payload содержит id, type=refresh, jti', () {
      final bundle = AuthUtils.generateTokenBundle(7, 'user');
      final payload = AuthUtils.verifyToken(
        bundle['refresh_token'] as String,
        isRefreshToken: true,
      );
      expect(payload['id'], equals(7));
      expect(payload['type'], equals('refresh'));
      expect(payload['jti'], isNotNull);
    });

    test('access_token отклоняется при isRefreshToken=true', () {
      final tokens = AuthUtils.generateTokens(1, 'user');
      expect(
        () => AuthUtils.verifyToken(tokens['access_token']!, isRefreshToken: true),
        throwsException,
      );
    });

    test('refresh_token отклоняется при isRefreshToken=false', () {
      final bundle = AuthUtils.generateTokenBundle(1, 'user');
      expect(
        () => AuthUtils.verifyToken(bundle['refresh_token'] as String),
        throwsException,
      );
    });

    test('повреждённая подпись → исключение', () {
      final tokens = AuthUtils.generateTokens(1, 'user');
      final tampered = '${tokens['access_token']!.substring(0, tokens['access_token']!.length - 4)}XXXX';
      expect(() => AuthUtils.verifyToken(tampered), throwsException);
    });

    test('неверный формат (не три части) → исключение', () {
      expect(() => AuthUtils.verifyToken('not.a.valid.jwt.token'), throwsException);
      expect(() => AuthUtils.verifyToken('onlyone'), throwsException);
    });

    test('пустой токен → исключение', () {
      expect(() => AuthUtils.verifyToken(''), throwsException);
    });

    test('generateTokenBundle содержит refresh_jti и refresh_expires_at', () {
      final bundle = AuthUtils.generateTokenBundle(5, 'support');
      expect(bundle['refresh_jti'], isNotNull);
      expect(bundle['refresh_expires_at'], isA<DateTime>());
      final exp = bundle['refresh_expires_at'] as DateTime;
      expect(exp.isAfter(DateTime.now()), isTrue);
    });
  });

  // ─── hashRefreshJti ──────────────────────────────────────────────────────────
  group('hashRefreshJti', skip: skip, () {
    test('один и тот же jti → одинаковый хэш', () {
      const jti = 'test-jti-value';
      expect(AuthUtils.hashRefreshJti(jti), equals(AuthUtils.hashRefreshJti(jti)));
    });

    test('разные jti → разные хэши', () {
      expect(
        AuthUtils.hashRefreshJti('jti-a'),
        isNot(equals(AuthUtils.hashRefreshJti('jti-b'))),
      );
    });

    test('хэш непустой и имеет ожидаемую длину SHA-256 (64 hex-символа)', () {
      final h = AuthUtils.hashRefreshJti('some-jti');
      expect(h, isNotEmpty);
      expect(h.length, equals(64));
    });
  });

  // ─── isTokenExpired ──────────────────────────────────────────────────────────
  group('isTokenExpired', skip: skip, () {
    test('свежесгенерированный access_token не истёк', () {
      final tokens = AuthUtils.generateTokens(1, 'user');
      expect(AuthUtils.isTokenExpired(tokens['access_token']!), isFalse);
    });

    test('свежесгенерированный refresh_token не истёк', () {
      final bundle = AuthUtils.generateTokenBundle(1, 'user');
      expect(AuthUtils.isTokenExpired(bundle['refresh_token'] as String), isFalse);
    });
  });

  // ─── JWT_SECRET не установлен ────────────────────────────────────────────────
  group('ошибка при отсутствии JWT_SECRET', () {
    test('generateTokens бросает исключение если JWT_SECRET пуст', () {
      // Этот тест проходит только если переменная не установлена.
      if (Platform.environment['JWT_SECRET']?.isNotEmpty ?? false) return;
      expect(() => AuthUtils.generateTokens(1, 'user'), throwsException);
    });
  });
}