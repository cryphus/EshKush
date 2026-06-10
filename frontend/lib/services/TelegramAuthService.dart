import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/RegistrationScreen.dart';
import 'dart:convert' show utf8, base64;
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
      print('Ошибка при открытии бота: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkUser(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/telegram/check_user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка проверки пользователя: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при проверке пользователя: $e');
      rethrow;
    }
  }

  Future<void> handleDeepLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final encodedData = uri.queryParameters['data'];
      
      if (encodedData != null) {
        final decodedData = utf8.decode(base64.decode(encodedData));
        final data = json.decode(decodedData);
        
        final phoneNumber = data['phoneNumber'];
        final firstName = data['firstName'];
        final lastName = data['lastName'];
        final exists = data['exists'];

        if (exists) {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/main');
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RegistrationScreen(
                  email: '',
                  displayName: '$firstName $lastName',
                  phoneNumber: phoneNumber,
                  isFromTelegram: true,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Ошибка при обработке deep link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
} 