import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/point.dart' as model;
import '../providers/nearby_points_provider.dart';
import '../theme/colors.dart';

/// Карта Yandex MapKit с маркерами ближайших точек.
/// Сама запрашивает геолокацию, затем нагружает [nearbyPointsProvider].
/// При тапе по маркеру вызывает [onPointTap] (если передано) — иначе
/// показывает bottom sheet с превью точки.
class PointsMap extends ConsumerStatefulWidget {
  final double radiusM;
  final ValueChanged<model.Point>? onPointTap;

  const PointsMap({
    super.key,
    this.radiusM = 5000,
    this.onPointTap,
  });

  @override
  ConsumerState<PointsMap> createState() => _PointsMapState();
}

class _PointsMapState extends ConsumerState<PointsMap> {
  YandexMapController? _controller;
  Position? _position;
  String? _error;
  bool _initializing = true;

  BitmapDescriptor? _pointIcon;
  BitmapDescriptor? _userIcon;

  // Fallback: Москва — центр, если геолокация недоступна.
  static const _fallback = Point(latitude: 55.751244, longitude: 37.618423);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _pointIcon ??= await _makePin(AppColors.accentGreen, Colors.white);
      _userIcon ??= await _makePin(Colors.blue, Colors.white);

      final pos = await _determinePosition();
      if (!mounted) return;
      setState(() {
        _position = pos;
        _initializing = false;
      });
      await _moveToUser();
    } catch (e) {
      if (!mounted) return;
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

  /// Программно рисуем простой пин: внешний круг [outer], внутренний [inner].
  /// Возвращает готовый BitmapDescriptor, который съест MapKit.
  Future<BitmapDescriptor> _makePin(Color outer, Color inner) async {
    const double size = 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Тень
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Внешний круг
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 6,
      Paint()..color = outer,
    );
    // Внутренний круг
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 5,
      Paint()..color = inner,
    );

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _moveToUser() async {
    final controller = _controller;
    if (controller == null) return;
    final p = _position;
    final lat = p?.latitude ?? _fallback.latitude;
    final lon = p?.longitude ?? _fallback.longitude;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: lat, longitude: lon),
          zoom: 14,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.6,
      ),
    );
  }

  NearbyQuery? get _query {
    final p = _position;
    if (p == null) return null;
    return NearbyQuery(
      lat: p.latitude,
      lon: p.longitude,
      radiusM: widget.radiusM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _position == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializing = true;
                    _error = null;
                  });
                  _bootstrap();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final query = _query;
    final nearbyAsync = query == null
        ? const AsyncValue<List<model.Point>>.data(<model.Point>[])
        : ref.watch(nearbyPointsProvider(query));

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: YandexMap(
            onMapCreated: (c) async {
              _controller = c;
              await _moveToUser();
            },
            mapObjects: _buildMapObjects(nearbyAsync.value ?? const []),
          ),
        ),
        if (nearbyAsync.isLoading)
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
        if (nearbyAsync.hasError)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapBadge(
              child: Text(
                'Не удалось загрузить точки: ${nearbyAsync.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 20,
          child: FloatingActionButton.small(
            heroTag: 'map-my-location',
            onPressed: _moveToUser,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.darkGreen,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  List<MapObject> _buildMapObjects(List<model.Point> points) {
    final objects = <MapObject>[];

    // Маркер пользователя
    final pos = _position;
    if (pos != null && _userIcon != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('user-location'),
          point: Point(latitude: pos.latitude, longitude: pos.longitude),
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(image: _userIcon!, scale: 1.0),
          ),
        ),
      );
    }

    // Маркеры точек
    if (_pointIcon != null) {
      for (final p in points) {
        objects.add(
          PlacemarkMapObject(
            mapId: MapObjectId('point-${p.id}'),
            point: Point(latitude: p.latitude, longitude: p.longitude),
            opacity: 1,
            onTap: (_, __) {
              if (widget.onPointTap != null) {
                widget.onPointTap!(p);
              } else {
                _showPointSheet(p);
              }
            },
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(image: _pointIcon!, scale: 1.0),
            ),
          ),
        );
      }
    }
    return objects;
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

class _PointPreview extends StatelessWidget {
  final model.Point point;
  const _PointPreview({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          SizedBox(
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
        ],
      ),
    );
  }
}
