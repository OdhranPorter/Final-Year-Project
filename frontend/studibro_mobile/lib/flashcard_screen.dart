import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'config.dart';

class FlashcardScreen extends StatefulWidget {
  final String notes;
  final String title;
  final String? subjectClass;
  final String? year;

  const FlashcardScreen({
    super.key,
    required this.notes,
    required this.title,
    this.subjectClass,
    this.year,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Map<String, dynamic>> cards = [];
  int currentCardIndex = 0;
  bool isLoading = true;
  bool isFlipped = false;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _generateFlashcards();
  }

  Future<void> _loadUsername() async {
    const storage = FlutterSecureStorage();
    try {
      final name = await storage.read(key: 'username');
      if (mounted) {
        setState(() => username = name);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _generateFlashcards() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showError('Not authenticated');
        Navigator.of(context).pop();
        return;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.generateFlashcardsEndpoint),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "text": widget.notes,
              "title": widget.title,
              "subject_class": widget.subjectClass ?? '',
              "year": widget.year ?? '',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            cards = List<Map<String, dynamic>>.from(data['cards'] ?? []);
            isLoading = false;
          });
        }
      } else {
        _showError('Failed to generate flashcards (${response.statusCode})');
        if (mounted) {
          setState(() => isLoading = false);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
      if (mounted) {
        setState(() => isLoading = false);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveFlashcards() async {
    if (cards.isEmpty) {
      _showError('No flashcards to save');
      return;
    }

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showError('Not authenticated');
        return;
      }

      _showLoading('Saving flashcards...');

      final response = await http
          .post(
            Uri.parse(ApiConfig.saveFlashcardsEndpoint),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "title": widget.title,
              "cards": cards,
              "original_text": widget.notes,
              "subject_class": widget.subjectClass ?? '',
              "year": widget.year ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      Navigator.of(context).pop(); // Close the loading dialog

      if (response.statusCode == 201) {
        _showSuccess('Flashcards saved successfully!');
        // Navigate back after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showError('Failed to save flashcards (${response.statusCode})');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
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
        title: const Text("Flashcards", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Generating flashcards..."),
                ],
              ),
            )
          : cards.isEmpty
              ? const Center(
                  child: Text("No flashcards generated"),
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

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveFlashcards,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Flashcards"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
