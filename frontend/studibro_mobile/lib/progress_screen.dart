import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _secureStorage = const FlutterSecureStorage();
  late String _accessToken = '';
  
  List<String> classes = [];
  List<String> years = [];
  String? selectedClass;
  String? selectedYear;
  List<dynamic> progressData = [];
  Map<String, dynamic>? statistics;
  bool isLoading = true;
  String? errorMessage;

  // For adding test score
  TextEditingController testNameController = TextEditingController();
  TextEditingController scoreController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSubmittingScore = false;

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null && mounted) {
        setState(() {
          _accessToken = token;
        });
        // Pass token directly to avoid race condition
        await _loadFilterOptions(token);
      } else if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Not authenticated. Please login first.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading token: $e';
        });
      }
    }
  }

  Future<void> _loadFilterOptions(String token) async {
    try {
      print('Progress Screen: Access Token = $token');
      print('Progress Screen: Calling ${ApiConfig.baseUrl}/progress/filters/');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/progress/filters/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Progress Screen: Response status = ${response.statusCode}');
      print('Progress Screen: Response body = ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            classes = List<String>.from(data['classes'] ?? []);
            years = List<String>.from(data['years'] ?? []);

            // Auto-select first class and year if available
            if (classes.isNotEmpty && years.isNotEmpty) {
              selectedClass = classes.first;
              selectedYear = years.first;
            }
          });

          // Load progress data after setting filter options
          if (selectedClass != null && selectedYear != null) {
            await _loadProgressData();
          } else {
            setState(() {
              isLoading = false;
              errorMessage = 'No data available. Start by adding test scores or taking quizzes.';
            });
          }
        }
      } else {
        final errorBody = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Error ${response.statusCode}: ${errorBody['detail'] ?? 'Failed to load filter options'}';
          });
        }
      }
    } catch (e) {
      print('Progress Screen: Exception = $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading filters: $e';
        });
      }
    }
  }

  Future<void> _loadProgressData() async {
    if (selectedClass == null || selectedYear == null || _accessToken.isEmpty) {
      print('Progress: Cannot load data - class=$selectedClass, year=$selectedYear, token=$_accessToken');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Loading progress data for $selectedClass / $selectedYear');
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/progress/data/?subject_class=$selectedClass&year=$selectedYear',
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Progress data response: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            progressData = data['progress_data'] ?? [];
            statistics = data['statistics'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          final errorBody = jsonDecode(response.body);
          setState(() {
            isLoading = false;
            errorMessage = 'Error ${response.statusCode}: ${errorBody['detail'] ?? 'Failed to load progress data'}';
          });
        }
      }
    } catch (e) {
      print('Exception loading progress data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading progress data: $e';
        });
      }
    }
  }

  Future<void> _addTestScore() async {
    if (selectedClass == null || selectedYear == null || scoreController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      isSubmittingScore = true;
    });

    try {
      print('Adding test score for $selectedClass / $selectedYear');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/progress/add-test-score/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject_class': selectedClass,
          'year': selectedYear,
          'score': double.parse(scoreController.text),
          'test_date': selectedDate.toIso8601String().split('T')[0],
          'test_name': testNameController.text.isEmpty
              ? 'In-Class Test'
              : testNameController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Add test score response: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 201) {
        _showSuccessSnackBar('Test score added successfully!');
        scoreController.clear();
        testNameController.clear();
        selectedDate = DateTime.now();
        await _loadProgressData();
      } else {
        final error = jsonDecode(response.body);
        _showErrorSnackBar(error['error'] ?? 'Failed to add test score');
      }
    } catch (e) {
      print('Exception adding test score: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        isSubmittingScore = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading && progressData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters Section
                  _buildFilterSection(),
                  const SizedBox(height: 24),

                  // Error or Data Display
                  if (errorMessage != null && progressData.isEmpty)
                    _buildErrorWidget(errorMessage!)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Cards
                        if (statistics != null) _buildStatisticsCards(),
                        const SizedBox(height: 24),

                        // Chart
                        if (progressData.isNotEmpty) _buildChart(),
                        if (progressData.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No progress data available for this selection. Add test scores below to get started!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Add Test Score Section
                        _buildAddTestScoreSection(),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    if (classes.isEmpty || years.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.info, color: Colors.orange, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'No classes data available yet',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final token = await _secureStorage.read(key: 'auth_token');
                      if (token != null) {
                        await _loadFilterOptions(token);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Class and Year',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    isExpanded: true,
                    items: classes
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                      if (value != null && selectedYear != null) {
                        _loadProgressData();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Class/Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    isExpanded: true,
                    items: years
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                      if (value != null && selectedClass != null) {
                        _loadProgressData();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Average Score',
                value: '${statistics!['average_score']}%',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Highest Score',
                value: '${statistics!['highest_score']}%',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Lowest Score',
                value: '${statistics!['lowest_score']}%',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total Entries',
                value: '${statistics!['total_entries']}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Separate progress data into test and quiz lines
    List<FlSpot> testSpots = [];
    List<FlSpot> quizSpots = [];
    
    for (int i = 0; i < progressData.length; i++) {
      final entry = progressData[i];
      final point = FlSpot(i.toDouble(), entry['score'].toDouble());
      
      if (entry['type'] == 'test') {
        testSpots.add(point);
      } else {
        quizSpots.add(point);
      }
    }

    if (progressData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Add test scores to see a progress chart.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Over Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'In-Class Tests',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'StudiBro Quizzes',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < progressData.length) {
                            final date = progressData[index]['date'];
                            final parts = date.split('-');
                            return Text('${parts[2]}/${parts[1]}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // In-Class Tests line (RED)
                    if (testSpots.isNotEmpty)
                      LineChartBarData(
                        spots: testSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2.5,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.15),
                        ),
                      ),
                    // StudiBro Quizzes line (Deep Purple)
                    if (quizSpots.isNotEmpty)
                      LineChartBarData(
                        spots: quizSpots,
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 2.5,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.deepPurple.withOpacity(0.15),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTestScoreSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add In-Class Test Score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Test Name Field
            TextField(
              controller: testNameController,
              decoration: InputDecoration(
                labelText: 'Test Name (optional)',
                hintText: 'e.g., Midterm, Chapter Quiz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Score Field
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Score (%)',
                hintText: '0-100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 12),

            // Date Picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedDate.toString().split(' ')[0]),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmittingScore ? null : _addTestScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isSubmittingScore
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Test Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    testNameController.dispose();
    scoreController.dispose();
    super.dispose();
  }
}
