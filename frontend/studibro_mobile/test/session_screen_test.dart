import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/session_screen.dart';

void main() {
  group('SessionScreen Tests', () {
    // session screen shows correct title
    testWidgets('SessionScreen displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test Mode',
          ),
        ),
      );

      expect(find.text('Test Mode'), findsOneWidget);
    });

    // text input field renders on screen
    testWidgets('Text field is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    // user can type text into field
    testWidgets('Can enter text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'My notes');
      await tester.pumpAndSettle();

      expect(find.text('My notes'), findsOneWidget);
    });

    // generate summary button is on screen
    testWidgets('Generate button exists', (WidgetTester tester) async {
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

    // results area shows initial placeholder text
    testWidgets('Results area displays placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      expect(find.text('Results will appear here'), findsOneWidget);
    });
  });
}
