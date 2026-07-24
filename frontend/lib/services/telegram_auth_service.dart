import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class TelegramAuthService {
  static const String _botUsername = AppConfig.botUsername;
  static const String _baseUrl = AppConfig.telegramApiUrl;

  static final TelegramAuthService _instance = TelegramAuthService._internal();
  factory TelegramAuthService() => _instance;
  TelegramAuthService._internal();

  Future<void> openTelegramBot() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/telegram/initiate'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final botUrl = 'https://t.me/$_botUsername?start=$token';
        
        if (await canLaunchUrl(Uri.parse(botUrl))) {
          await launchUrl(
            Uri.parse(botUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Не удалось открыть Telegram');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при открытии бота: $e');
      rethrow;
    }
  }

}
