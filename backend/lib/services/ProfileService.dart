import '../model/entities/Profile.dart';
import '../repositories/ProfileRepository.dart';

class ProfileService {
  final ProfileRepository _repository;

  ProfileService(this._repository);

  Future<Profile?> getProfile(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<Profile?> getProfileById(int id) async {
    return await _repository.findById(id);
  }

  Future<Profile> createProfile(Profile profile) async {
    return await _repository.create(profile);
  }

  Future<Profile> update(Profile profile) async {
    return await _repository.update(profile);
  }

  Future<void> deleteProfile(int userId) async {
    await _repository.delete(userId);
  }
}