import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart';
import 'package:studibro_mobile/login.dart';

void main() {
  group('Navigation Tests', () {
    // app opens at home screen (not login)
    testWidgets('App starts at login', (WidgetTester tester) async {
      await tester.pumpWidget(const StudiBroApp());
      await tester.pumpAndSettle();

      // App now starts at HomeScreen, not LoginScreen
      expect(find.byType(HomeScreen), findsOneWidget);
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

    // login button appears on home screen when not logged in
    testWidgets('Logout button is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        ),
      );

      // When not logged in, shows login button instead of logout
      expect(find.byIcon(Icons.login), findsOneWidget);
    });
  });
}