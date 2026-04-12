import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart';

void main() {
  group('HomeScreen Tests', () {
    // home screen shows studibro title
    testWidgets('Home screen displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      // Updated from "StudiBro Home" to "StudiBro"
      expect(find.text('StudiBro'), findsOneWidget);
    });

    // login button is visible on home screen when not logged in
    testWidgets('Home screen has logout button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      // When not logged in, shows login button
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    // scan card option shows on home
    testWidgets('Scan card is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      // Updated card title to match new implementation
      expect(find.text('Scan from Image'), findsOneWidget);
    });

    // paste card option shows on home
    testWidgets('Sign in prompt is displayed when not logged in', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      // When not logged in, a sign in prompt should be visible
      expect(find.text('Sign in to get started'), findsOneWidget);
    });

    // studibro branding displays on home screen
    testWidgets('Home screen shows StudiBro branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      expect(find.text('StudiBro'), findsOneWidget);
    });
  });
}
