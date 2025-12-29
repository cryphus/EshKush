import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/layouts/scaffold_layout.dart';
import '../../theme/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  void _handleNavItemTap(int index) => setState(() => _currentNavIndex = index);

  Widget _buildContent() {
    return Column(
      children: [
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }
}

Widget _buildActionButtons() {
  final actions = [
    {
      'title': '199р',
      'icon': 'icons/profile1.svg',
    },
    {
      'title': '1',
      'icon': 'icons/profile2.svg',
    },
    {
      'title': '0.2 кг',
      'icon': 'icons/profile3.svg',
    },
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: actions
        .map((action) => _ActionButton(
              text: action['title']!,
              iconPath: action['icon']!,
            ))
        .toList(),
  );
}

class _ActionButton extends StatelessWidget {
  final String text;
  final String iconPath;

  const _ActionButton({
    required this.text,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.darkGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            color: AppColors.darkGreen,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}
