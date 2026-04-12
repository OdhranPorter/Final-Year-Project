import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'config.dart';
import 'saved_flashcard_viewer_screen.dart';

class FlashcardsHistoryScreen extends StatefulWidget {
  const FlashcardsHistoryScreen({super.key});

  @override
  State<FlashcardsHistoryScreen> createState() =>
      _FlashcardsHistoryScreenState();
}

class _FlashcardsHistoryScreenState extends State<FlashcardsHistoryScreen> {
  List<Map<String, dynamic>> flashcards = [];
  List<String> availableClasses = [];
  List<String> availableYears = [];
  String? selectedClass;
  String? selectedYear;
  bool isLoading = true;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchFlashcards();
    _fetchFilterOptions();
  }

  Future<void> _loadUsername() async {
    const storage = FlutterSecureStorage();
    try {
      final name = await storage.read(key: 'username');
      if (mounted) {
        setState(() => username = name);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchFilterOptions() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.flashcardFiltersEndpoint),
        headers: {
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            availableClasses =
                List<String>.from(data['classes'] ?? []);
            availableYears = List<String>.from(data['years'] ?? []);
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchFlashcards() async {
    setState(() => isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      String url = ApiConfig.flashcardsHistoryEndpoint;
      final queryParams = [];

      if (selectedClass != null && selectedClass!.isNotEmpty) {
        queryParams.add("subject_class=$selectedClass");
      }
      if (selectedYear != null && selectedYear!.isNotEmpty) {
        queryParams.add("year=$selectedYear");
      }

      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join('&')}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            flashcards = List<Map<String, dynamic>>.from(data['flashcards'] ?? []);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to load flashcards"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteFlashcard(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Flashcard Set?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.flashcardsHistoryEndpoint}$id/delete/'),
        headers: {
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _fetchFlashcards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Flashcard set deleted"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Flashcards",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filters",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Class"),
                        value: selectedClass,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("All Classes"),
                          ),
                          ...availableClasses
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              ,
                        ],
                        onChanged: (value) {
                          setState(() => selectedClass = value);
                          _fetchFlashcards();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Year"),
                        value: selectedYear,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("All Years"),
                          ),
                          ...availableYears
                              .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ))
                              ,
                        ],
                        onChanged: (value) {
                          setState(() => selectedYear = value);
                          _fetchFlashcards();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Flashcards List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : flashcards.isEmpty
                    ? Center(
                        child: Text(
                          "No flashcards yet",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: flashcards.length,
                        itemBuilder: (context, index) {
                          final flashcard = flashcards[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SavedFlashcardViewerScreen(
                                          flashcard: flashcard,
                                        ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      flashcard['title'] ?? 'Flashcard Set',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.layers,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${flashcard['total_cards']} cards",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          flashcard['created_at']
                                              .toString()
                                              .split('T')[0],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (flashcard['subject_class'] != null &&
                                        flashcard['subject_class']!
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                flashcard['subject_class'] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                            if (flashcard['year'] != null &&
                                                flashcard['year']!
                                                    .toString()
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    flashcard['year'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSecondaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text("Delete"),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteFlashcard(flashcard['id']),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
