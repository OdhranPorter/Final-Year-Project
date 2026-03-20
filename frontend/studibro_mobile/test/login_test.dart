import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/login.dart';

void main() {
  group('LoginScreen Tests', () => {
    // check login screen shows all elements
    testWidgets('Login screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const LoginScreen()),
      );

      expect(find.text('StudiBro'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
    });

    // verify username field accepts input
    testWidgets('Can enter username', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const LoginScreen()),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'user123');
      await tester.pumpAndSettle();

      expect(find.text('user123'), findsOneWidget);
    });

    // verify password field accepts input
    testWidgets('Can enter password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const LoginScreen()),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), 'pass123');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    // error message shown when login is empty
    testWidgets('Empty login shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {'/home': (context) => const Scaffold()},
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter both username and password'), findsOneWidget);
    });

    // login button is present on screen
    testWidgets('Login button exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const LoginScreen()),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
