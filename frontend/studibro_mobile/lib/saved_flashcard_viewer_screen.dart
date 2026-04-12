import 'package:flutter/material.dart';

class SavedFlashcardViewerScreen extends StatefulWidget {
  final Map<String, dynamic> flashcard;

  const SavedFlashcardViewerScreen({
    super.key,
    required this.flashcard,
  });

  @override
  State<SavedFlashcardViewerScreen> createState() =>
      _SavedFlashcardViewerScreenState();
}

class _SavedFlashcardViewerScreenState
    extends State<SavedFlashcardViewerScreen> {
  late List<Map<String, dynamic>> cards;
  int currentCardIndex = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    cards = List<Map<String, dynamic>>.from(
        widget.flashcard['cards'] ?? []);
  }

  void _nextCard() {
    if (currentCardIndex < cards.length - 1) {
      setState(() {
        currentCardIndex++;
        isFlipped = false;
      });
    }
  }

  void _previousCard() {
    if (currentCardIndex > 0) {
      setState(() {
        currentCardIndex--;
        isFlipped = false;
      });
    }
  }

  void _toggleFlip() {
    setState(() => isFlipped = !isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.flashcard['title'] ?? 'Flashcards',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: cards.isEmpty
          ? const Center(
              child: Text("No flashcards in this set"),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress
                  Text(
                    "Card ${currentCardIndex + 1} of ${cards.length}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (currentCardIndex + 1) / cards.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Flashcard
                  GestureDetector(
                    onTap: _toggleFlip,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: FlashcardWidget(
                        key: ValueKey(isFlipped),
                        question: cards[currentCardIndex]['question'] ?? '',
                        answer: cards[currentCardIndex]['answer'] ?? '',
                        isFlipped: isFlipped,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentCardIndex > 0 ? _previousCard : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Previous"),
                      ),
                      ElevatedButton.icon(
                        onPressed: currentCardIndex < cards.length - 1
                            ? _nextCard
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Next"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info
                  if (widget.flashcard['subject_class'] != null &&
                      widget.flashcard['subject_class']!.toString().isNotEmpty)
                    Text(
                      'Class: ${widget.flashcard['subject_class']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (widget.flashcard['year'] != null &&
                      widget.flashcard['year']!.toString().isNotEmpty)
                    Text(
                      'Year: ${widget.flashcard['year']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class FlashcardWidget extends StatelessWidget {
  final String question;
  final String answer;
  final bool isFlipped;

  const FlashcardWidget({
    super.key,
    required this.question,
    required this.answer,
    required this.isFlipped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isFlipped
              ? [
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ]
              : [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
        ),
        border: Border.all(
          color: isFlipped
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isFlipped ? "Answer" : "Question",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SingleChildScrollView(
              child: Text(
                isFlipped ? answer : question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ),
            Text(
              "Tap to flip",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
