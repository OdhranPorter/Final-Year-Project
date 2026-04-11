import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'quiz_screen.dart';

class SessionScreen extends StatefulWidget {
  final bool isImageMode;
  final String title;
  final int userId;

  const SessionScreen({
    super.key,
    required this.isImageMode,
    required this.title,
    required this.userId,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final String backendUrl = 'http://192.168.0.8:8000/api';

  final TextEditingController _textController = TextEditingController();
  String _summary = "";
  bool _isLoading = false;
  bool _isExtracting = false;
  bool _isGeneratingQuiz = false;
  bool _isSavingNote = false;
  File? _selectedImage;
  int? _savedNoteId;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
  }

  // --- FEATURE 1: REAL OCR WITH GOOGLE ML KIT ---
  Future<void> _pickImageAndExtractText() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isExtracting = true;
        _summary = "";
        _textController.text = "Extracting text...";
      });

      try {
        final inputImage = InputImage.fromFile(_selectedImage!);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        setState(() {
          _textController.text = recognizedText.text.isEmpty
              ? "[No text detected - try another image]"
              : recognizedText.text;
          _isExtracting = false;
        });

        if (recognizedText.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No text found. Try another photo.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✓ Text extracted!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isExtracting = false;
          _textController.text = "Error: ${e.toString()}";
        });
      }
    }
  }

  // --- FEATURE 2: SEND TO GEMINI FOR PROCESSING ---
  Future<void> _processWithGemini() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please extract text first")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = "Analyzing with Gemini AI...";
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw SocketException('No internet');
      }

      final response = await http
          .post(
            Uri.parse('$backendUrl/summarize/'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": _textController.text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _summary = data['summary'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Analysis complete!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _summary = "SERVER ERROR (${response.statusCode})\nCheck backend server.";
        });
      }
    } on SocketException {
      setState(() {
        _summary = "NO INTERNET\n\nCheck your connection.";
      });
    } on TimeoutException {
      setState(() {
        _summary = "TIMEOUT\n\nServer not responding.";
      });
    } catch (e) {
      setState(() {
        _summary = "ERROR\n\n${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FEATURE 3: SAVE NOTE TO DATABASE ---
  Future<void> _saveNote() async {
    if (_textController.text.trim().isEmpty || _summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Process text and analysis first")),
      );
      return;
    }

    setState(() => _isSavingNote = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/notes/save/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'title': 'Note - ${DateTime.now().toString().split(' ')[0]}',
          'original_text': _textController.text,
          'processed_content': _summary,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => _savedNoteId = data['note_id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Note saved!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSavingNote = false);
    }
  }

  // --- FEATURE 4: GENERATE QUIZ ---
  Future<void> _generateQuiz() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please extract text first")),
      );
      return;
    }

    setState(() {
      _isGeneratingQuiz = true;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw SocketException('No internet');
      }

      final response = await http
          .post(
            Uri.parse('$backendUrl/generate-quiz/'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": _textController.text,
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
                sessionTitle: widget.title,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No internet")),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timeout")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isGeneratingQuiz = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6B46C1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: SCAN BUTTON
            ElevatedButton.icon(
              onPressed: _isExtracting || _isLoading ? null : _pickImageAndExtractText,
              icon: _isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isExtracting ? "Extracting..." : "📸 Scan Image",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PREVIEW IMAGE
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
                ),
              ),

            // EXTRACTED TEXT DISPLAY
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _textController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Extracted text will appear here...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STEP 2: PROCESS WITH GEMINI BUTTON
            ElevatedButton.icon(
              onPressed: _isLoading || _isExtracting ? null : _processWithGemini,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isLoading ? "Processing..." : "✨ Analyze with AI",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // GEMINI RESPONSE DISPLAY
            if (_summary.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.purple[50],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gemini AI Analysis:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B46C1),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: _summary,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        h1: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF6B46C1),
                        ),
                        h2: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF7C3AED),
                        ),
                        em: const TextStyle(fontStyle: FontStyle.italic),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            if (_summary.isNotEmpty) const SizedBox(height: 16),

            // STEP 3: SAVE NOTE BUTTON
            if (_summary.isNotEmpty && _selectedImage != null)
              ElevatedButton.icon(
                onPressed: _isSavingNote ? null : _saveNote,
                icon: _isSavingNote
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSavingNote ? "Saving..." : "💾 Save as Note",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            if (_summary.isNotEmpty && _selectedImage != null)
              const SizedBox(height: 16),

            // STEP 4: GENERATE QUIZ BUTTON
            if (_textController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _isGeneratingQuiz || _isLoading ? null : _generateQuiz,
                icon: _isGeneratingQuiz
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.quiz),
                label: Text(
                  _isGeneratingQuiz ? "Generating..." : "📝 Generate Quiz",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}