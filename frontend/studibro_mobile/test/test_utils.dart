import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test utilities for StudiBro app tests
class TestUtils {
  /// Creates a basic MaterialApp wrapper for testing
  static Widget createTestApp({
    required Widget home,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      home: home,
      routes: routes ?? {},
      debugShowCheckedModeBanner: false,
    );
  }

  /// Helper to find a specific Button by text
  static Finder findButton(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// Helper to find a specific TextField by label
  static Finder findTextField(String labelText) {
    return find.ancestor(
      of: find.text(labelText),
      matching: find.byType(TextField),
    );
  }

  /// Helper to tap a button by text
  static Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(ElevatedButton, text));
    await tester.pumpAndSettle();
  }

  /// Helper to enter text safely
  static Future<void> enterTextSafely(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Helper to verify snackbar message
  static void verifySnackbarMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Helper to verify widget is visible
  static void verifyWidgetVisible(Finder finder) {
    expect(finder, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Visibility && widget.visible == false,
      ),
      findsNothing,
    );
  }

  /// Helper to scroll to widget
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Helper to verify page transition
  static void verifyNavigatedTo(Type pageType) {
    expect(find.byType(pageType), findsOneWidget);
  }

  /// Helper to clear text field
  static Future<void> clearTextField(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.enterText(finder, '');
    await tester.pumpAndSettle();
  }

  /// Helper to check if button is enabled
  static bool isButtonEnabled(WidgetTester tester, String buttonText) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, buttonText),
    );
    return button.onPressed != null;
  }
}
