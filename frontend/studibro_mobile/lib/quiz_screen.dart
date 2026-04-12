import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'config.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String notes;
  final String title;
  final List<Map<String, dynamic>>? existingQuestions;

  const QuizScreen({
    super.key,
    required this.notes,
    required this.title,
    this.existingQuestions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool hasAnswered = false;
  int? selectedAnswerIndex;
  List<int?> userAnswers = [];
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    if (widget.existingQuestions != null && widget.existingQuestions!.isNotEmpty) {
      // Use existing questions from a retake
      _loadExistingQuestions();
    } else {
      // Generate new questions
      _generateQuiz();
    }
  }

  Future<void> _loadExistingQuestions() async {
    try {
      if (widget.existingQuestions == null || widget.existingQuestions!.isEmpty) {
        _showError('No questions available to retake');
        setState(() => isLoading = false);
        return;
      }

      // Convert existing questions to the format used by the app
      final formattedQuestions = <Map<String, dynamic>>[];
      
      for (var q in widget.existingQuestions!) {
        try {
          // Extract options text and find correct index
          final optionsList = q['options'] as List? ?? [];
          if (optionsList.isEmpty) {
            continue;
          }
          
          final optionsText = <String>[];
          for (var o in optionsList) {
            if (o is Map) {
              optionsText.add((o['option_text'] ?? '').toString());
            } else {
              optionsText.add(o.toString());
            }
          }
          
          // Find the correct answer index
          int correctIdx = 0;
          for (int i = 0; i < optionsList.length; i++) {
            if (optionsList[i] is Map && optionsList[i]['is_correct'] == true) {
              correctIdx = i;
              break;
            }
          }

          formattedQuestions.add({
            'question': q['question_text'] ?? '',
            'options': optionsText,
            'correct_index': correctIdx,
          });
        } catch (e) {
          // Skip malformed questions
          continue;
        }
      }

      if (formattedQuestions.isEmpty) {
        _showError('Failed to load quiz questions');
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        questions = formattedQuestions;
        currentQuestionIndex = 0;
        score = 0;
        hasAnswered = false;
        selectedAnswerIndex = null;
        userAnswers = List<int?>.filled(formattedQuestions.length, null);
        isLoading = false;
      });
    } catch (e) {
      _showError('Error loading quiz: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadUsername() async {
    const storage = FlutterSecureStorage();
    try {
      final user = await storage.read(key: 'username');
      if (mounted && user != null) {
        setState(() => username = user);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _generateQuiz() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showError('Not authenticated');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.generateQuizEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"text": widget.notes}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
          userAnswers = List<int?>.filled(questions.length, null);
          isLoading = false;
        });
      } else {
        _showError('Failed to generate quiz (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _selectAnswer(int index) {
    if (!hasAnswered && currentQuestionIndex < questions.length) {
      setState(() {
        selectedAnswerIndex = index;
        userAnswers[currentQuestionIndex] = index;
        hasAnswered = true;

        // Check if correct
        if (index == questions[currentQuestionIndex]['correct_index']) {
          score++;
        }
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedAnswerIndex = null;
      });
    } else {
      // Quiz complete - go to results
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QuizResultsScreen(
            score: score,
            totalQuestions: questions.length,
            questions: questions,
            userAnswers: userAnswers,
            notes: widget.notes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Loading Quiz..."),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Quiz"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text("Failed to load quiz questions"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (currentQuestionIndex >= questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Quiz"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text("Invalid quiz state"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quiz", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${currentQuestionIndex + 1} of ${questions.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Score: $score/${questions.length}",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentQuestion['question'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            ...List.generate(
              (currentQuestion['options'] as List).length,
              (index) {
                final option = currentQuestion['options'][index];
                final isCorrect = index == currentQuestion['correct_index'];
                final isSelected = selectedAnswerIndex == index;
                final showFeedback = hasAnswered;

                Color backgroundColor = Colors.white;
                Color borderColor = Colors.grey[300]!;
                Color textColor = Colors.black87;

                if (showFeedback) {
                  if (isCorrect) {
                    backgroundColor = Colors.green[100]!;
                    borderColor = Colors.green[500]!;
                    textColor = Colors.green[900]!;
                  } else if (isSelected) {
                    backgroundColor = Colors.red[100]!;
                    borderColor = Colors.red[500]!;
                    textColor = Colors.red[900]!;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    child: InkWell(
                      onTap: hasAnswered ? null : () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (showFeedback)
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Next button
            if (hasAnswered)
              ElevatedButton.icon(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  currentQuestionIndex == questions.length - 1
                      ? "View Results"
                      : "Next Question",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
