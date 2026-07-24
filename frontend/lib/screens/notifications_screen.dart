import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_provider.dart';
import '../theme/colors.dart';
import '../theme/decorations.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Уведомления'),
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                        const SizedBox(height: 12),
                        const Text('Не удалось загрузить уведомления'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.read(notificationsProvider.notifier).load(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'Пока нет уведомлений',
                      description: 'Здесь будут акции и новости о ваших заказах.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(notificationsProvider.notifier).load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final n = state.notifications[index];
                          return GestureDetector(
                            onTap: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppShadows.subtle,
                                border: n.isUnread
                                    ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4))
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: n.isUnread ? AppColors.accentGreen : Colors.transparent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: n.isUnread ? FontWeight.w600 : FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(n.createdAt),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
