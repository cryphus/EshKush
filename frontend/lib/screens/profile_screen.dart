import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/colors.dart';
import '../theme/decorations.dart';
import '../widgets/skeleton.dart';
import 'all_orders_screen.dart';
import 'notifications_screen.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        ref.read(profileProvider.notifier).load();
        ref.read(notificationsProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (!auth.isAuthenticated || auth.isGuest) {
      return const _GuestProfileBlock();
    }

    if (profileState.isLoading && profile == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 4),
          Text(
            'Ваш вклад:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: StatCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: StatCardSkeleton()),
            ],
          ),
        ],
      );
    }

    if (profileState.error != null && profile == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Не удалось загрузить профиль'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(profileProvider.notifier).load(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final money = profile?.savedMoney ?? 0.0;
    final buys = profile?.countBuy ?? 0;
    final co2 = profile?.sumCO2 ?? 0;

    final user = auth.user;

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ProfileHeader(
            displayName: profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : (user?.username ?? ''),
            avatarUrl: profile?.avatarUrl,
            bio: profile?.bio,
            user: user,
          ),
          const SizedBox(height: 20),
          const Text(
            'Ваш вклад:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  iconPath: 'assets/icons/profile1.svg',
                  value: '${money.toStringAsFixed(0)}₽',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  iconPath: 'assets/icons/profile2.svg',
                  value: '$buys',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  iconPath: 'assets/icons/profile3.svg',
                  value: '$co2 кг',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Настройки',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.receipt_long_outlined,
                label: 'Мои заказы',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllOrdersScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.notifications_none_outlined,
                label: 'Уведомления',
                badgeCount: ref.watch(notificationsProvider).unreadCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              _SettingsRow(
                icon: Icons.info_outline,
                label: 'О приложении',
                onTap: () => _showAboutSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.logout,
                label: 'Выйти из аккаунта',
                labelColor: const Color(0xFFD32F2F),
                iconColor: const Color(0xFFD32F2F),
                showChevron: false,
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вам нужно будет войти заново, чтобы продолжить пользоваться приложением.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EshKush',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Приложение для спасения еды: покупайте у партнёров '
                'излишки со скидкой и помогайте сокращать пищевые отходы.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Версия 1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestProfileBlock extends StatelessWidget {
  const _GuestProfileBlock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Вы вошли как гость',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String iconPath;
  final String value;

  const _StatCard({required this.iconPath, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FADC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(AppColors.darkGreen, BlendMode.srcIn),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка профиля: аватар, имя, роль (если не обычный пользователь),
/// контактные данные (телефон/почта) и краткое «о себе».
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final User? user;

  const _ProfileHeader({
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.user,
  });

  String get _initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String? get _roleLabel {
    switch (user?.role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.partner:
        return 'Партнёр';
      case UserRole.support:
        return 'Поддержка';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _roleLabel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Container(
                      color: AppColors.veryLightGray,
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    )
                  : Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.veryLightGray,
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (role != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                if (user?.email.isNotEmpty == true)
                  _ContactLine(icon: Icons.mail_outline, text: user!.email),
                if (user?.number.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  _ContactLine(icon: Icons.phone_outlined, text: user!.number),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Белая карточка-группа строк настроек (со встроенными разделителями).
class _SettingsGroup extends StatelessWidget {
  final List<_SettingsRow> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 52, color: Color(0xFFF0EEE7)),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;
  final int badgeCount;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.darkGreen),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? Colors.black87,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron) const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
