import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/profile_api_service.dart';
import '../models/profile.dart';

class ProfileState {
  final Profile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({this.profile, this.isLoading = false, this.error});

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? error,
    bool clearProfile = false,
    bool clearError = false,
  }) => ProfileState(
        profile: clearProfile ? null : (profile ?? this.profile),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileApiService _api;

  ProfileNotifier({ProfileApiService? api})
      : _api = api ?? ProfileApiService(),
        super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _api.getMyProfile();
      state = ProfileState(profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setProfile(Profile profile) {
    state = ProfileState(profile: profile);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const ProfileState();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
