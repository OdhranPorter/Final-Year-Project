import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'quiz_screen.dart';

class QuizzesHistoryScreen extends StatefulWidget {
  const QuizzesHistoryScreen({super.key});

  @override
  State<QuizzesHistoryScreen> createState() => _QuizzesHistoryScreenState();
}

class _QuizzesHistoryScreenState extends State<QuizzesHistoryScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _quizzes = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchQuizHistory();
  }

  Future<void> _fetchQuizHistory() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Not authenticated. Please login first.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.quizzesHistoryEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () => throw 'Request timeout',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quizzes = data['quizzes'] ?? [];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load quiz history (Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          _fetchQuizHistory();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _quizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes completed yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a quiz to see your history',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchQuizHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _quizzes[index];
                          final percentage = quiz['percentage'] ?? 0;
                          final score = quiz['score'] ?? 0;
                          final totalQuestions = quiz['total_questions'] ?? 0;
                          final createdAt = quiz['created_at'] ?? '';
                          
                          // Determine color based on performance
                          Color performanceColor = Colors.red;
                          String performanceMessage = 'Needs Improvement';
                          if (percentage >= 80) {
                            performanceColor = Colors.green;
                            performanceMessage = 'Excellent!';
                          } else if (percentage >= 60) {
                            performanceColor = Colors.orange;
                            performanceMessage = 'Good Job!';
                          }
                          
                          // Format date
                          String formattedDate = 'Unknown Date';
                          try {
                            final dateTime = DateTime.parse(createdAt);
                            formattedDate =
                                '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                          } catch (e) {
                            // Keep default
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                _showQuizDetails(context, quiz);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Quiz ${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: performanceColor
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${percentage.toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: performanceColor,
                                                ),
                                              ),
                                              Text(
                                                performanceMessage,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: performanceColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Score: $score / $totalQuestions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showQuizDetails(BuildContext context, dynamic quiz) {
    final questions = quiz['questions'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quiz Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Score',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${quiz['score']} / ${quiz['total_questions']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Percentage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(quiz['percentage'] as num).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (questions.isNotEmpty) ...[
                  Text(
                    'Questions Review',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final questionText = question['question_text'] ?? '';
                      final correctAnswer = question['correct_answer'] ?? '0';
                      final options = question['options'] as List<dynamic>? ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${index + 1}: $questionText',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(
                                options.length,
                                (optIndex) {
                                  final option = options[optIndex];
                                  final optionText = option['option_text'] ?? '';
                                  final isCorrect = option['is_correct'] ?? false;
                                  final backgroundColor = isCorrect
                                      ? Colors.green[50]
                                      : Colors.grey[50];
                                  final borderColor =
                                      isCorrect ? Colors.green : Colors.grey[300];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      border: Border.all(color: borderColor!),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isCorrect)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          )
                                        else
                                          Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.grey[400],
                                            size: 18,
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            optionText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCorrect
                                                  ? Colors.green[700]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        if (isCorrect)
                                          Text(
                                            'Correct',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final originalText = quiz['original_text'] ?? '';
                          final quizQuestions = quiz['questions'] as List<dynamic>? ?? [];
                          if (quizQuestions.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  title: 'Retake Quiz',
                                  notes: originalText,
                                  existingQuestions: List<Map<String, dynamic>>.from(quizQuestions),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot retake quiz - questions not available'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Retake Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Close',
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
      ),
    );
  }
}
