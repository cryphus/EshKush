import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthState {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => accessToken != null && user != null;
  bool get isGuest => user == null || user!.isGuest;

  AuthState copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearTokens = false,
    bool clearError = false,
  }) => AuthState(
        user: clearUser ? null : (user ?? this.user),
        accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
        refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<User?> _fetchCurrentUser() async {
    try {
      final response = await ApiClient().dio.get('/users/profile');
      if (response.data is! Map<String, dynamic>) return null;
      final raw = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      if (raw['number'] == null && raw['phone_number'] != null) {
        raw['number'] = raw['phone_number'];
      }
      return User.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  User _buildFallbackUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        throw const FormatException('Invalid JWT format');
      }

      final normalized = base64Url.normalize(parts[1]);
      final payloadRaw = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;

      final id = (payload['id'] as num?)?.toInt() ?? 0;
      final role = payload['role']?.toString() ?? 'user';

      return User(
        id: id,
        username: 'Пользователь',
        email: '',
        number: '',
        role: userRoleFromString(role),
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return User(
        id: 0,
        username: 'Пользователь',
        email: '',
        number: '',
        role: UserRole.user,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> loadSavedAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final refresh = prefs.getString('refresh_token');
      final userJson = prefs.getString('user_json');
      if (token != null) {
        User user;
        if (userJson != null) {
          user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        } else {
          user = _buildFallbackUserFromToken(token);
        }

        final needsRefreshFromApi =
            user.username.trim().isEmpty || user.username == 'OAuth User' || user.id == 0;
        final apiUser = await _fetchCurrentUser();
        if (apiUser != null && (needsRefreshFromApi || apiUser.id == user.id)) {
          user = apiUser;
          await prefs.setString('user_json', jsonEncode(user.toJson()));
        } else if (userJson == null) {
          await prefs.setString('user_json', jsonEncode(user.toJson()));
        }

        state = state.copyWith(
          user: user,
          accessToken: token,
          refreshToken: refresh,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setAuth({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_json', jsonEncode(user.toJson()));
    state = AuthState(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> updateToken(String newAccessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', newAccessToken);
    state = state.copyWith(accessToken: newAccessToken);
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_json');
    state = const AuthState();
  }

  void enterAsGuest() {
    state = AuthState(
      user: User(
        id: 0,
        username: 'Гость',
        email: '',
        number: '',
        role: UserRole.guest,
        createdAt: DateTime.now(),
      ),
    );
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
