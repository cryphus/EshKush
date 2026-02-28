import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/FrontendAuthService.dart';
import '../state/app_state.dart';
import 'package:shared/enums/UserRole.dart';

class RegistrationScreen extends StatefulWidget {
  final String email;
  final String displayName;
  final String? phoneNumber;
  final bool isFromTelegram;

  const RegistrationScreen({
    super.key,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.isFromTelegram = false,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  final _authService = FrontendAuthService();
  bool _isLoading = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isFromTelegram
              ? 'Регистрация через Telegram'
              : 'Завершение регистрации',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Данные из провайдера
              _buildProviderInfo(),
              const SizedBox(height: 24),

              // Телефон (только если не от Telegram)
              if (!widget.isFromTelegram) ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Номер телефона', '+7 (999) 999-99-99'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите номер телефона';
                    }
                    if (!_phoneMaskFormatter.isFill()) {
                      return 'Введите корректный номер';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Пароль
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Пароль', 'Минимум 6 символов'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите пароль';
                  if (value.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Роль (только user и partner для самостоятельной регистрации)
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: _inputDecoration('Тип аккаунта', null),
                items: [UserRole.user, UserRole.partner]
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role == UserRole.user ? 'Покупатель' : 'Владелец точки',
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Создать аккаунт',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FADC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isFromTelegram ? 'Данные из Telegram' : 'Данные из аккаунта',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (widget.displayName.isNotEmpty)
            _infoRow('Имя', widget.displayName),
          if (!widget.isFromTelegram && widget.email.isNotEmpty)
            _infoRow('Email', widget.email),
          if (widget.isFromTelegram && widget.phoneNumber != null)
            _infoRow('Телефон', widget.phoneNumber!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF91CA6D)),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.completeRegistration(
        email: widget.email,
        displayName: widget.displayName,
        phone: widget.isFromTelegram
            ? (widget.phoneNumber ?? '')
            : _phoneMaskFormatter.getMaskedText(),
        password: _passwordController.text,
        role: _selectedRole.name,
      );

      if (mounted && result['access_token'] != null) {
        await AppState().loginWithData(
          name: widget.displayName,
          phone: widget.isFromTelegram ? widget.phoneNumber : null,
          email: widget.email.isNotEmpty ? widget.email : null,
          role: _selectedRole.name,
          token: result['access_token'],
        );
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
