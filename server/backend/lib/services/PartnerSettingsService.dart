import '../model/entities/PartnerSettings.dart';
import '../repositories/PartnerSettingsRepository.dart';

class PartnerSettingsService {
  final PartnerSettingsRepository _repository;

  PartnerSettingsService(this._repository);

  Future<List<PartnerSettings>> getAllSettings() async {
    return await _repository.findAll();
  }

  Future<PartnerSettings?> getSettings(int id) async {
    return await _repository.findById(id);
  }

  Future<PartnerSettings?> getSettingsByPartnerId(int partnerId) async {
    return await _repository.findByPartnerId(partnerId);
  }

  Future<PartnerSettings> createSettings(int partnerId, String brandingColor) async {
    final settings = PartnerSettings(
      id: 0,
      partnerId: partnerId,
      brandingColor: brandingColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _repository.create(settings);
  }

  Future<PartnerSettings> updateSettings(int id, Map<String, dynamic> data) async {
    if (data['branding_color'] != null) {
      final colorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
      if (!colorRegex.hasMatch(data['branding_color'])) {
        throw ArgumentError('Неверный формат цвета');
      }
    }
    
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _repository.update(id, data);
  }

  Future<PartnerSettings> updateBrandingColor(int id, String newColor) async {
    final colorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    if (!colorRegex.hasMatch(newColor)) {
      throw ArgumentError('Неверный формат цвета');
    }
    
    return await _repository.update(id, {
      'branding_color': newColor,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSettings(int id) async {
    await _repository.delete(id);
  }
} 