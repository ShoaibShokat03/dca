/// API configuration for the DCA app.
/// Change the base URL in one place for different environments.
class ApiConfig {
  // =====================================================
  // BASE URLs — change these for production/staging
  // =====================================================

  /// DCA backend base URL
  static const String backendBaseUrl = 'https://dca.jantrah.io';

  /// Streamer media service base URL (used for HLS videos)
  static const String streamerBaseUrl = 'https://jawab.jantrah.io/media-storage-streamer/api';

  // =====================================================
  // API Endpoints (under backendBaseUrl)
  // =====================================================

  static const String apiPrefix = '/api';

  // Auth
  static String get login => '$backendBaseUrl$apiPrefix/login';
  static String get signup => '$backendBaseUrl$apiPrefix/signup';
  static String get logout => '$backendBaseUrl$apiPrefix/logout';

  // Dashboard
  static String get dashboard => '$backendBaseUrl$apiPrefix/dashboard';

  // Profile
  static String get profile => '$backendBaseUrl$apiPrefix/profile';
  static String get profileUpdate => '$backendBaseUrl$apiPrefix/profile/update';

  // Sessions
  static String get sessions => '$backendBaseUrl$apiPrefix/sessions';
  static String sessionQuizzes(int id) => '$backendBaseUrl$apiPrefix/sessions/$id/quizzes';

  // Quizzes
  static String get quizzes => '$backendBaseUrl$apiPrefix/quizzes';
  static String quizQuestions(int id) => '$backendBaseUrl$apiPrefix/quizzes/$id/questions';
  static String quizSubmitAnswer(int id) => '$backendBaseUrl$apiPrefix/quizzes/$id/submit-answer';
  static String quizResult(int id) => '$backendBaseUrl$apiPrefix/quizzes/$id/result';
  static String quizTimeLog(int id) => '$backendBaseUrl$apiPrefix/quizzes/$id/time-log';
  static String quizStart(int id) => '$backendBaseUrl$apiPrefix/quizzes/$id/start';

  // Lectures
  static String get lectures => '$backendBaseUrl$apiPrefix/lectures';
  static String lecturesByQuiz(int id) => '$backendBaseUrl$apiPrefix/lectures/quiz/$id';

  // Live Stream
  static String get liveStream => '$backendBaseUrl$apiPrefix/live-stream';

  // Reattempts
  static String get reattempts => '$backendBaseUrl$apiPrefix/reattempts';

  // News
  static String get news => '$backendBaseUrl$apiPrefix/news';

  // =====================================================
  // Streamer helpers
  // =====================================================

  /// Build poster URL from a video UUID
  static String posterUrl(String uuid) => '$streamerBaseUrl/videos/$uuid/poster.jpg';

  /// Build MP4 stream URL from a UUID
  static String mp4Url(String uuid) => '$streamerBaseUrl/videos/$uuid/mp4';

  /// Extract UUID from a file_path (HLS master URL) if present
  static String? extractUuid(String? filePath) {
    if (filePath == null) return null;
    final match = RegExp(r'/videos/([a-f0-9-]{36})/', caseSensitive: false).firstMatch(filePath);
    return match?.group(1);
  }

  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
}
