import '../model/entities/Partner.dart';
import '../repositories/PartnerRepository.dart';

class PartnerService {
  final PartnerRepository _repository;

  PartnerService(this._repository);

  Future<Partner?> getPartner(int id) async {
    return await _repository.findById(id);
  }

  Future<List<Partner>> getAllPartners() async {
    return await _repository.findAll();
  }

  Future<Partner> createPartner(Partner partner) async {
    return await _repository.create(partner);
  }

  Future<Partner> updatePartner(int id, Map<String, dynamic> data) async {
    return await _repository.update(id, data);
  }

  Future<void> deletePartner(int id) async {
    await _repository.delete(id);
  }

  Future<Partner> updatePartnerName(int id, String newName) async {
    if (newName.isEmpty) {
      throw ArgumentError('Имя не может быть пустым');
    }
    return await _repository.update(id, {'name': newName});
  }

  Future<Partner> updatePartnerMaxDiscount(int id, double newDiscount) async {
    if (newDiscount < 0 || newDiscount > 100) {
      throw ArgumentError('Максимальная скидка должна быть между 0 и 100');
    }
    return await _repository.update(id, {'max_discount': newDiscount});
  }
} 