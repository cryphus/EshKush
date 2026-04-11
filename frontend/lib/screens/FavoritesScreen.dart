import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point.dart';
import '../providers/favorites_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).load();
    });
  }

  Future<void> _refresh() => ref.read(favoritesProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);

    if (state.isLoading && state.favorites.isEmpty) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => const OfferCardSkeleton(),
      );
    }
    if (state.error != null && state.favorites.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Не удалось загрузить избранное',
        description: 'Проверьте подключение и попробуйте ещё раз.',
        actionLabel: 'Повторить',
        onAction: _refresh,
      );
    }
    if (state.favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            EmptyState(
              icon: Icons.favorite_border,
              title: 'Нет избранных заведений',
              description: 'Добавляйте сюда любимые места — они появятся в списке.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final point = state.favorites[index];
          return _FavoriteCard(
            point: point,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product',
                arguments: {'point': point},
              );
            },
            onRemove: () async {
              try {
                await ref.read(favoritesProvider.notifier).remove(point.id);
                showSnack('Удалено из избранного', kind: SnackKind.info);
              } catch (e) {
                showApiError(e);
              }
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Point point;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _FavoriteCard({required this.point, this.onTap, this.onRemove});

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
            Stack(
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
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
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Color(0xFFFFB800), size: 15),
                            Text(
                              ' ${point.rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
