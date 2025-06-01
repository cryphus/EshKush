import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Auth screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const EshKush());

    // Проверяем наличие полей ввода
    expect(find.byType(TextField), findsNWidgets(2));
    
    // Проверяем наличие кнопок
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
