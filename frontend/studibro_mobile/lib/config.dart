/// API Configuration for StudiBro
class ApiConfig {
  // Change this to match your backend server IP/domain
  static const String baseUrl = 'http://192.168.0.8:8000/api';
  
  // API Endpoints
  static const String summarizeEndpoint = '$baseUrl/summarize/';
  static const String loginEndpoint = '$baseUrl/token/';
  static const String notesEndpoint = '$baseUrl/notes/';
  static const String saveSummaryEndpoint = '$baseUrl/notes/save/';
  static const String notesFiltersEndpoint = '$baseUrl/notes/filters/';
  static const String generateQuizEndpoint = '$baseUrl/generate-quiz/';
  static const String saveQuizEndpoint = '$baseUrl/quizzes/';
  static const String quizzesHistoryEndpoint = '$baseUrl/quizzes-history/';
  static const String quizFiltersEndpoint = '$baseUrl/quizzes/filters/';
  static const String quizEndpoint = '$baseUrl/quiz/';
  static const String answerEndpoint = '$baseUrl/answer/';
  static const String historyEndpoint = '$baseUrl/history/';
  static const String generateFlashcardsEndpoint = '$baseUrl/generate-flashcards/';
  static const String saveFlashcardsEndpoint = '$baseUrl/flashcards/';
  static const String flashcardsHistoryEndpoint = '$baseUrl/flashcards-history/';
  static const String flashcardFiltersEndpoint = '$baseUrl/flashcards/filters/';
  
  // Timeout duration for HTTP requests (in seconds)
  static const int requestTimeout = 30;
  
  // User ID (hardcoded for now, replace with actual auth later)
  static const int userId = 1;
}
