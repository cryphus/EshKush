import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../models/point.dart';
import '../models/product_offer.dart';
import '../providers/city_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/points_provider.dart';
import '../providers/product_feed_provider.dart';
import '../theme/colors.dart';
import '../theme/decorations.dart';
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
      _loadPoints();
      ref.read(favoritesProvider.notifier).load();
    });
  }

  void _loadPoints() {
    final city = ref.read(selectedCityProvider);
    ref.read(pointsProvider.notifier).loadAll(cityId: city?.id);
    ref.read(productFeedProvider.notifier).loadAll(cityId: city?.id);
  }

  Future<void> _refresh() async {
    setState(() => _visibleCount = _pageSize);
    final city = ref.read(selectedCityProvider);
    await Future.wait([
      ref.read(pointsProvider.notifier).loadAll(cityId: city?.id),
      ref.read(productFeedProvider.notifier).loadAll(cityId: city?.id),
    ]);
  }

  List<ProductOffer> _filter(List<ProductOffer> offers) {
    Iterable<ProductOffer> result = offers;

    if (_selectedCategory > 0) {
      final tag = _categories[_selectedCategory].toLowerCase();
      result = result.where((o) {
        final p = o.point;
        // ищем в названии точки, названии товара и в тегах точки (значениях/ключах)
        if (p.name.toLowerCase().contains(tag.substring(0, tag.length - 1)) ||
            o.product.name.toLowerCase().contains(tag.substring(0, tag.length - 1))) {
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
      result = result.where((o) =>
          o.point.name.toLowerCase().contains(q) ||
          o.point.address.toLowerCase().contains(q) ||
          o.product.name.toLowerCase().contains(q));
    }

    // "Рядом": добавляем distanceM точке и сортируем по возрастанию расстояния.
    if (_nearMeEnabled && _userLat != null && _userLon != null) {
      final enriched = result.map((o) {
        final p = o.point;
        final d = _haversineM(_userLat!, _userLon!, p.latitude, p.longitude);
        return ProductOffer(
          product: o.product,
          point: Point(
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
            imageUrl: p.imageUrl,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            distanceM: d,
          ),
        );
      }).toList()
        ..sort((a, b) => (a.point.distanceM ?? 0).compareTo(b.point.distanceM ?? 0));
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
    // Смена города — перезагружаем точки/предложения с фильтром по city_id.
    ref.listen(selectedCityProvider, (prev, next) {
      if (prev?.id != next?.id) {
        setState(() => _visibleCount = _pageSize);
        ref.read(pointsProvider.notifier).loadAll(cityId: next?.id);
        ref.read(productFeedProvider.notifier).loadAll(cityId: next?.id);
      }
    });

    final feedState = ref.watch(productFeedProvider);
    final filtered = _filter(feedState.offers);
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
            child: _buildList(feedState, filtered, visible),
          ),
        ] else ...[
          Expanded(child: _buildMapView()),
        ],
      ],
    );
  }

  Widget _buildList(
      ProductFeedState state, List<ProductOffer> filtered, List<ProductOffer> visible) {
    if (state.isLoading && state.offers.isEmpty) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => const OfferCardSkeleton(),
      );
    }
    if (state.error != null && state.offers.isEmpty) {
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
          final offer = visible[index];
          return _ProductOfferCard(
            offer: offer,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product-detail',
                arguments: {'product': offer.product, 'point': offer.point},
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
              color: _nearMeEnabled ? AppColors.veryLightGray : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.subtle,
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
              color: _isSearchVisible ? AppColors.veryLightGray : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.subtle,
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
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          boxShadow: AppShadows.subtle,
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Поиск точек...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? AppShadows.soft(alpha: 0.16, blur: 12, offset: const Offset(0, 4))
              : AppShadows.subtle,
        ),
        child: Text(
          _categories[index],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: PointsMap(),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? AppShadows.soft(alpha: 0.16, blur: 14, offset: const Offset(0, 5))
              : AppShadows.subtle,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isActive ? Colors.white : AppColors.darkGreen,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.darkGreen,
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

class _ProductOfferCard extends ConsumerWidget {
  final ProductOffer offer;
  final VoidCallback? onTap;

  const _ProductOfferCard({required this.offer, this.onTap});

  Point get point => offer.point;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, bool isFav) async {
    try {
      if (isFav) {
        await ref.read(favoritesProvider.notifier).remove(point.id);
        showSnack('Удалено из избранного', kind: SnackKind.info);
      } else {
        await ref.read(favoritesProvider.notifier).add(point);
        showSnack('Добавлено в избранное', kind: SnackKind.success);
      }
    } catch (e) {
      showApiError(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).favorites.any((f) => f.id == point.id);
    final product = offer.product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      point.photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : Container(color: Colors.grey.shade100),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.store, size: 40, color: Colors.grey),
                      ),
                    ),
                    // Мягкое затемнение снизу для читаемости чипа времени самовывоза.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.38),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(context, ref, isFav),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.subtle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.black45,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _Pill(
                        color: Colors.white,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              point.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (product.pickupWindowLabel != null)
                      Positioned(
                        left: 12,
                        bottom: 10,
                        right: 12,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              product.pickupWindowLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Бейдж пакета — количество ПОЗИЦИЙ внутри бокса
                      // (например "суп, второе, компот" = 3), а не остаток
                      // на складе — тот учитывается только для лимита корзины.
                      SizedBox(
                        width: 26,
                        height: 29,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/bag_offer.svg',
                              width: 26,
                              height: 29,
                            ),
                            Align(
                              alignment: const Alignment(0, 0.25),
                              child: Text(
                                '${product.itemsCount}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (point.distanceLabel != null)
                        Expanded(
                          child: Text(
                            point.distanceLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            point.address,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ),
                      if (product.hasDiscount) ...[
                        Text(
                          '${product.originalPrice!.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.price.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

/// Мини-таблетка (пилюля) с тенью — используется для рейтинга/дистанции
/// поверх фото заведения.
class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.subtle,
      ),
      child: child,
    );
  }
}
