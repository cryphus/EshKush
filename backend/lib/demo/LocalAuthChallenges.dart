import 'dart:math';

/// A local stand-in for SMS delivery; only exposed by the gated demo router.
class LocalAuthChallenges {
  final DateTime Function() now;
  final Random _random = Random.secure();
  final Map<String, _Challenge> _challenges = {};
  LocalAuthChallenges({DateTime Function()? clock})
      : now = clock ?? DateTime.now;

  Map<String, dynamic> issue(String phone, String role) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8'))
      digits = '7${digits.substring(1)}';
    if (!RegExp(r'^7\d{10}$').hasMatch(digits))
      throw ArgumentError('Введите номер в формате +7 999 123-45-67');
    if (!['user', 'partner'].contains(role))
      throw ArgumentError('Этот способ входа недоступен');
    final time = now();
    _challenges.removeWhere((_, c) => !c.expires.isAfter(time));
    if (_challenges.length >= 200)
      throw StateError('Слишком много запросов. Попробуйте позже');
    final recent = _challenges.values.where(
        (c) => c.phone == digits && time.difference(c.created).inSeconds < 30);
    if (recent.isNotEmpty)
      throw StateError('Новый код можно запросить через 30 секунд');
    _challenges.removeWhere((_, c) => c.phone == digits && c.role == role);
    final id = List.generate(
            24, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final code = (100000 + _random.nextInt(900000)).toString();
    final challenge = _Challenge(
        digits, role, code, time, time.add(const Duration(minutes: 3)));
    _challenges[id] = challenge;
    return {
      'challenge_id': id,
      'code_preview': code,
      'phone': '+$digits',
      'expires_at': challenge.expires.toUtc().toIso8601String(),
      'retry_after': 30
    };
  }

  String verify(String id, String code) {
    final c = _challenges[id];
    if (c == null) throw ArgumentError('Запросите новый код');
    if (!c.expires.isAfter(now())) {
      _challenges.remove(id);
      throw ArgumentError('Срок действия кода истёк. Запросите новый');
    }
    if (++c.attempts > 5) {
      _challenges.remove(id);
      throw StateError('Слишком много попыток. Запросите новый код');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code) || code != c.code)
      throw ArgumentError('Код не совпал. Проверьте шесть цифр');
    _challenges.remove(id);
    return c.role;
  }
}

class _Challenge {
  final String phone, role, code;
  final DateTime created, expires;
  int attempts = 0;
  _Challenge(this.phone, this.role, this.code, this.created, this.expires);
}
