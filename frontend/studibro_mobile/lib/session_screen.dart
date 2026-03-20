import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SessionScreen extends StatefulWidget {
  final bool isImageMode;
  final String title;

  const SessionScreen({super.key, required this.isImageMode, required this.title});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final String backendUrl = 'http://192.168.0.8:8000/api/summarize/';

  final TextEditingController _textController = TextEditingController();
  String _summary = "";
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.isImageMode) {
      Future.delayed(const Duration(milliseconds: 300), _pickImageAndSimulateOCR);
    }
  }

  Future<void> _pickImageAndSimulateOCR() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        
        _textController.text = """
Photosynthesis is the process used by plants, algae and certain bacteria to harness energy from sunlight and turn it into chemical energy. 

There are two main types of photosynthetic processes: oxygenic photosynthesis and anoxygenic photosynthesis. The general principles of anoxygenic and oxygenic photosynthesis are very similar, but oxygenic photosynthesis is the most common and is seen in plants, algae and cyanobacteria.
        """;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image Captured! Simulated Text Extracted."),
            backgroundColor: Colors.green,
          ),
        );
      });
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
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _textController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _summary = data['summary'];
        });
      } else {
        setState(() {
          _summary = "SERVER ERROR (Code: ${response.statusCode}):\nCould not process request. Check Django logs.";
        });
      }
    } catch (e) {
      setState(() {
        _summary = "CONNECTION FAILED.\n\nEnsure your Django server is running on 0.0.0.0 and your firewall is open.\nError: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                                  onPressed: _pickImageAndSimulateOCR,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getSummary,
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
                      if (widget.isImageMode) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          width: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _pickImageAndSimulateOCR,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.all(0),
                              elevation: 3,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
                      child: _summary.isEmpty && !_isLoading
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
                              child: Markdown(
                                data: _summary,
                                styleSheet: MarkdownStyleSheet(
                                  listBullet: const TextStyle(color: Colors.black87),
                                  p: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
                                  h1: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  h2: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey[200],
                                    fontFamily: 'monospace',
                                  ),
                                ),
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
    super.dispose();
  }
}