import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'config.dart';

class QuizResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> questions;
  final List<int?> userAnswers;
  final String notes;
  final String? subjectClass;  // Class/subject for the quiz
  final String? year;  // Year for the quiz

  const QuizResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
    required this.notes,
    this.subjectClass,
    this.year,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  bool isSaving = false;
  bool hasSaved = false;

  Future<void> _saveResults() async {
    setState(() => isSaving = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showError('Not authenticated');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.saveQuizEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "score": widget.score,
          "total_questions": widget.totalQuestions,
          "questions": widget.questions,
          "original_text": widget.notes,
          "subject_class": widget.subjectClass ?? '',
          "year": widget.year ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        setState(() => hasSaved = true);
        _showSuccess('Quiz results saved!');
      } else {
        _showError('Failed to save results (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quiz Complete!", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        percentage,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You scored",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.score} out of ${widget.totalQuestions}",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPerformanceColor(double.parse(percentage))[0],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getPerformanceColor(double.parse(percentage))[1],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPerformanceIcon(double.parse(percentage)),
                    color: _getPerformanceColor(double.parse(percentage))[1],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getPerformanceMessage(double.parse(percentage)),
                      style: TextStyle(
                        color: _getPerformanceColor(double.parse(percentage))[1],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question review
            Text(
              "Review Your Answers",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.questions.length, (index) {
              final question = widget.questions[index];
              final userAnswer = widget.userAnswers[index];
              final isCorrect = userAnswer == question['correct_index'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect ? Colors.green[100] : Colors.red[100],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question['question'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your answer: ${question['options'][userAnswer ?? 0]}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isCorrect ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Correct answer: ${question['options'][question['correct_index']]}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Save/Continue buttons
            ElevatedButton.icon(
              onPressed: isSaving || hasSaved ? null : _saveResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(hasSaved ? Icons.check : Icons.save, color: Colors.white),
              label: Text(
                hasSaved ? "Results Saved" : "Save Results",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.home),
              label: const Text(
                "Back to Home",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getPerformanceColor(double percentage) {
    if (percentage >= 80) {
      return [Colors.green[100]!, Colors.green[700]!];
    } else if (percentage >= 60) {
      return [Colors.orange[100]!, Colors.orange[700]!];
    } else {
      return [Colors.red[100]!, Colors.red[700]!];
    }
  }

  IconData _getPerformanceIcon(double percentage) {
    if (percentage >= 80) {
      return Icons.emoji_events;
    } else if (percentage >= 60) {
      return Icons.thumb_up;
    } else {
      return Icons.info;
    }
  }

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 80) {
      return "Excellent! You've mastered this material! 🎉";
    } else if (percentage >= 60) {
      return "Good job! Keep practicing to improve. 💪";
    } else {
      return "Room for improvement. Review and try again! 📚";
    }
  }
}
