/// API Configuration for StudiBro
class ApiConfig {
  // Change this to match your backend server IP/domain
  static const String baseUrl = 'http://192.168.0.8:8000/api';
  
  // API Endpoints
  static const String summarizeEndpoint = '$baseUrl/summarize/';
  static const String loginEndpoint = '$baseUrl/token/';
  static const String quizEndpoint = '$baseUrl/quiz/';
  static const String answerEndpoint = '$baseUrl/answer/';
  static const String historyEndpoint = '$baseUrl/history/';
  
  // Timeout duration for HTTP requests (in seconds)
  static const int requestTimeout = 30;
  
  // User ID (hardcoded for now, replace with actual auth later)
  static const int userId = 1;
}
