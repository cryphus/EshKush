import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> loadSavedAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final refresh = prefs.getString('refresh_token');
      final userJson = prefs.getString('user_json');
      if (token != null && userJson != null) {
        final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
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
