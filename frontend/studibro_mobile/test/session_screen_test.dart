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

    // Image mode: Scan button exists
    testWidgets('Image mode: Scan button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: true,
            title: 'Image Test',
          ),
        ),
      );

      expect(find.text('SCAN'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    // Image mode: Gallery button exists
    testWidgets('Image mode: Gallery button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: true,
            title: 'Image Test',
          ),
        ),
      );

      expect(find.text('GALLERY'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    // Text mode: Scan and Gallery buttons don't exist
    testWidgets('Text mode: Scan and Gallery buttons not present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Text Test',
          ),
        ),
      );

      expect(find.text('SCAN'), findsNothing);
      expect(find.text('GALLERY'), findsNothing);
    });

    // Generate Summary button is disabled during extraction
    testWidgets('Generate Summary button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionScreen(
            isImageMode: false,
            title: 'Test',
          ),
        ),
      );

      // Find the Generate Summary button by icon
      expect(find.byIcon(Icons.stars_outlined), findsOneWidget);
    });
  });
}
