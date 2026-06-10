import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class SimpleRegisterScreen extends ConsumerStatefulWidget {
  const SimpleRegisterScreen({super.key});

  @override
  ConsumerState<SimpleRegisterScreen> createState() => _SimpleRegisterScreenState();
}

class _SimpleRegisterScreenState extends ConsumerState<SimpleRegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 ### ### ##-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _dio = ApiClient().dio;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty &&
      _phoneMask.isFill() &&
      !_isLoading;

  String? _validate() {
    final username = _usernameController.text.trim();
    if (username.length < 3) return 'Логин: минимум 3 символа';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Логин: только латинские буквы, цифры и _';
    }

    final pass = _passwordController.text;
    if (pass.length < 8) return 'Пароль: минимум 8 символов';
    if (!pass.contains(RegExp(r'[A-Z]'))) return 'Пароль: нужна заглавная буква';
    if (!pass.contains(RegExp(r'[a-z]'))) return 'Пароль: нужна строчная буква';
    if (!pass.contains(RegExp(r'[0-9]'))) return 'Пароль: нужна цифра';
    if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Пароль: нужен спецсимвол (!@#\$%^&*...)';
    }

    if (pass != _confirmController.text) return 'Пароли не совпадают';

    return null;
  }

  Future<void> _onRegister() async {
    if (!_canSubmit) return;

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final phone = _phoneMask.getMaskedText().replaceAll(RegExp(r'[\s\-]'), '');

      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'password_confirm': _confirmController.text,
          'number': phone,
          'role': 'user',
        },
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>? ?? {};
        final user = User.fromJson({
          'id': userData['id'] ?? 0,
          'username': userData['username'] ?? _usernameController.text.trim(),
          'email': userData['email'],
          'number': userData['phoneNumber'],
          'role': userData['role'] ?? 'user',
          'createdAt': DateTime.now().toIso8601String(),
        });
        await ref.read(authProvider.notifier).setAuth(
              user: user,
              accessToken: data['access_token'] ?? '',
              refreshToken: data['refresh_token'] ?? '',
            );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        final msg = (response.data as Map<String, dynamic>?)?['error']?.toString()
            ?? 'Ошибка регистрации';
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Регистрация',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _label('Логин'),
            const SizedBox(height: 8),
            _field(
              controller: _usernameController,
              hint: 'Только латиница, цифры, _',
            ),
            const SizedBox(height: 16),
            _label('Телефон'),
            const SizedBox(height: 8),
            _maskedField(),
            const SizedBox(height: 16),
            _label('Пароль'),
            const SizedBox(height: 8),
            _field(
              controller: _passwordController,
              hint: 'Мин. 8 символов, A-z, 0-9, спецсимвол',
              obscure: _obscurePassword,
              suffix: _visibilityToggle(
                visible: _obscurePassword,
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 16),
            _label('Подтверждение пароля'),
            const SizedBox(height: 8),
            _field(
              controller: _confirmController,
              hint: 'Повторите пароль',
              obscure: _obscureConfirm,
              suffix: _visibilityToggle(
                visible: _obscureConfirm,
                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _onRegister : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? AppColors.accentGreen : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Создать аккаунт',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return StatefulBuilder(
      builder: (_, setLocal) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: suffix,
          ),
        ),
      ),
    );
  }

  Widget _maskedField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _phoneController,
        inputFormatters: [_phoneMask],
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 16),
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          hintText: '+7 ___ ___ __-__',
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _visibilityToggle({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(visible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
      onPressed: onTap,
    );
  }
}
