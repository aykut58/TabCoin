import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapcoin/main.dart';
import 'package:tapcoin/pages/homepage.dart' show HomePage;
import 'package:tapcoin/pages/on_board.dart' show OnBoard;

void main() {
  testWidgets('App başlatılıyor ve onboarding ya da homepage gösteriliyor', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Başlangıçta CircularProgressIndicator olabilir (FutureBuilder bekliyor)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // FutureBuilder tamamlandıktan sonra ya OnBoard ya da HomePage gözükecek
    await tester.pumpAndSettle();

    // Ya OnBoard ya da HomePage widget'ından biri olmalı
    expect(find.byType(OnBoard).evaluate().isNotEmpty || find.byType(HomePage).evaluate().isNotEmpty, true);
  });
}
