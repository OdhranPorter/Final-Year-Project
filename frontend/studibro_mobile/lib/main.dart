import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'scan_options_screen.dart';
import 'notes_screen.dart';
import 'quizzes_history_screen.dart';
import 'auth_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudiBroApp());
}

class StudiBroApp extends StatefulWidget {
  const StudiBroApp({super.key});

  @override
  State<StudiBroApp> createState() => _StudiBroAppState();
}

class _StudiBroAppState extends State<StudiBroApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudiBro AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: const Color(0xFF673AB7),
          secondary: const Color(0xFF03A9F4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    const storage = FlutterSecureStorage();
    try {
      final username = await storage.read(key: 'username');
      if (mounted && username != null) {
        setState(() => _username = username);
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

  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isImageMode,
  }) {
    return Material(
      child: InkWell(
        onTap: () {
          if (_username == null) {
            _showAuthModal();
          } else {
            // Route based on button title
            if (title == "Scan from Image") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanOptionsScreen(),
                ),
              );
            } else if (title == "View Notes") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotesScreen(),
                ),
              );
            } else if (title == "View Quizzes") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizzesHistoryScreen(),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: _username == null
                  ? [
                      Colors.grey[300]!.withOpacity(0.5),
                      Colors.grey[200]!.withOpacity(0.3),
                    ]
                  : isImageMode
                      ? [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                        ]
                      : [
                          Colors.blue.withOpacity(0.1),
                          Colors.cyan.withOpacity(0.05),
                        ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _username == null
                  ? Colors.grey[400]!.withOpacity(0.3)
                  : isImageMode
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _username == null
                    ? Colors.grey.withOpacity(0.05)
                    : isImageMode
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                        : Colors.blue.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _username == null
                        ? Colors.grey[300]!.withOpacity(0.3)
                        : isImageMode
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: _username == null
                        ? Colors.grey[500]
                        : (isImageMode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _username == null ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _username == null
                            ? "Sign in to access this feature"
                            : subtitle,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: _username == null ? Colors.grey[500] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
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
        title: const Text("StudiBro", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              "Welcome to StudiBro",
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose how you want to study",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_username == null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Sign in to get started",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create an account or log in to unlock all features",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showAuthModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign In Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSelectionCard(
              context: context,
              icon: Icons.image,
              title: "Scan from Image",
              subtitle: "Take a photo or upload from gallery\nto extract and summarize notes",
              isImageMode: true,
            ),
            const SizedBox(height: 16),
            _buildSelectionCard(
              context: context,
              icon: Icons.note_alt,
              title: "View Notes",
              subtitle: "Access your saved notes\nand summaries",
              isImageMode: false,
            ),
            const SizedBox(height: 16),
            _buildSelectionCard(
              context: context,
              icon: Icons.quiz,
              title: "View Quizzes",
              subtitle: "Review and take your\ngenerated quizzes",
              isImageMode: false,
            ),
          ],
        ),
      ),
    );
  }
}