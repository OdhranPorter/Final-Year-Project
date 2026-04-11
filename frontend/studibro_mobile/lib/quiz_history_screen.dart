import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizHistoryScreen extends StatefulWidget {
  final int userId;

  const QuizHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final String backendUrl = 'http://192.168.0.8:8000/api';

  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> quizzes = [];
  bool isLoadingSessions = true;
  bool isLoadingQuizzes = true;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadQuizzes();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/sessions/?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          sessions = List<Map<String, dynamic>>.from(data);
          isLoadingSessions = false;
        });
      } else {
        setState(() => isLoadingSessions = false);
      }
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => isLoadingSessions = false);
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/quizzes/history/?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          quizzes = List<Map<String, dynamic>>.from(data);
          isLoadingQuizzes = false;
        });
      } else {
        setState(() => isLoadingQuizzes = false);
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      setState(() => isLoadingQuizzes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Sessions & Quiz History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: selectedTabIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    child: InkWell(
                      onTap: () => setState(() => selectedTabIndex = 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Sessions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selectedTabIndex == 0
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: selectedTabIndex == 1
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    child: InkWell(
                      onTap: () => setState(() => selectedTabIndex = 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Quiz Results',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selectedTabIndex == 1
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: selectedTabIndex == 0
                ? _buildSessionsTab()
                : _buildQuizzesTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No study sessions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.note_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              session['title'] ?? 'Untitled Session',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  session['date_created'] ?? 'Unknown date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['quiz_count'] ?? 0} quizzes taken',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            isThreeLine: true,
            onTap: () {
              // Could navigate to session details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing session: ${session['title']}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    if (isLoadingQuizzes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No quizzes completed yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        final score = quiz['score'] ?? 0;
        final total = quiz['total_questions'] ?? 1;
        final percentage = ((score / total) * 100).toStringAsFixed(1);
        
        Color scoreColor = double.parse(percentage) >= 80
            ? Colors.green
            : double.parse(percentage) >= 60
                ? Colors.orange
                : Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withAlpha(25),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              quiz['title'] ?? 'Quiz',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Score: $score/$total questions',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  quiz['date_created'] ?? 'Unknown date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Icon(
              double.parse(percentage) >= 80
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: scoreColor,
            ),
            onTap: () {
              // Could show quiz details or option to retake
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quiz: ${quiz['title']} - Score: $percentage%'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
