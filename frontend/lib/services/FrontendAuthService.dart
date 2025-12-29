import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FrontendAuthService {
  final Dio _dio = Dio();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '672295969525-4rih26k55qehk1h9jj35rki5l4o8t8an.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  static const String _baseUrl = 'http://localhost:8080';

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final response = await _dio.post(
        '$_baseUrl/auth/google',
        data: {
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'idToken': googleAuth.idToken,
        },
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        ),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.data['access_token']);
        await prefs.setString('refresh_token', response.data['refresh_token']);
        return response.data;
      } else if (response.statusCode == 404) {
        return {
          'needsRegistration': true,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
        };
      } else {
        throw Exception('Ошибка аутентификации: ${response.data['error']}');
      }
    } catch (e) {
      print('Ошибка при входе через Google: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeRegistration({
    required String email,
    required String displayName,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'email': email,
          'username': displayName,
          'password': password,
          'phone': cleanPhone,
          'role': role.toLowerCase(),
        },
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        ),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.data['access_token']);
        await prefs.setString('refresh_token', response.data['refresh_token']);
        return response.data;
      }
      throw Exception('Ошибка при регистрации: ${response.data['error']}');
    } catch (e) {
      print('Ошибка при завершении регистрации: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      print('Ошибка при выходе: $e');
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
} 