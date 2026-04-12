import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart';
import 'package:studibro_mobile/session_screen.dart';

void main() {
  group('Integration Tests', () {
    // app launches successfully
    testWidgets('App boots without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const StudiBroApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    // user can type in session screen
    testWidgets('Can enter text in session screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'My notes here');
      await tester.pumpAndSettle();

      expect(find.text('My notes here'), findsOneWidget);
    });

    // generate button is present in session
    testWidgets('Generate button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      expect(find.byIcon(Icons.stars_outlined), findsOneWidget);
    });
  });
}
