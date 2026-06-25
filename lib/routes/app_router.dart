// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/student/presentation/screens/student_home_screen.dart';
import '../features/student/presentation/screens/student_profile_screen.dart';
import '../features/ebook/presentation/screens/book_list_screen.dart';
import '../features/ebook/presentation/screens/book_reader_screen.dart';
import '../features/ebook/presentation/screens/book_detail_screen.dart';
import '../features/quiz/presentation/screens/quiz_list_screen.dart';
import '../features/quiz/presentation/screens/quiz_screen.dart';
import '../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../features/quiz/presentation/screens/quiz_upload_screen.dart';
import '../features/quiz/presentation/screens/quiz_history_screen.dart';
import '../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/teacher/presentation/screens/teacher_home_screen.dart';
import '../features/teacher/presentation/screens/teacher_results_screen.dart';
import '../features/teacher/presentation/screens/teacher_tasks_screen.dart';
import '../features/teacher/presentation/screens/teacher_task_detail_screen.dart';
import '../features/teacher/presentation/screens/teacher_notes_screen.dart';
import '../features/student/presentation/screens/student_tasks_screen.dart';
import '../features/student/presentation/screens/student_notes_screen.dart';
import '../features/quiz/presentation/screens/ai_quiz_generator_screen.dart';

export 'route_names.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      // Only notify GoRouter to redirect if authentication or onboarding status fundamentally changes
      if (previous?.isAuthenticated != next.isAuthenticated || 
          previous?.isOnboarded != next.isOnboarded ||
          previous?.user?.isTeacher != next.user?.isTeacher) {
        notifyListeners();
      }
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isOnboarded = authState.isOnboarded;
    
    final isAuthRoute = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.forgotPassword,
      AppRoutes.otp,
    ].contains(state.matchedLocation);

    // Not onboarded -> onboarding
    if (!isOnboarded && state.matchedLocation != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // Not authenticated -> login
    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.login;
    }

    // Authenticated but on auth route -> redirect to appropriate home
    if (isAuthenticated && isAuthRoute) {
      return authState.user?.isTeacher == true
          ? AppRoutes.teacherHome
          : AppRoutes.studentHome;
    }

    // Role-based route guarding
    if (isAuthenticated) {
      final isTeacher = authState.user?.isTeacher == true;
      final isStudentRoute = state.matchedLocation.startsWith('/student');
      final isTeacherRoute = state.matchedLocation.startsWith('/teacher');

      if (isTeacher && isStudentRoute) {
        return AppRoutes.teacherHome;
      }
      if (!isTeacher && isTeacherRoute) {
        return AppRoutes.studentHome;
      }
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
      ),

      // ─── Student routes ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
              path: AppRoutes.studentHome,
              builder: (_, __) => const StudentHomeScreen()),
          GoRoute(
              path: AppRoutes.studentProfile,
              builder: (_, __) => const StudentProfileScreen()),
          GoRoute(
              path: AppRoutes.bookList,
              builder: (_, __) => const BookListScreen()),
          GoRoute(
            path: AppRoutes.bookDetail,
            name: AppRoutes.bookDetail,
            builder: (_, state) =>
                BookDetailScreen(bookId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.bookReader,
            name: AppRoutes.bookReader,
            builder: (_, state) => BookReaderScreen(
              bookId: state.pathParameters['id']!,
              chapterId: state.uri.queryParameters['chapterId'],
            ),
          ),
          GoRoute(
              path: AppRoutes.quizList,
              builder: (_, __) => const QuizListScreen()),
          GoRoute(
            path: AppRoutes.quiz,
            name: AppRoutes.quiz,
            builder: (_, state) => const QuizScreen(),
          ),
          GoRoute(
            path: AppRoutes.quizResult,
            name: AppRoutes.quizResult,
            builder: (_, state) => const QuizResultScreen(),
          ),
          GoRoute(
            path: AppRoutes.quizUpload,
            name: AppRoutes.quizUpload,
            builder: (_, __) => const QuizUploadScreen(),
          ),
          GoRoute(
            path: AppRoutes.quizHistory,
            name: AppRoutes.quizHistory,
            builder: (_, __) => const QuizHistoryScreen(),
          ),
          GoRoute(
              path: AppRoutes.aiChat, builder: (_, __) => const AiChatScreen()),
          GoRoute(
              path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
          GoRoute(
              path: AppRoutes.studentTasks,
              builder: (_, __) => const StudentTasksScreen()),
          GoRoute(
              path: AppRoutes.studentNotes,
              builder: (_, __) => const StudentNotesScreen()),
        ],
      ),

      // ─── Teacher routes ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
              path: AppRoutes.teacherHome,
              builder: (_, __) => const TeacherHomeScreen()),
          GoRoute(
              path: AppRoutes.teacherBooks,
              builder: (_, __) => const BookListScreen()),
          GoRoute(
            path: AppRoutes.teacherBookDetail,
            name: AppRoutes.teacherBookDetail,
            builder: (_, state) =>
                BookDetailScreen(bookId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.teacherBookReader,
            name: AppRoutes.teacherBookReader,
            builder: (_, state) => BookReaderScreen(
              bookId: state.pathParameters['id']!,
              chapterId: state.uri.queryParameters['chapterId'],
            ),
          ),
          GoRoute(
              path: AppRoutes.teacherQuizzes,
              builder: (_, __) => const QuizListScreen()),
          GoRoute(
            path: AppRoutes.teacherQuizUpload,
            name: AppRoutes.teacherQuizUpload,
            builder: (_, __) => const QuizUploadScreen(),
          ),
          GoRoute(
              path: AppRoutes.teacherAiQuizGenerator,
              builder: (_, __) => const AiQuizGeneratorScreen()),
          GoRoute(
              path: AppRoutes.teacherResults,
              builder: (_, __) => const TeacherResultsScreen()),
          GoRoute(
              path: AppRoutes.teacherTasks,
              builder: (_, __) => const TeacherTasksScreen()),
          GoRoute(
            path: AppRoutes.teacherTaskDetail,
            name: AppRoutes.teacherTaskDetail,
            builder: (context, state) {
              final task = state.extra as Map<String, dynamic>?;
              if (task == null) return const TeacherTasksScreen();
              return TeacherTaskDetailScreen(task: task);
            },
          ),
          GoRoute(
              path: AppRoutes.teacherNotes,
              builder: (_, __) => const TeacherNotesScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            TextButton(
                onPressed: () => context.go(AppRoutes.studentHome),
                child: const Text('Go Home')),
          ],
        ),
      ),
    ),
  );
});

// ─── Shell scaffolds (side nav) ────────────────────────────────────────────

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: const _StudentBottomNav(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _StudentSideNav(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StudentSideNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = [
      (AppRoutes.studentHome, Icons.home_rounded, Icons.home_outlined, 'Home'),
      (
        AppRoutes.bookList,
        Icons.menu_book_rounded,
        Icons.menu_book_outlined,
        'Books'
      ),
      (
        AppRoutes.studentTasks,
        Icons.assignment_rounded,
        Icons.assignment_outlined,
        'Tasks'
      ),
      (
        AppRoutes.studentNotes,
        Icons.note_rounded,
        Icons.note_outlined,
        'Notes'
      ),
      (AppRoutes.quizList, Icons.quiz_rounded, Icons.quiz_outlined, 'Quizzes'),
      (
        AppRoutes.aiChat,
        Icons.smart_toy_rounded,
        Icons.smart_toy_outlined,
        'AI Tutor'
      ),
      (
        AppRoutes.studentProfile,
        Icons.person_rounded,
        Icons.person_outline,
        'Profile'
      ),
    ];

    int currentIndex = items.indexWhere((i) => location.startsWith(i.$1));
    if (currentIndex < 0) currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Premium dark sleek sidebar
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          )
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        unselectedIconTheme:
            IconThemeData(color: Colors.white.withValues(alpha: 0.5)),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
        unselectedLabelTextStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        selectedLabelTextStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(items[i].$1),
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
        ),
        destinations: items
            .map((i) => NavigationRailDestination(
                  icon: Icon(i.$3),
                  selectedIcon: Icon(i.$2),
                  label: Text(i.$4),
                ))
            .toList(),
      ),
    );
  }
}

class _StudentBottomNav extends ConsumerWidget {
  const _StudentBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    // For mobile, we might want to prioritize the most important tabs
    // to avoid overcrowding the bottom bar. Max 5 items is recommended.
    final items = [
      (AppRoutes.studentHome, Icons.home_rounded, Icons.home_outlined, 'Home'),
      (
        AppRoutes.bookList,
        Icons.menu_book_rounded,
        Icons.menu_book_outlined,
        'Books'
      ),
      (
        AppRoutes.aiChat,
        Icons.smart_toy_rounded,
        Icons.smart_toy_outlined,
        'AI Tutor'
      ),
      (AppRoutes.quizList, Icons.quiz_rounded, Icons.quiz_outlined, 'Quizzes'),
      (
        AppRoutes.studentProfile,
        Icons.person_rounded,
        Icons.person_outline,
        'Profile'
      ),
    ];

    int currentIndex = items.indexWhere((i) => location.startsWith(i.$1));
    if (currentIndex < 0) currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(items[i].$1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items
            .map((i) => NavigationDestination(
                  icon: Icon(i.$3, color: Colors.grey[600]),
                  selectedIcon: Icon(i.$2, color: const Color(0xFF3B82F6)),
                  label: i.$4,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Teacher Shell ────────────────────────────────────────────────────────
class TeacherShell extends StatelessWidget {
  final Widget child;
  const TeacherShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: const _TeacherBottomNav(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _TeacherSideNav(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TeacherSideNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = [
      (
        AppRoutes.teacherHome,
        Icons.dashboard_rounded,
        Icons.dashboard_outlined,
        'Dashboard'
      ),
      (
        AppRoutes.teacherBooks,
        Icons.menu_book_rounded,
        Icons.menu_book_outlined,
        'Books'
      ),
      (
        AppRoutes.teacherTasks,
        Icons.assignment_rounded,
        Icons.assignment_outlined,
        'Tasks'
      ),
      (
        AppRoutes.teacherNotes,
        Icons.note_rounded,
        Icons.note_outlined,
        'Notes'
      ),
      (
        AppRoutes.teacherQuizzes,
        Icons.quiz_rounded,
        Icons.quiz_outlined,
        'Quizzes'
      ),
      (
        AppRoutes.teacherAiQuizGenerator,
        Icons.auto_awesome_rounded,
        Icons.auto_awesome_outlined,
        'AI Quiz'
      ),
      (
        AppRoutes.teacherResults,
        Icons.analytics_rounded,
        Icons.analytics_outlined,
        'Results'
      ),
    ];

    int currentIndex = items.indexWhere((i) => location.startsWith(i.$1));
    if (currentIndex < 0) currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF312E81), // Distinct Indigo for Teacher Mode
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          )
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        unselectedIconTheme:
            IconThemeData(color: Colors.white.withValues(alpha: 0.5)),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
        unselectedLabelTextStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        selectedLabelTextStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(items[i].$1),
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
        ),
        destinations: items
            .map((i) => NavigationRailDestination(
                  icon: Icon(i.$3),
                  selectedIcon: Icon(i.$2),
                  label: Text(i.$4),
                ))
            .toList(),
      ),
    );
  }
}

class _TeacherBottomNav extends ConsumerWidget {
  const _TeacherBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    // For mobile, pick the 5 most important tabs
    final items = [
      (
        AppRoutes.teacherHome,
        Icons.dashboard_rounded,
        Icons.dashboard_outlined,
        'Home'
      ),
      (
        AppRoutes.teacherTasks,
        Icons.assignment_rounded,
        Icons.assignment_outlined,
        'Tasks'
      ),
      (
        AppRoutes.teacherNotes,
        Icons.note_rounded,
        Icons.note_outlined,
        'Notes'
      ),
      (
        AppRoutes.teacherQuizzes,
        Icons.quiz_rounded,
        Icons.quiz_outlined,
        'Quizzes'
      ),
      (
        AppRoutes.teacherResults,
        Icons.analytics_rounded,
        Icons.analytics_outlined,
        'Results'
      ),
    ];

    int currentIndex = items.indexWhere((i) => location.startsWith(i.$1));
    if (currentIndex < 0) currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.15), // Indigo indicator for teacher
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(items[i].$1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items
            .map((i) => NavigationDestination(
                  icon: Icon(i.$3, color: Colors.grey[600]),
                  selectedIcon: Icon(i.$2, color: const Color(0xFF4F46E5)), // Indigo for teacher
                  label: i.$4,
                ))
            .toList(),
      ),
    );
  }
}
