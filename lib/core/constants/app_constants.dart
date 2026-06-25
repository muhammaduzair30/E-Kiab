// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'E-Kitab';
  static const String appNameUrdu = 'ای کتاب';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Learn Smart. Learn Digital.';

  // API base URL (update for prod)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  // API endpoints — Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String googleSignIn = '/auth/google';
  static const String me = '/auth/me';

  // API endpoints — Books
  static const String books = '/books';
  static const String bookById = '/books/:id';
  static const String booksByGrade = '/books/grade/:gradeId';
  static const String booksBySubject = '/books/subject/:subjectId';
  static const String booksByBoard = '/books/board/:boardId';
  static const String downloadBook = '/books/:id/download';
  static const String bookProgress = '/books/:id/progress';

  // API endpoints — Chapters
  static const String chapters = '/chapters';
  static const String chaptersByBook = '/chapters/book/:bookId';

  // API endpoints — Subjects
  static const String subjects = '/subjects';
  static const String grades = '/grades';
  static const String boards = '/boards';

  // API endpoints — Videos
  static const String videos = '/videos';
  static const String videoProgress = '/videos/:id/progress';
  static const String watchHistory = '/videos/history';

  // API endpoints — Quizzes
  static const String quizzes = '/quizzes';
  static const String quizById = '/quizzes/:id';
  static const String submitQuiz = '/quizzes/:id/submit';
  static const String quizResults = '/quizzes/:id/results';
  static const String quizLeaderboard = '/quizzes/:id/leaderboard';
  static const String myQuizResults = '/quizzes/my-results';

  // API endpoints — AI
  static const String aiChat = '/ai/chat';
  static const String aiSummarize = '/ai/summarize';
  static const String aiTranslate = '/ai/translate';
  static const String aiGenerateQuiz = '/ai/generate-quiz';
  static const String aiRecommend = '/ai/recommend';
  static const String chatHistory = '/ai/chat/history';

  // API endpoints — Analytics
  static const String studentAnalytics = '/analytics/student';
  static const String teacherAnalytics = '/analytics/teacher';
  static const String adminAnalytics = '/analytics/admin';
  static const String readingStats = '/analytics/reading';

  // API endpoints — Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/:id/read';
  static const String fcmToken = '/notifications/fcm-token';

  // API endpoints — Search
  static const String search = '/search';

  // API endpoints — Teacher
  static const String teacherStudents = '/teacher/students';
  static const String teacherClasses = '/teacher/classes';
  static const String assignHomework = '/teacher/homework';
  static const String uploadMaterial = '/teacher/upload';

  // API endpoints — Admin
  static const String adminUsers = '/admin/users';
  static const String adminBooks = '/admin/books';
  static const String adminDashboardAnalytics = '/admin/analytics';
  static const String adminReports = '/admin/reports';
  static const String adminCurriculum = '/admin/curriculum';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_done';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String downloadPathKey = 'download_path';

  // Hive boxes
  static const String booksBox = 'books_box';
  static const String chaptersBox = 'chapters_box';
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String bookmarksBox = 'bookmarks_box';
  static const String notesBox = 'notes_box';
  static const String readingProgressBox = 'reading_progress_box';
  static const String downloadQueueBox = 'download_queue_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String chatHistoryBox = 'chat_history_box';
  static const String quizCacheBox = 'quiz_cache_box';

  static const String hiveTokenBox = 'token_box';
  static const String hiveSettingsBox = settingsBox;
  static const String hiveOfflineBooksBox = 'offline_books_box';
  static const String hiveSyncQueueBox = syncQueueBox;

  // Pagination
  static const int defaultPageSize = 20;
  static const int booksPageSize = 10;
  static const int searchPageSize = 15;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 60000;
  static const int aiResponseTimeout = 120000;

  // Pakistani curriculum boards
  static const List<String> boardsList = [
    'Punjab Textbook Board',
    'Sindh Textbook Board',
    'KPK Textbook Board',
    'FBISE (Federal Board)',
    'Balochistan Textbook Board',
    'AJK Textbook Board',
  ];

  // Grades / Classes
  static const List<String> gradesList = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8',
    'Class 9', 'Class 10',
    'Class 11 (FSc/FA/ICS)', 'Class 12 (FSc/FA/ICS)',
  ];

  // Subjects
  static const List<String> subjectsList = [
    'English', 'Urdu', 'Mathematics', 'Science', 'Social Studies',
    'Islamiat', 'Pakistan Studies', 'Physics', 'Chemistry',
    'Biology', 'Computer Science', 'Economics', 'General Knowledge',
  ];

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  // AI chat limits
  static const int maxChatMessageLength = 2000;
  static const int maxChatHistoryMessages = 50;

  // File size limits (bytes)
  static const int maxPdfSize = 50 * 1024 * 1024;  // 50MB
  static const int maxVideoSize = 500 * 1024 * 1024; // 500MB
  static const int maxImageSize = 5 * 1024 * 1024;  // 5MB

  // Reading speed (words per minute, avg for students)
  static const int avgReadingSpeed = 200;
}
