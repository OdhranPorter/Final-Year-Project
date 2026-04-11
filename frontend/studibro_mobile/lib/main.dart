import 'package:flutter/material.dart';
import 'session_screen.dart'; // Import the new session screen
import 'quiz_history_screen.dart'; // Import quiz history screen
import 'login_screen.dart'; // Import login screen
import 'notes_screen.dart'; // Import notes screen

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  int? userId;
  bool isLoggedIn = false;

  void _openLoginScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result != null && result['isLoggedIn'] == true) {
      setState(() {
        isLoggedIn = true;
        userEmail = result['email'];
        userId = result['userId'] ?? 1; // Default to 1 if not provided
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome, ${result['email']}!")),
      );
    }
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
      userEmail = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User Profile",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userEmail ?? "No email",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings coming soon")),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text("Settings"),
            ),
            const SizedBox(height: 12),

            // View Notes Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesScreen(userId: userId!),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.note_outlined),
              label: const Text("View Notes"),
            ),
            const SizedBox(height: 12),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

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
          if (!isLoggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please login first to use this feature")),
            );
            _openLoginScreen();
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionScreen(
                isImageMode: isImageMode,
                title: title,
                userId: userId ?? 1,
              ),
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
      appBar: AppBar(
        title: const Text(
          "StudiBro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isLoggedIn
                ? GestureDetector(
                    onTap: _showProfileMenu,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            userEmail?.split('@').first ?? "Profile",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _openLoginScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text(
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
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

              // --- Main Action ---
              Text(
                "Scan Your Notes",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Scan Button - Camera/OCR
              _buildSelectionCard(
                context: context,
                icon: Icons.camera_alt_rounded,
                title: "Scan Notes",
                subtitle: "Capture text from textbooks or handwritten notes.",
                isImageMode: true,
              ),

              const SizedBox(height: 24),

              // Quiz History Section
              Text(
                "Your Progress",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Quiz History Card
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 24),
                child: InkWell(
                  onTap: () {
                    if (!isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login first to view your quiz history")),
                      );
                      _openLoginScreen();
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuizHistoryScreen(userId: userId ?? 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(Icons.history,
                            size: 40,
                            color:
                                Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Quiz History",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      )),
                              const SizedBox(height: 4),
                              Text(
                                "View your study sessions and quiz results.",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
