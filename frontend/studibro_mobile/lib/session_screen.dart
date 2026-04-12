import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';
import 'auth_modal.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';

class SessionScreen extends StatefulWidget {
  final bool isImageMode;
  final String title;
  final String initialText;

  const SessionScreen({
    super.key,
    required this.isImageMode,
    required this.title,
    this.initialText = '',
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final String backendUrl = ApiConfig.summarizeEndpoint;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _summary = "";
  bool _isLoading = false;
  bool _isExtracting = false;
  File? _selectedImage;
  late TextRecognizer _textRecognizer;
  String? _username;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _loadUsername();
    
    // If initialText is provided, populate the text controller
    if (widget.initialText.isNotEmpty) {
      _textController.text = widget.initialText;
    } else if (widget.isImageMode) {
      // Use addPostFrameCallback instead of Future.delayed for better testability
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _capturePhoto();
        }
      });
    }
  }

  Future<void> _loadUsername() async {
    const storage = FlutterSecureStorage();
    try {
      final username = await storage.read(key: 'username');
      if (mounted) {
        if (username == null) {
          // Not logged in, redirect to home
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to access this feature')),
          );
        } else {
          setState(() => _username = username);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'username');
    if (mounted) {
      setState(() => _username = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  void _showAuthModal() async {
    final result = await AuthModal.showAuthModal(context);
    if (result != null && mounted) {
      _loadUsername();
    }
  }

  /// Captures a photo from the device camera
  Future<void> _capturePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _processSelectedImage(pickedFile);
      }
    } catch (e) {
      _showErrorSnackbar('Camera Error', 'Failed to access camera: ${e.toString()}');
    }
  }

  /// Picks a photo from the device gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _processSelectedImage(pickedFile);
      }
    } catch (e) {
      _showErrorSnackbar('Gallery Error', 'Failed to access gallery: ${e.toString()}');
    }
  }

  /// Processes the selected image and extracts text from it
  Future<void> _processSelectedImage(XFile imageFile) async {
    final File imageFileObj = File(imageFile.path);

    setState(() {
      _selectedImage = imageFileObj;
      _isExtracting = true;
      _textController.text = "Extracting text...";
    });

    try {
      final String extractedText = await _extractTextFromImage(imageFileObj.path);
      
      setState(() {
        _textController.text = extractedText.isEmpty
            ? "(No text detected in image. Try another image.)"
            : extractedText;
        _isExtracting = false;
      });

      if (extractedText.isNotEmpty) {
        _showInfoSnackbar('Success', 'Text extracted successfully!');
      } else {
        _showErrorSnackbar('No Text', 'No text detected in this image.');
      }
    } catch (e) {
      setState(() {
        _textController.text = "";
        _isExtracting = false;
      });
      _showErrorSnackbar('Extraction Error', 'Failed to extract text: ${e.toString()}');
    }
  }

  /// Extracts text from the image file using ML Kit (offline)
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text.trim();
      return extractedText;
    } catch (e) {
      rethrow;
    }
  }

  /// Shows an error snackbar
  void _showErrorSnackbar(String title, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Shows a success snackbar
  void _showInfoSnackbar(String title, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _getSummary() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notes are empty. Please scan or type text!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = "Processing notes with Gemini AI...";
    });

    try {
      // Get the auth token from secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        setState(() {
          _summary = "ERROR: Not authenticated. Please log in again.";
        });
        return;
      }

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"text": _textController.text}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('DEBUG: Full response: ${response.body}');
          print('DEBUG: Parsed data: $data');
          
          final summary = data['summary'];
          print('DEBUG: Summary value: $summary');
          
          if (summary == null || summary.toString().isEmpty) {
            setState(() {
              _summary = "⚠️ Empty response from AI. Please try again.";
            });
          } else {
            setState(() {
              _summary = summary.toString();
              print('DEBUG: Summary updated to: $_summary');
            });
          }
        } catch (parseError) {
          print('DEBUG: Parse error: $parseError');
          print('DEBUG: Response body: ${response.body}');
          setState(() {
            _summary = "ERROR: Failed to parse response.\nResponse: ${response.body}\nError: $parseError";
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _summary = "ERROR: Authentication failed (401).\nPlease log in again.";
        });
      } else {
        setState(() {
          _summary = "SERVER ERROR (Code: ${response.statusCode}):\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _summary = "CONNECTION FAILED.\n\nEnsure your Django server is running on 0.0.0.0 and your firewall is open.\n\nError: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSummary() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showErrorSnackbar('Error', 'Not authenticated. Please log in again.');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.saveSummaryEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "original_text": _textController.text,
          "summary_text": _summary,
          "subject_class": _classController.text,
          "year": _yearController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        _showInfoSnackbar('Success', '✅ Summary saved successfully!');
        // Keep class and year values so user can create flashcards/quiz without re-entering
      } else {
        _showErrorSnackbar('Error', 'Failed to save summary (Code: ${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to save: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Center(
                  child: Text(
                    _username!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          if (_username != null)
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            TextButton.icon(
              onPressed: _showAuthModal,
              icon: const Icon(Icons.login, color: Colors.white, size: 20),
              label: const Text(
                'Login/Sign Up',
                style: TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Input Area (Top Half)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Display captured image if available
                  if (_selectedImage != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Captured Image",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Text Input Field
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _textController,
                      maxLines: 8,
                      readOnly: widget.isImageMode && _selectedImage == null,
                      decoration: InputDecoration(
                        hintText: widget.isImageMode
                            ? "Extracted Text (Tap Scan to update)"
                            : "Paste or Type Notes Here",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
                        suffixIcon: widget.isImageMode
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: "Re-scan",
                                  onPressed: _isExtracting ? null : _capturePhoto,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Capture Buttons (for Image Mode)
                  if (widget.isImageMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExtracting ? null : _capturePhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                            icon: Icon(
                              _isExtracting ? Icons.hourglass_bottom : Icons.camera_alt,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isExtracting ? "EXTRACTING..." : "SCAN",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExtracting ? null : _pickImageFromGallery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                            icon: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "GALLERY",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _isExtracting ? null : _getSummary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 3,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.stars_outlined),
                          label: Text(
                            _isLoading ? "PROCESSING..." : "GENERATE SUMMARY",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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

          // Results Area (Bottom Half)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "AI Response",
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summary.isEmpty && !_isLoading
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.note_alt_outlined,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Results will appear here",
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Text(
                                      _summary,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            // Class and Year input fields - shown when there's a summary
                            if (_summary.isNotEmpty && !_isLoading && !_summary.startsWith('ERROR') && !_summary.startsWith('⚠️'))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _classController,
                                      decoration: InputDecoration(
                                        labelText: 'Class/Subject (optional)',
                                        hintText: 'e.g., Physics 101, Biology A',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(Icons.school),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _yearController,
                                      decoration: InputDecoration(
                                        labelText: 'Year (optional)',
                                        hintText: 'e.g., 2024, 2025',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(Icons.calendar_today),
                                      ),
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                    ),
                                  ],
                                ),
                              ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _saveSummary,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          icon: const Icon(Icons.save, color: Colors.white),
                                          label: const Text(
                                            'Save This Summary',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => QuizScreen(
                                                      title: 'Quiz',
                                                      notes: _summary,
                                                      subjectClass: _classController.text,
                                                      year: _yearController.text,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              icon: const Icon(Icons.quiz, color: Colors.white),
                                              label: const Text(
                                                'Quiz',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => FlashcardScreen(
                                                      title: 'Flashcards',
                                                      notes: _summary,
                                                      subjectClass: _classController.text,
                                                      year: _yearController.text,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.purple,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              icon: const Icon(Icons.library_books, color: Colors.white),
                                              label: const Text(
                                                'Flashcards',
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _classController.dispose();
    _yearController.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}