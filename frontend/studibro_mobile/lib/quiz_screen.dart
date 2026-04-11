import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final int quizId;
  final String sessionTitle;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.sessionTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final String backendUrl = 'http://192.168.0.8:8000/api';
  
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool quizCompleted = false;
  String? selectedAnswer;
  bool answerSubmitted = false;

  @override
  void initState() {
    super.initState();
    // In a real app, you'd fetch quiz details from backend
    // For now, we're assuming questions are passed or we fetch them
    _loadQuizQuestions();
  }

  Future<void> _loadQuizQuestions() async {
    // This would normally fetch from backend
    // For demo, we'll use mock data
    setState(() {
      isLoading = false;
      // Mock questions - in real app these come from backend
      questions = [
        {
          'id': 1,
          'question': 'What is photosynthesis?',
          'options': [
            'Process by which plants convert sunlight to energy',
            'Process of breaking down sugar for energy',
            'Process of making light from energy',
            'Process of filtering water'
          ],
          'correct_answer': 'Process by which plants convert sunlight to energy'
        },
        {
          'id': 2,
          'question': 'What is the powerhouse of the cell?',
          'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
          'correct_answer': 'Mitochondria'
        },
      ];
    });
  }

  void _selectAnswer(String answer) {
    if (!answerSubmitted) {
      setState(() {
        selectedAnswer = answer;
      });
    }
  }

  void _submitAnswer() {
    if (selectedAnswer == null) return;

    bool isCorrect =
        selectedAnswer == questions[currentQuestionIndex]['correct_answer'];

    if (isCorrect) {
      score++;
    }

    setState(() {
      answerSubmitted = true;
    });

    // Save answer to backend
    _saveAnswerToBackend(isCorrect);
  }

  Future<void> _saveAnswerToBackend(bool isCorrect) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/answers/save/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'quiz_id': widget.quizId,
          'question_id': questions[currentQuestionIndex]['id'],
          'user_response': selectedAnswer,
          'is_correct': isCorrect,
        }),
      );
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        answerSubmitted = false;
      });
    } else {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    // Save final score to backend
    try {
      await http.post(
        Uri.parse('$backendUrl/quizzes/save/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'quiz_id': widget.quizId,
          'score': score,
          'total_questions': questions.length,
        }),
      );
    } catch (e) {
      print('Error saving quiz result: $e');
    }

    setState(() {
      quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Loading...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (quizCompleted) {
      return _buildQuizCompletedScreen();
    }

    return _buildQuizQuestionScreen();
  }

  Widget _buildQuizQuestionScreen() {
    final currentQuestion = questions[currentQuestionIndex];
    final percentage =
        ((currentQuestionIndex + 1) / questions.length * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1}/${questions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Score: $score/${questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Text(
              currentQuestion['question'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion['options'].length,
                itemBuilder: (context, index) {
                  final option = currentQuestion['options'][index];
                  final isSelected = option == selectedAnswer;
                  final isCorrect =
                      option == currentQuestion['correct_answer'];

                  Color backgroundColor = Colors.white;
                  Color borderColor = Colors.grey[300]!;
                  Color textColor = Colors.black87;

                  if (answerSubmitted) {
                    if (isSelected && isCorrect) {
                      backgroundColor = Colors.green[50]!;
                      borderColor = Colors.green;
                      textColor = Colors.green[700]!;
                    } else if (isSelected && !isCorrect) {
                      backgroundColor = Colors.red[50]!;
                      borderColor = Colors.red;
                      textColor = Colors.red[700]!;
                    } else if (isCorrect) {
                      backgroundColor = Colors.green[50]!;
                      borderColor = Colors.green;
                      textColor = Colors.green[700]!;
                    }
                  } else if (isSelected) {
                    backgroundColor =
                        Theme.of(context).colorScheme.primary.withAlpha(25);
                    borderColor = Theme.of(context).colorScheme.primary;
                    textColor = Theme.of(context).colorScheme.primary;
                  }

                  return GestureDetector(
                    onTap: answerSubmitted
                        ? null
                        : () => _selectAnswer(option),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                              color: isSelected && !answerSubmitted
                                  ? Theme.of(context).colorScheme.primary
                                  : backgroundColor,
                            ),
                            child: answerSubmitted && isCorrect
                                ? Icon(Icons.check,
                                    size: 16, color: Colors.green[700])
                                : answerSubmitted && isSelected && !isCorrect
                                    ? Icon(Icons.close, size: 16, color: Colors.red[700])
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (answerSubmitted && isCorrect)
                            Icon(Icons.check_circle,
                                color: Colors.green[700], size: 24)
                          else if (answerSubmitted && isSelected && !isCorrect)
                            Icon(Icons.cancel, color: Colors.red[700], size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (!answerSubmitted)
              ElevatedButton.icon(
                onPressed: selectedAnswer != null ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'SUBMIT ANSWER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  currentQuestionIndex < questions.length - 1
                      ? 'NEXT QUESTION'
                      : 'FINISH QUIZ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCompletedScreen() {
    final percentage = (score / questions.length * 100).toInt();
    final performance = percentage >= 80
        ? 'Excellent!'
        : percentage >= 60
            ? 'Good Job!'
            : 'Keep Practicing!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Complete'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Celebration icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(25),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Score Display
              Text(
                'Quiz Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score / ${questions.length}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Performance Text
              Text(
                performance,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 80
                      ? Colors.green
                      : percentage >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 48),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Could implement retake quiz here
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.replay, color: Colors.white),
                      label: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
