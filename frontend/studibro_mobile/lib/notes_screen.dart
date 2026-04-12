import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'config.dart';
import 'quiz_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _username;
  
  // Filter state
  List<String> _availableClasses = [];
  List<String> _availableYears = [];
  String? _selectedClass;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchFilterOptions();
    _fetchNotes();
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

  Future<void> _fetchFilterOptions() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.notesFiltersEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availableClasses = List<String>.from(data['classes'] ?? []);
            _availableYears = List<String>.from(data['years'] ?? []);
          });
        }
      }
    } catch (e) {
      // Silently ignore errors in fetching filters
    }
  }

  Future<void> _fetchNotes() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _notes = [];
        });
        return;
      }

      // Build query parameters based on filters
      var queryParams = <String, String>{};
      if (_selectedClass != null && _selectedClass!.isNotEmpty) {
        queryParams['subject_class'] = _selectedClass!;
      }
      if (_selectedYear != null && _selectedYear!.isNotEmpty) {
        queryParams['year'] = _selectedYear!;
      }

      final uri = Uri.parse(ApiConfig.notesEndpoint).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notes = List<Map<String, dynamic>>.from(data['summaries'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Error', 'Failed to load notes');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error', 'Connection failed: ${e.toString()}');
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        _showErrorSnackbar('Error', 'Not authenticated');
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.notesEndpoint}$noteId/delete/'),
        headers: {
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showInfoSnackbar('Success', 'Note deleted');
        _fetchNotes(); // Refresh the list
      } else {
        _showErrorSnackbar('Error', 'Failed to delete note');
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to delete: ${e.toString()}');
    }
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

  void _showNoteDetails(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteNote(note['id'] ?? 0);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  'Original Notes:',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note['original_text'] ?? 'No content',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'AI Summary:',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note['summary_text'] ?? 'No summary',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                if (note['subject_class'] != null && note['subject_class']!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class: ${note['subject_class']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                if (note['year'] != null && note['year']!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year: ${note['year']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                if (note['created_at'] != null)
                  Text(
                    'Saved: ${note['created_at']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
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
        title: const Text("Your Notes", style: TextStyle(fontWeight: FontWeight.w600)),
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
            const SizedBox.shrink(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Filter section
                if (_availableClasses.isNotEmpty || _availableYears.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Notes',
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Class filter
                            if (_availableClasses.isNotEmpty)
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedClass,
                                  hint: Text('By Class', style: TextStyle(color: Colors.grey[600])),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: const Text('All Classes'),
                                    ),
                                    ..._availableClasses
                                        .map((c) => DropdownMenuItem<String>(
                                          value: c,
                                          child: Text(c),
                                        ))
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedClass = value);
                                    _fetchNotes();
                                  },
                                ),
                              ),
                            const SizedBox(width: 12),
                            // Year filter
                            if (_availableYears.isNotEmpty)
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedYear,
                                  hint: Text('By Year', style: TextStyle(color: Colors.grey[600])),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: const Text('All Years'),
                                    ),
                                    ..._availableYears
                                        .map((y) => DropdownMenuItem<String>(
                                          value: y,
                                          child: Text(y),
                                        ))
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedYear = value);
                                    _fetchNotes();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Notes list
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saved notes yet',
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Generate a summary and save it here',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchNotes,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              final note = _notes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _showNoteDetails(note),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Summary',
                                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Display class and year if available
                                        if (note['subject_class'] != null && note['subject_class']!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              'Class: ${note['subject_class']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        if (note['year'] != null && note['year']!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              'Year: ${note['year']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.purple[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          note['original_text'] ?? 'No content',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tap to view',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            if (note['created_at'] != null)
                                              Text(
                                                note['created_at'].toString().split('T')[0],
                                                style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QuizScreen(
                                            title: 'Quiz',
                                            notes: note['summary'] ?? note['original_text'] ?? '',
                                            subjectClass: note['subject_class'],
                                            year: note['year'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.quiz),
                                    label: const Text('Create Quiz'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
