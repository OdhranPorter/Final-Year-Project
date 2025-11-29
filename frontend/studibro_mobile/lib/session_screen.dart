import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // REQUIRED PACKAGE

class SessionScreen extends StatefulWidget {
  final bool isImageMode;
  final String title;

  const SessionScreen({super.key, required this.isImageMode, required this.title});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  // ⚠️ YOUR CORRECT IP ADDRESS: 192.168.0.8
  final String backendUrl = 'http://192.168.0.8:8000/api/summarize/';

  final TextEditingController _textController = TextEditingController();
  String _summary = "";
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // If starting in Image Mode, launch the image picker immediately
    if (widget.isImageMode) {
      Future.delayed(const Duration(milliseconds: 300), _pickImageAndSimulateOCR);
    }
  }

  // --- FEATURE 1: SIMULATED OCR ---
  Future<void> _pickImageAndSimulateOCR() async {
    final picker = ImagePicker();
    // Prompt for camera access
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        
        // MOCK LOGIC: Simulated Text Extraction
        _textController.text = """
Photosynthesis is the process used by plants, algae and certain bacteria to harness energy from sunlight and turn it into chemical energy. 

There are two main types of photosynthetic processes: oxygenic photosynthesis and anoxygenic photosynthesis. The general principles of anoxygenic and oxygenic photosynthesis are very similar, but oxygenic photosynthesis is the most common and is seen in plants, algae and cyanobacteria.
        """;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image Captured! Simulated Text Extracted.")),
        );
      });
    }
  }

  // --- FEATURE 2: CALL DJANGO BACKEND ---
  Future<void> _getSummary() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notes are empty. Please scan or type text!")),
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
        // Display detailed server error
        setState(() {
          _summary = "SERVER ERROR (Code: ${response.statusCode}):\nCould not process request. Check Django logs.";
        });
      }
    } catch (e) {
      // Display connection failure error
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
      ),
      body: Column(
        children: [
          // Input Area (Top Half)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display captured image if available
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, height: 120, fit: BoxFit.cover),
                    ),
                  ),

                // Text Input Field
                TextField(
                  controller: _textController,
                  maxLines: 8,
                  readOnly: widget.isImageMode && _selectedImage == null, 
                  decoration: InputDecoration(
                    labelText: widget.isImageMode ? "Extracted Text (Tap Scan to update)" : "Paste or Type Notes Here",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: widget.isImageMode ? IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _pickImageAndSimulateOCR, // Re-scan button
                    ) : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Summarize Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _getSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("GENERATE SUMMARY & QUIZ"),
                ),
              ],
            ),
          ),
          
          // Results Area (Bottom Half)
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gemini AI Response:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: _summary.isEmpty && !_isLoading 
                          ? Center(child: Text("Results will appear here.", style: TextStyle(color: Colors.grey[400])))
                          : Markdown(
                              data: _summary,
                              styleSheet: MarkdownStyleSheet(
                                listBullet: TextStyle(color: Colors.black87),
                                p: TextStyle(fontSize: 15, height: 1.5),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}