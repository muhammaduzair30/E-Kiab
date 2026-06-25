// lib/routes/route_names.dart
class AppRoutes {
  AppRoutes._();

  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';

  // Student
  static const studentHome = '/student/home';
  static const studentProfile = '/student/profile';
  static const bookList = '/student/books';
  static const bookDetail = '/student/books/:id';
  static const bookReader = '/student/books/:id/read';
  static const quizList = '/student/quizzes';
  static const quiz = '/student/quiz';
  static const quizResult = '/student/quiz/result';
  static const quizUpload = '/student/quiz/upload';
  static const quizHistory = '/student/quiz/history';
  static const aiChat = '/student/ai-chat';
  static const search = '/student/search';

  // Teacher
  static const teacherHome = '/teacher/home';
  static const teacherProfile = '/teacher/profile';
  static const teacherBooks = '/teacher/books';
  static const teacherBookDetail = '/teacher/books/:id';
  static const teacherBookReader = '/teacher/books/:id/read';
  static const teacherQuizzes = '/teacher/quizzes';
  static const teacherQuizUpload = '/teacher/quiz/upload';
  static const teacherAiQuizGenerator = '/teacher/quiz/ai-generator';
  static const teacherResults = '/teacher/results';
  static const teacherTasks = '/teacher/tasks';
  static const teacherTaskDetail = '/teacher/tasks/detail';
  static const teacherNotes = '/teacher/notes';

  // Student new features
  static const studentTasks = '/student/tasks';
  static const studentNotes = '/student/notes';
}
