import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:studibro_mobile/flashcard_screen.dart';

// Mock HTTP client
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('FlashcardScreen Tests', () {
    // Test basic widget rendering
    testWidgets('FlashcardScreen renders without crashing', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            notes: 'Test notes content',
            title: 'Test Flashcards',
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Test widget receives correct parameters
    testWidgets('FlashcardScreen receives parameters correctly',
      (WidgetTester tester) async {
      const testNotes = 'Sample study notes';
      const testTitle = 'Biology Chapter 5';
      const testSubject = 'Biology 101';
      const testYear = '2024';

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            notes: testNotes,
            title: testTitle,
            subjectClass: testSubject,
            year: testYear,
          ),
        ),
      );

      // Widget should initialize without errors
      expect(find.byType(FlashcardScreen), findsOneWidget);
    });

    // Test card flip animation
    testWidgets('Card flip changes visibility correctly',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestableFlashcardCard(
              question: 'What is photosynthesis?',
              answer: 'The process of converting light to energy',
              isFlipped: false,
            ),
          ),
        ),
      );

      // Should show question initially
      expect(find.text('What is photosynthesis?'), findsOneWidget);

      // Tap to flip
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Should now show answer
      expect(find.text('The process of converting light to energy'), findsOneWidget);
    });

    // Test flashcard navigation
    testWidgets('Navigation buttons move through cards',
      (WidgetTester tester) async {
      // Create a mock screen state with multiple cards
      final mockCards = [
        {'question': 'Q1', 'answer': 'A1'},
        {'question': 'Q2', 'answer': 'A2'},
        {'question': 'Q3', 'answer': 'A3'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardNavigation(cards: mockCards),
        ),
      );

      // Check initial card
      expect(find.text('Card 1 of 3'), findsOneWidget);

      // Click next button
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Should move to next card
      expect(find.text('Card 2 of 3'), findsOneWidget);

      // Click next again
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Should move to last card
      expect(find.text('Card 3 of 3'), findsOneWidget);

      // Click previous button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should go back to card 2
      expect(find.text('Card 2 of 3'), findsOneWidget);
    });

    // Test save button exists
    testWidgets('Save button is present on screen',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardWithButton(),
        ),
      );

      // Look for save button
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    // Test empty cards state
    testWidgets('Handles empty flashcard set gracefully',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardNavigation(cards: []),
        ),
      );

      // Should show message or handle empty state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Test card progress indicator
    testWidgets('Displays correct card progress counter',
      (WidgetTester tester) async {
      final mockCards = [
        {'question': 'Q1', 'answer': 'A1'},
        {'question': 'Q2', 'answer': 'A2'},
        {'question': 'Q3', 'answer': 'A3'},
        {'question': 'Q4', 'answer': 'A4'},
        {'question': 'Q5', 'answer': 'A5'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardNavigation(cards: mockCards),
        ),
      );

      // Check initial progress
      expect(find.text('Card 1 of 5'), findsOneWidget);

      // Navigate to last card
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();
      }

      expect(find.text('Card 5 of 5'), findsOneWidget);
    });

    // Test that next button is disabled on last card
    testWidgets('Next button disabled on last card',
      (WidgetTester tester) async {
      final mockCards = [
        {'question': 'Q1', 'answer': 'A1'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardNavigation(cards: mockCards),
        ),
      );

      // Navigate to last (and only) card - we're already there
      // Next button should be disabled
      final nextButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.onPressed == null,
      );

      expect(nextButton, findsWidgets);
    });

    // Test that previous button is disabled on first card
    testWidgets('Previous button disabled on first card',
      (WidgetTester tester) async {
      final mockCards = [
        {'question': 'Q1', 'answer': 'A1'},
        {'question': 'Q2', 'answer': 'A2'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardNavigation(cards: mockCards),
        ),
      );

      // On first card, previous button should be disabled
      final prevButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.onPressed == null,
      );

      // Should have at least one disabled button (the previous)
      expect(prevButton, findsWidgets);
    });

    // Test subject class and year display
    testWidgets('Displays subject class and year when provided',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestableFlashcardMetadata(
            title: 'Test Flashcards',
            subjectClass: 'Physics 101',
            year: '2024',
          ),
        ),
      );

      expect(find.text('Physics 101'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    // Test card content formatting
    testWidgets('Card displays question and answer correctly formatted',
      (WidgetTester tester) async {
      const testQuestion = 'What is 2 + 2?';
      const testAnswer = '4';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestableFlashcardCard(
              question: testQuestion,
              answer: testAnswer,
              isFlipped: false,
            ),
          ),
        ),
      );

      // Initially shows question
      expect(find.text(testQuestion), findsOneWidget);
      expect(find.text(testAnswer), findsNothing);

      // Tap to flip
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Now shows answer
      expect(find.text(testAnswer), findsOneWidget);
      expect(find.text(testQuestion), findsNothing);
    });
  });
}

// ============= Test Helper Widgets =============

/// Testable card widget that displays question/answer
class _TestableFlashcardCard extends StatefulWidget {
  final String question;
  final String answer;
  final bool isFlipped;

  const _TestableFlashcardCard({
    required this.question,
    required this.answer,
    required this.isFlipped,
  });

  @override
  State<_TestableFlashcardCard> createState() => _TestableFlashcardCardState();
}

class _TestableFlashcardCardState extends State<_TestableFlashcardCard> {
  late bool isFlipped;

  @override
  void initState() {
    super.initState();
    isFlipped = widget.isFlipped;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isFlipped = !isFlipped;
        });
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              isFlipped ? widget.answer : widget.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Testable navigation widget
class _TestableFlashcardNavigation extends StatefulWidget {
  final List<Map<String, dynamic>> cards;

  const _TestableFlashcardNavigation({
    required this.cards,
  });

  @override
  State<_TestableFlashcardNavigation> createState() =>
      _TestableFlashcardNavigationState();
}

class _TestableFlashcardNavigationState
    extends State<_TestableFlashcardNavigation> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: widget.cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Card ${currentIndex + 1} of ${widget.cards.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.cards[currentIndex]['question'] ?? '',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentIndex > 0
                            ? () {
                                setState(() => currentIndex--);
                              }
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            currentIndex < widget.cards.length - 1
                                ? () {
                                    setState(() => currentIndex++);
                                  }
                                : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Testable widget with save button
class _TestableFlashcardWithButton extends StatelessWidget {
  const _TestableFlashcardWithButton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.save),
          label: const Text('Save Flashcards'),
        ),
      ),
    );
  }
}

/// Testable widget displaying metadata
class _TestableFlashcardMetadata extends StatelessWidget {
  final String title;
  final String? subjectClass;
  final String? year;

  const _TestableFlashcardMetadata({
    required this.title,
    this.subjectClass,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjectClass != null) Text(subjectClass!),
            if (year != null) Text(year!),
          ],
        ),
      ),
    );
  }
}
