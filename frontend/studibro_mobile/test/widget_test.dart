import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studibro_mobile/main.dart'; 

void main() {
  testWidgets('StudiBro App Load Test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    // This uses your actual class name: StudiBroApp
    await tester.pumpWidget(const StudiBroApp());

    // 2. Verify that the app actually loads a Material App.
    // This is a generic check that passes as long as your app starts.
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 3. Optional: Check for a specific piece of text you know is on your home screen
    // expect(find.text('Summarize'), findsOneWidget); 
  });
}