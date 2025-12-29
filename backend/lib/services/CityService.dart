import '../model/entities/City.dart';
import '../repositories/CityRepository.dart';

class CityService {
  final CityRepository _repository;

  CityService(this._repository);

  Future<City?> getById(int id) async {
    return await _repository.findById(id);
  }

  Future<List<City>> getAll() async {
    return await _repository.findAll();
  }

  Future<City> create(City city) async {
    return await _repository.create(city);
  }

  Future<City> update(City city) async {
    return await _repository.update(city);
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
  }
} 