import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import 'RegistrationScreen.dart';

/// Экран авторизации по номеру телефона.
/// Фаза 1: ввод номера → фаза 2: ввод кода из СМС.
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _codeSent = false;
  bool _isLoading = false;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Вход по телефону',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Иллюстрация
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FADC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _codeSent ? Icons.message_outlined : Icons.phone_android,
                  size: 52,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _codeSent
                  ? 'Введите код из СМС'
                  : 'Введите номер телефона',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'Мы отправили 4-значный код на ${_phoneController.text}'
                  : 'Мы отправим вам СМС с кодом подтверждения',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),

            if (!_codeSent) _buildPhaseOne() else _buildPhaseTwo(),
          ],
        ),
      ),
    );
  }

  // ── Фаза 1: ввод номера ─────────────────────────────────────────────────────
  Widget _buildPhaseOne() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            inputFormatters: [_phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Номер телефона', '+7 (999) 999-99-99'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Введите номер';
              if (!_phoneMaskFormatter.isFill()) return 'Введите полный номер';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Получить код',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Фаза 2: ввод кода ───────────────────────────────────────────────────────
  Widget _buildPhaseTwo() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.lightGreen),
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 4) return 'Введите 4-значный код';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Подтвердить',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 16),
          // Повторная отправка
          Center(
            child: TextButton(
              onPressed: _resendCountdown > 0 ? null : _sendCode,
              child: Text(
                _resendCountdown > 0
                    ? 'Повторить через $_resendCountdown с.'
                    : 'Отправить код повторно',
                style: TextStyle(
                  color: _resendCountdown > 0
                      ? Colors.black38
                      : AppColors.darkGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _codeSent = false;
                _codeController.clear();
              }),
              child: const Text(
                'Изменить номер',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    // Имитация отправки СМС (в реальном приложении — POST /auth/phone/send_code)
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _isLoading = false;
      _codeSent = true;
      _resendCountdown = 60;
    });
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendCountdown > 0) _resendCountdown--;
      });
      return _resendCountdown > 0;
    });
  }

  Future<void> _verifyCode() async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    // Имитация проверки кода (в реальном приложении — POST /auth/phone/verify)
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _isLoading = false);

    if (!mounted) return;

    // Для демо: код "1234" — вход как существующий пользователь,
    // любой другой — новый пользователь → регистрация
    if (_codeController.text == '1234') {
      // Существующий пользователь — мок-вход
      await AppState().loginWithData(
        name: 'Пользователь',
        phone: _phoneController.text,
        role: 'user',
        token: 'mock_token_phone_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Новый пользователь — переход на регистрацию с предзаполненным телефоном
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(
              email: '',
              displayName: '',
              phoneNumber: _phoneController.text,
              isFromTelegram: false,
            ),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightGreen),
      ),
    );
  }
}
