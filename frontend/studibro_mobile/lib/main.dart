import 'package:flutter/material.dart';
import 'session_screen.dart'; // Import the new session screen

void main() {
  runApp(const StudiBroApp());
}

class StudiBroApp extends StatelessWidget {
  const StudiBroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudiBro AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use Material 3
        useMaterial3: true, 
        // Use a modern, deep theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: const Color(0xFF673AB7), // Deep Purple
          secondary: const Color(0xFF03A9F4), // Light Blue
        ),
        
        // **CONFLICTING cardTheme REMOVED HERE**
        
        // Global styling for elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Widget for the selection cards
  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isImageMode,
  }) {
    return Card(
      // The styling (elevation, shape, rounded corners) is now defined here, on the individual Card widget.
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionScreen(isImageMode: isImageMode, title: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                    )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Logo/Header ---
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 80, child: Icon(Icons.lightbulb_outline, size: 60, color: Color(0xFF673AB7))),
                    SizedBox(height: 8),
                    Text(
                      "StudiBro",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Your AI-Powered Study Assistant",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Main Options ---
              Text(
                "How would you like to input your notes?",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 1. Image/OCR Mode Card (Leads to Camera/Gallery)
              _buildSelectionCard(
                context: context,
                icon: Icons.camera_alt_rounded,
                title: "Scan (Image/OCR)",
                subtitle: "Capture text from physical textbooks or whiteboards.",
                isImageMode: true,
              ),

              // 2. Text Input Mode Card (Leads to Typing)
              _buildSelectionCard(
                context: context,
                icon: Icons.keyboard_alt_rounded,
                title: "Paste (Manual Text)",
                subtitle: "Paste notes from digital sources or type them in.",
                isImageMode: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
