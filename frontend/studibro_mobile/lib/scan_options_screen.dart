import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session_screen.dart';
import 'auth_modal.dart';

class ScanOptionsScreen extends StatefulWidget {
  const ScanOptionsScreen({super.key});

  @override
  State<ScanOptionsScreen> createState() => _ScanOptionsScreenState();
}

class _ScanOptionsScreenState extends State<ScanOptionsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late TextRecognizer _textRecognizer;
  bool _isExtracting = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    const storage = FlutterSecureStorage();
    try {
      final username = await storage.read(key: 'username');
      if (mounted) {
        if (username == null) {
          // Not logged in, redirect to home
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to access scanning')),
          );
        } else {
          setState(() => _username = username);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  void _showErrorSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleCamera() async {
    try {
      setState(() => _isExtracting = true);
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        _showInfoSnackbar('Extracting', 'Processing image...');
        final String extractedText = await _extractTextFromImage(pickedFile.path);

        if (mounted) {
          if (extractedText.isEmpty) {
            setState(() => _isExtracting = false);
            _showErrorSnackbar('No Text', 'No text detected in this image. Try again.');
          } else {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionScreen(
                    isImageMode: true,
                    title: 'Scanned Notes',
                    initialText: extractedText,
                  ),
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isExtracting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        _showErrorSnackbar('Camera Error', 'Failed to access camera: ${e.toString()}');
      }
    }
  }

  Future<void> _handleGallery() async {
    try {
      setState(() => _isExtracting = true);
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showInfoSnackbar('Extracting', 'Processing image...');
        final String extractedText = await _extractTextFromImage(pickedFile.path);

        if (mounted) {
          if (extractedText.isEmpty) {
            setState(() => _isExtracting = false);
            _showErrorSnackbar('No Text', 'No text detected in this image. Try another.');
          } else {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionScreen(
                    isImageMode: true,
                    title: 'Scanned Notes',
                    initialText: extractedText,
                  ),
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isExtracting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        _showErrorSnackbar('Gallery Error', 'Failed to access gallery: ${e.toString()}');
      }
    }
  }

  void _handleTypeText() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionScreen(
          isImageMode: false,
          title: 'Type/Paste Notes',
          initialText: '',
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
    required Color color,
    required bool isLoading,
  }) {
    return Material(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        )
                      : Icon(
                          icon,
                          size: 44,
                          color: color,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Choose Input Method", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              "How do you want to input your notes?",
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose from camera, gallery, or type directly",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionButton(
              icon: Icons.camera_alt,
              label: "Camera",
              description: "Take a photo with your camera and extract text",
              onTap: _handleCamera,
              color: Theme.of(context).colorScheme.primary,
              isLoading: _isExtracting,
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              icon: Icons.image,
              label: "Gallery",
              description: "Pick an image from your phone gallery",
              onTap: _handleGallery,
              color: Colors.green,
              isLoading: _isExtracting,
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              icon: Icons.edit_note,
              label: "Type/Paste",
              description: "Write or paste your notes directly",
              onTap: _handleTypeText,
              color: Colors.orange,
              isLoading: false,
            ),
          ],
        ),
      ),
    );
  }
}
