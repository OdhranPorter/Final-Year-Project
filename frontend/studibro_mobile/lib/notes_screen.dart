import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'quiz_screen.dart';

class NotesScreen extends StatefulWidget {
  final int userId;

  const NotesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final String backendUrl = 'http://192.168.0.8:8000/api';
  List<dynamic> notes = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/notes/?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notes = data['notes'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load notes (${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6B46C1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotes,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No notes yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Scan images and save AI analysis to create notes",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteCard(
                          note: note,
                          onRefresh: _fetchNotes,
                          userId: widget.userId,
                          backendUrl: backendUrl,
                        );
                      },
                    ),
    );
  }
}

class NoteCard extends StatefulWidget {
  final dynamic note;
  final VoidCallback onRefresh;
  final int userId;
  final String backendUrl;

  const NoteCard({
    super.key,
    required this.note,
    required this.onRefresh,
    required this.userId,
    required this.backendUrl,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool isExpanded = false;
  bool isGeneratingQuiz = false;

  Future<void> _generateQuizFromNote() async {
    final content = widget.note['content'] ?? '';
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note has no content")),
      );
      return;
    }

    setState(() => isGeneratingQuiz = true);

    try {
      final response = await http
          .post(
            Uri.parse('${widget.backendUrl}/generate-quiz/'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": content,
              "user_id": widget.userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int quizId = data['quiz_id'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✓ Quiz generated!")),
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                quizId: quizId,
                sessionTitle: 'Quiz from Note',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isGeneratingQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.note['title'] ?? 'Untitled';
    final content = widget.note['content'] ?? '';
    final summary = widget.note['summary'];
    final summaryText = summary != null ? summary['text'] ?? '' : '';
    final createdAt = widget.note['created_at'] ?? '';

    // Format date
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate =
            "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Card Header (Always Visible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B46C1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: const Color(0xFF6B46C1),
                      ),
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
                if (!isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      content.length > 100
                          ? "${content.substring(0, 100)}..."
                          : content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Expanded Content
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Original Extracted Text
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Extracted Text:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            content,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gemini Analysis
                  if (summaryText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text(
                            "Gemini AI Analysis:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF6B46C1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF7C3AED),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.purple[50],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: MarkdownBody(
                              data: summaryText,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                h1: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF6B46C1),
                                ),
                                h2: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF7C3AED),
                                ),
                                em: const TextStyle(fontStyle: FontStyle.italic),
                                strong: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Generate Quiz Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isGeneratingQuiz ? null : _generateQuizFromNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: isGeneratingQuiz
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.quiz),
                              label: Text(
                                isGeneratingQuiz ? "Generating..." : "📝 Generate Quiz",
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
