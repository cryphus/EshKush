import 'package:flutter/material.dart';

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветственный баннер
          _buildInfoBanner(),
          
          const SizedBox(height: 30),
          _buildHeader("Ваши заказы"),
          const SizedBox(height: 12),
          
          // Карточка заказа
          _buildOrderCard(),
          
          const SizedBox(height: 20),
          
          // Кнопка "Больше предложений"
          _buildActionButton("Больше предложений"),
          
          const SizedBox(height: 30),
          _buildHeader("Категории"),
          const SizedBox(height: 15),
          
          // Сетка категорий
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  "Магазины", 
                  const Color(0xFFE8FADC),
                  null, // Локальное изображение будет добавлено позже 
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildCategoryCard(
                  "Рестораны", 
                  const Color(0xFFE8FADC),
                  null, // Локальное изображение будет добавлено позже
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Заголовок секции с кнопкой "все"
  Widget _buildHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const Text(
          "все",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  // Верхний баннер
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FADC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Привет,\nГость",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Только в этом месяце\nты сохранил 2 кг еды!",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          // Изображение планеты и пакета
          const SizedBox(
            width: 100,
            height: 80,
            child: Placeholder(color: Colors.green), // Замените на Image.asset
          ),
        ],
      ),
    );
  }

  // Карточка текущего заказа
  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF76A571),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: Text("Лого", style: TextStyle(fontSize: 12))),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "БулоШная",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "сегодня, 19:00 - 21:00",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Широкая зеленая кнопка
  Widget _buildActionButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF98D377),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Карточка категории
  Widget _buildCategoryCard(String title, Color bgColor, String? imgUrl) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          // Изображение продуктов
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: imgUrl != null
                ? (imgUrl.startsWith('http')
                    ? Image.network(
                        imgUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 50),
                      )
                    : Image.asset(
                        imgUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 50),
                      ))
                : const Icon(Icons.fastfood, size: 50),
          ),
        ],
      ),
    );
  }
}