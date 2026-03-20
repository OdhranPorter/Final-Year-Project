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

    // error shown when trying to generate with empty notes
    testWidgets('Empty notes shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.stars_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Notes are empty. Please scan or type text!'), findsOneWidget);
    });
  });
}
