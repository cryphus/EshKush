import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/city_api_service.dart';
import '../models/city.dart';

/// Список городов с бэкенда (GET /cities/).
final citiesProvider = FutureProvider<List<City>>((ref) async {
  return CityApiService().getAllCities();
});

/// Выбранный город. null — город ещё не выбран (показываем первый из списка).
final selectedCityProvider = StateProvider<City?>((ref) => null);
