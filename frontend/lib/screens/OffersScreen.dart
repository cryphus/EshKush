import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../models/point.dart';
import '../providers/points_provider.dart';
import '../theme/colors.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/points_map.dart';
import '../widgets/skeleton.dart';

class OffersPage extends ConsumerStatefulWidget {
  const OffersPage({super.key});

  @override
  ConsumerState<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends ConsumerState<OffersPage> {
  int _activeTab = 0; // 0 = Для вас, 1 = Карта
  bool _isSearchVisible = false;
  String _searchQuery = '';
  int _selectedCategory = 0;

  // Простая клиентская "пагинация" — пока бэк не отдаёт страницы.
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  // "Рядом" — сортировка по дистанции от текущей позиции пользователя.
  bool _nearMeEnabled = false;
  bool _nearMeLoading = false;
  double? _userLat;
  double? _userLon;

  final List<String> _categories = [
    'Все',
    'Пекарни',
    'Кондитерские',
    'Суши',
    'Пицца',
    'Кофейни',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pointsProvider.notifier).loadAll();
    });
  }

  Future<void> _refresh() async {
    setState(() => _visibleCount = _pageSize);
    await ref.read(pointsProvider.notifier).loadAll();
  }

  List<Point> _filter(List<Point> points) {
    Iterable<Point> result = points;

    if (_selectedCategory > 0) {
      final tag = _categories[_selectedCategory].toLowerCase();
      result = result.where((p) {
        // ищем в названии и в тегах (значениях/ключах)
        if (p.name.toLowerCase().contains(tag.substring(0, tag.length - 1))) {
          return true;
        }
        for (final entry in p.tags.entries) {
          if (entry.key.toLowerCase().contains(tag) ||
              entry.value.toString().toLowerCase().contains(tag)) {
            return true;
          }
        }
        return false;
      });
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q));
    }

    // "Рядом": добавляем distanceM и сортируем по возрастанию расстояния.
    if (_nearMeEnabled && _userLat != null && _userLon != null) {
      final enriched = result.map((p) {
        final d = _haversineM(_userLat!, _userLon!, p.latitude, p.longitude);
        return Point(
          id: p.id,
          name: p.name,
          address: p.address,
          rating: p.rating,
          cityId: p.cityId,
          products: p.products,
          openingHours: p.openingHours,
          closingHours: p.closingHours,
          partnerId: p.partnerId,
          longitude: p.longitude,
          latitude: p.latitude,
          tags: p.tags,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
          distanceM: d,
        );
      }).toList()
        ..sort((a, b) => (a.distanceM ?? 0).compareTo(b.distanceM ?? 0));
      return enriched;
    }

    return result.toList();
  }

  /// Haversine: расстояние между двумя точками на сфере Земли в метрах.
  double _haversineM(double lat1, double lon1, double lat2, double lon2) {
    const earthR = 6371000.0; // радиус Земли в метрах
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthR * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  Future<void> _toggleNearMe() async {
    if (_nearMeEnabled) {
      setState(() => _nearMeEnabled = false);
      return;
    }
    if (_userLat != null && _userLon != null) {
      setState(() => _nearMeEnabled = true);
      return;
    }
    setState(() => _nearMeLoading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        showSnack('Включите геолокацию в настройках', kind: SnackKind.error);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showSnack('Нет доступа к геолокации', kind: SnackKind.error);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLon = pos.longitude;
        _nearMeEnabled = true;
      });
    } catch (e) {
      if (!mounted) return;
      showSnack('Не удалось определить локацию: $e', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _nearMeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = ref.watch(pointsProvider);
    final filtered = _filter(pointsState.points);
    final visible = filtered.take(_visibleCount).toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: _buildTabs(),
        ),
        const SizedBox(height: 12),
        if (_isSearchVisible) _buildSearchBar(),
        if (_activeTab == 0) ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _buildCategoryChip(index),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildList(pointsState, filtered, visible),
          ),
        ] else ...[
          Expanded(child: _buildMapView()),
        ],
      ],
    );
  }

  Widget _buildList(PointsState state, List<Point> filtered, List<Point> visible) {
    if (state.isLoading && state.points.isEmpty) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => const OfferCardSkeleton(),
      );
    }
    if (state.error != null && state.points.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Не удалось загрузить',
        description: 'Проверьте подключение и попробуйте ещё раз.',
        actionLabel: 'Повторить',
        onAction: _refresh,
      );
    }
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            EmptyState(
              icon: Icons.search_off,
              title: 'Ничего не найдено',
              description: 'Попробуйте изменить запрос или категорию.',
            ),
          ],
        ),
      );
    }
    final hasMore = visible.length < filtered.length;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visible.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            // элемент-кнопка "Показать ещё"
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _visibleCount += _pageSize),
                  child: const Text('Показать ещё'),
                ),
              ),
            );
          }
          final point = visible[index];
          return _OfferCard(
            point: point,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product',
                arguments: {'point': point},
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Для вас',
            iconPath: 'assets/icons/star.svg',
            isActive: _activeTab == 0,
            onTap: () => setState(() {
              _activeTab = 0;
              _isSearchVisible = false;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabButton(
            label: 'Карта',
            iconPath: 'assets/icons/nav.svg',
            isActive: _activeTab == 1,
            onTap: () => setState(() {
              _activeTab = 1;
              _isSearchVisible = false;
            }),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _nearMeLoading ? null : _toggleNearMe,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _nearMeEnabled ? const Color(0xFFE8FADC) : Colors.white,
              border: Border.all(color: AppColors.darkGreen, width: 1.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _nearMeLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.darkGreen,
                      ),
                    )
                  : const Icon(
                      Icons.near_me_outlined,
                      color: AppColors.darkGreen,
                      size: 20,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _isSearchVisible = !_isSearchVisible),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isSearchVisible ? const Color(0xFFE8FADC) : Colors.white,
              border: Border.all(color: AppColors.darkGreen, width: 1.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/search.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.darkGreen, width: 1.2),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Поиск точек...',
            prefixIcon:
                Icon(Icons.search, color: AppColors.darkGreen, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) => setState(() {
            _searchQuery = value;
            _visibleCount = _pageSize;
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index) {
    final isSelected = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = index;
        _visibleCount = _pageSize;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          _categories[index],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: PointsMap(radiusM: 5000),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8FADC) : Colors.white,
          border: Border.all(color: AppColors.darkGreen, width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Point point;
  final VoidCallback? onTap;

  const _OfferCard({required this.point, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.store, size: 40, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                point.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Color(0xFFFFB800), size: 15),
                            Text(
                              ' ${point.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Colors.black54),
                          const SizedBox(width: 3),
                          Text(
                            point.workingHours,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                point.address,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (point.distanceLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FADC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk,
                                  size: 12, color: AppColors.darkGreen),
                              const SizedBox(width: 3),
                              Text(
                                point.distanceLabel!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Карточка точки продаж ─────────────────────────────────────────────────────

class _PointCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _PointCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение с логотипом
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    data['image'] ?? '',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFE8FADC),
                      child: const Icon(Icons.store,
                          size: 48, color: AppColors.darkGreen),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          data['logo'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store, color: AppColors.darkGreen),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Инфо
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star,
                              color: Color(0xFFFFB800), size: 15),
                          Text(
                            ' ${data['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 13, color: Colors.black54),
                          const SizedBox(width: 3),
                          Text(
                            data['time'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Пакет с количеством
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.darkGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                data['count'] ?? '1',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['distance'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      // Цены
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                data['oldPrice'] ?? '',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF8E8E8E),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.darkGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['price'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
