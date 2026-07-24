import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../api/product_api_service.dart';
import '../models/point.dart' as model;
import '../models/product.dart';
import '../providers/points_provider.dart';
import '../theme/colors.dart';

/// Карта на движке OpenStreetMap (flutter_map) с маркерами ВСЕХ точек
/// (в выбранном городе — тот же набор, что и в списке «Для вас»). Одна
/// реализация для web и мобильных платформ. Сама запрашивает геолокацию
/// только чтобы отцентрировать карту и показать точку пользователя — на
/// набор маркеров расстояние не влияет: точка не может существовать без
/// отметки на карте. При тапе по маркеру вызывает [onPointTap] (если
/// передано) — иначе показывает bottom sheet с превью точки.
///
/// Тайлы — CartoDB Positron (light_all): бесплатные, без API-ключа, визуально
/// чище и спокойнее стандартных тайлов OSM (нужна атрибуция — см. [_MapAttribution]).
class PointsMap extends ConsumerStatefulWidget {
  final ValueChanged<model.Point>? onPointTap;

  const PointsMap({
    super.key,
    this.onPointTap,
  });

  @override
  ConsumerState<PointsMap> createState() => _PointsMapState();
}

class _PointsMapState extends ConsumerState<PointsMap> {
  final MapController _controller = MapController();
  Position? _position;
  String? _error;
  bool _initializing = true;

  // Fallback: Тюмень — центр, если геолокация недоступна.
  static const _fallback = ll.LatLng(57.1522, 65.5272);

  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final pos = await _determinePosition();
      if (!mounted) return;
      setState(() {
        _position = pos;
        _initializing = false;
      });
      _moveToUser();
    } catch (e) {
      if (!mounted) return;
      if (kIsWeb) {
        // В браузере показываем карту с fallback-центром даже без геолокации.
        setState(() => _initializing = false);
        return;
      }
      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Геолокация выключена. Включите её в настройках.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Доступ к геолокации не предоставлен.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Доступ к геолокации заблокирован. '
          'Откройте настройки и разрешите доступ.';
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  void _moveToUser() {
    final p = _position;
    final target = p != null ? ll.LatLng(p.latitude, p.longitude) : _fallback;
    _controller.move(target, 14);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    // Точки на карте не зависят от геолокации — она нужна только чтобы
    // отцентрировать карту и показать точку пользователя. Даже если
    // геолокация недоступна, все точки всё равно должны быть на карте.
    final pointsState = ref.watch(pointsProvider);
    if (pointsState.points.isEmpty && !pointsState.isLoading) {
      Future.microtask(() => ref.read(pointsProvider.notifier).loadAll());
    }
    final points = pointsState.points;
    final userPos = _position;
    final center = userPos != null
        ? ll.LatLng(userPos.latitude, userPos.longitude)
        : _fallback;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _tileSubdomains,
                userAgentPackageName: 'com.eshkush.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  if (userPos != null)
                    Marker(
                      point: ll.LatLng(userPos.latitude, userPos.longitude),
                      width: 22,
                      height: 22,
                      child: const _UserDot(),
                    ),
                  for (final p in points)
                    Marker(
                      point: ll.LatLng(p.latitude, p.longitude),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: _PointPin(
                        onTap: () => widget.onPointTap != null
                            ? widget.onPointTap!(p)
                            : _showPointSheet(p),
                      ),
                    ),
                ],
              ),
              const _MapAttribution(),
            ],
          ),
        ),
        if (pointsState.isLoading)
          const Positioned(
            top: 12,
            right: 12,
            child: _MapBadge(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (pointsState.error != null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapBadge(
              child: Text(
                'Не удалось загрузить точки: ${pointsState.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        else if (_error != null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapBadge(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  void _showPointSheet(model.Point point) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PointPreview(point: point),
    );
  }
}

/// Атрибуция карты — обязательна по условиям использования бесплатных
/// тайлов OpenStreetMap/CARTO.
class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors © CARTO',
          onTap: () {},
        ),
      ],
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _PointPin extends StatelessWidget {
  final VoidCallback onTap;
  const _PointPin({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront,
              size: 14,
              color: Colors.white,
            ),
          ),
          const CustomPaint(
            size: Size(8, 6),
            painter: _TrianglePainter(AppColors.accentGreen),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _MapBadge extends StatelessWidget {
  final Widget child;
  const _MapBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PointPreview extends StatefulWidget {
  final model.Point point;
  const _PointPreview({required this.point});

  @override
  State<_PointPreview> createState() => _PointPreviewState();
}

class _PointPreviewState extends State<_PointPreview> {
  final _productsApi = ProductApiService();
  bool _isLoading = true;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productsApi.getProductsByPoint(widget.point.id);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    point.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, size: 40, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  point.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(point.rating.toStringAsFixed(1)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(point.workingHours),
                    ]),
                    if (point.distanceLabel != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.directions_walk,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(point.distanceLabel!),
                      ]),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Что продают',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Пока нет доступных позиций', style: TextStyle(color: Colors.black54)),
            )
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _ProductMiniCard(product: _products[index]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/product',
                    arguments: {'point': point},
                  );
                },
                child: const Text(
                  'ПОДРОБНЕЕ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  final Product product;
  const _ProductMiniCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final outOfStock = !product.isPurchasable;
    return Opacity(
      opacity: outOfStock ? 0.55 : 1.0,
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: product.imageUrl == null
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, color: Colors.grey, size: 18),
                      )
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        color: outOfStock ? Colors.grey.shade400 : null,
                        colorBlendMode: outOfStock ? BlendMode.saturation : null,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey, size: 18),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    outOfStock ? 'Раскуплено' : '${product.price.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: outOfStock ? Colors.black45 : AppColors.darkGreen,
                    ),
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
