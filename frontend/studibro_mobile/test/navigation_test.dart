import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart';
import 'package:studibro_mobile/login.dart';

void main() {
  group('Navigation Tests', () {
    // app opens at login screen
    testWidgets('App starts at login', (WidgetTester tester) async {
      await tester.pumpWidget(const StudiBroApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // user can enter credentials
    testWidgets('Can enter username and password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {'/home': (context) => const HomeScreen()},
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'user1');
      await tester.enterText(textFields.at(1), 'pass1');
      await tester.pumpAndSettle();

      expect(find.text('user1'), findsOneWidget);
    });

    // logout button navigates to login
    testWidgets('Logout button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}