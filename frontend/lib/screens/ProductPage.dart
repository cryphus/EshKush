import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/layouts/scaffold_layout.dart';

class ProductPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      pageTitle: data['name'] ?? 'Название не указано',
      bodyContent: _buildContent(),
      showNavBar: false,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildImageSection(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(),
                const SizedBox(height: 12),
                _buildRatingSection(),
                const SizedBox(height: 24),
                _buildAddressList(),
                const SizedBox(height: 24),
                _buildDescriptionSection(),
                const SizedBox(height: 32),
                _buildBuyButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Image.network(
          data['image'],
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: -24,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(50),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(data['logo']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Center(
        child: Text(
          data['name'],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 28),
        const SizedBox(width: 8),
        Text(
          data['rating']?.toString() ?? '0.0',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressList() {
    return Column(
      children: [
        _AddressInfoItem(
          icon: Icons.location_on_outlined,
          street: 'Адрес',
          address: data['address'] ?? 'Адрес не указан',
        ),
        _AddressInfoItem(
          icon: Icons.access_time_filled,
          street: 'Часы работы',
          address: data['working_hours'] ?? 'Не указаны',
        ),
        _AddressInfoItem(
          icon: Icons.phone,
          street: 'Телефон',
          address: data['phone'] ?? 'Не указан',
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data['description'] ?? 'Описание отсутствует',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBuyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Купить за',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data['price']?.toString() ?? '₽ 0',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressInfoItem extends StatelessWidget {
  final IconData icon;
  final String street;
  final String address;

  const _AddressInfoItem({
    required this.icon,
    required this.street,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.lightGreen, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 32, color: AppColors.lightGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  street,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
