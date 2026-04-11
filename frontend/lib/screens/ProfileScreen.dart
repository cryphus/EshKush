import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/colors.dart';
import '../widgets/skeleton.dart';

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

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (profile != null) ...[
            Text(
              profile.fullName.isEmpty ? auth.user?.username ?? '' : profile.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
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
        ],
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
