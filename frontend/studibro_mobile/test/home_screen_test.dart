import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart';

void main() {
  group('HomeScreen Tests', () {
    // home screen shows studibro home title
    testWidgets('Home screen displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      expect(find.text('StudiBro Home'), findsOneWidget);
    });

    // logout button is visible on home screen
    testWidgets('Home screen has logout button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    // scan card option shows on home
    testWidgets('Scan card is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      expect(find.text('Scan (Image/OCR)'), findsOneWidget);
    });

    // paste card option shows on home
    testWidgets('Paste card is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {'/login': (context) => const Scaffold()},
        ),
      );

      expect(find.text('Paste (Manual Text)'), findsOneWidget);
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
