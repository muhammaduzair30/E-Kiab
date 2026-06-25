// lib/features/student/presentation/screens/student_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ebook/presentation/providers/book_provider.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookListProvider.notifier).loadBooks();
      ref.read(quizListProvider.notifier).loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              child: user?.profileImage != null
                                  ? null
                                  : Text(
                                      user?.initials ?? 'S',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'السلام علیکم, ${user?.displayName}!',
                                    style: const TextStyle(
                                      fontFamily: 'NotoNastaliqUrdu',
                                      fontFamilyFallback: [
                                        'Poppins',
                                        'Roboto',
                                        'sans-serif'
                                      ],
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                  Text(
                                    'What are we learning today?',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.search),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDark ? [] : const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text('Search books, subjects, quizzes...',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick actions
                _QuickActionsRow(),
                const SizedBox(height: 24),

                // Subjects grid
                _SectionHeader(
                    title: 'Your Subjects',
                    subtitle: 'Tap to explore',
                    actionLabel: 'All Books',
                    onAction: () => context.go(AppRoutes.bookList)),
                const SizedBox(height: 12),
                _SubjectGrid(),
                const SizedBox(height: 24),

                // Continue reading
                const _SectionHeader(
                    title: 'Continue Reading',
                    subtitle: 'Pick up where you left off'),
                const SizedBox(height: 12),
                _ContinueReadingList(),
                const SizedBox(height: 24),

                // Recent quizzes
                _SectionHeader(
                  title: 'Practice Quizzes',
                  actionLabel: 'See All',
                  onAction: () => context.go(AppRoutes.quizList),
                ),
                const SizedBox(height: 12),
                _QuizSuggestions(),
                const SizedBox(height: 80), // bottom nav padding
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actions = [
      (
        Icons.assignment_rounded,
        'Tasks',
        AppColors.primary,
        AppRoutes.studentTasks
      ),
      (Icons.note_alt_rounded, 'Notes', Colors.orange, AppRoutes.studentNotes),
      (Icons.smart_toy_rounded, 'AI Tutor', Colors.indigo, AppRoutes.aiChat),
      (Icons.quiz_rounded, 'Quizzes', AppColors.secondary, AppRoutes.quizList),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map((a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => context.push(a.$4),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isDark ? [] : [
                              BoxShadow(
                                  color: a.$3.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                            border: Border.all(
                                color: a.$3.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: Icon(a.$1, color: a.$3, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(a.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle, actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader(
      {required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    actionLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Subject Grid ─────────────────────────────────────────────────────────────
class _SubjectGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookListProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Extract unique subjects from books
    final Set<String> uniqueSubjects = {};
    for (var book in state.books) {
      final subjectStr = book['subject'] is Map
          ? (book['subject']['name'] ?? 'General')
          : (book['subject']?.toString() ?? 'General');
      uniqueSubjects.add(subjectStr);
    }

    if (uniqueSubjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text("No subjects available yet.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }

    final subjectConfig = {
      'Mathematics': ('🔢', AppColors.mathColor),
      'Maths': ('🔢', AppColors.mathColor),
      'Physics': ('⚛️', AppColors.physicsColor),
      'Chemistry': ('🧪', AppColors.chemColor),
      'Biology': ('🌱', AppColors.bioColor),
      'Science': ('🔬', Colors.teal),
      'English': ('📖', AppColors.englishColor),
      'Urdu': ('📝', AppColors.urduColor),
      'Computer Science': ('💻', Colors.blueGrey),
      'Computer': ('💻', Colors.blueGrey),
      'History': ('🏺', Colors.brown),
      'Geography': ('🌍', Colors.green),
      'General': ('📚', AppColors.primary),
    };

    final activeSubjects = uniqueSubjects.map((name) {
      final config = subjectConfig[name] ?? ('📚', AppColors.primary);
      return (name, config.$1, config.$2);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2, // horizontal pills
      ),
      itemCount: activeSubjects.length,
      itemBuilder: (_, i) {
        final sub = activeSubjects[i];
        return GestureDetector(
          onTap: () => context.push(AppRoutes.bookList),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sub.$3.withValues(alpha: 0.05),
                  sub.$3.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sub.$3.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(sub.$2, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(sub.$1,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sub.$3.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Continue Reading ─────────────────────────────────────────────────────────
class _ContinueReadingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    if (state.isLoading) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      );
    }

    if (state.books.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ],
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.auto_stories_rounded,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text("Your reading journey starts here!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("Explore the library to find your first book.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.bookList),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Browse Library'),
            )
          ],
        ),
      );
    }

    final recentBooks = state.books.take(5).toList();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: recentBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final book = recentBooks[i];
          final subject = book['subject'] is Map
              ? (book['subject']['name'] ?? 'General')
              : (book['subject']?.toString() ?? 'General');
          return GestureDetector(
            onTap: () => context.pushNamed(AppRoutes.bookDetail,
                pathParameters: {'id': book['_id'] ?? ''}),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: book['coverImage'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(book['coverImage'],
                                fit: BoxFit.cover),
                          )
                        : const Icon(Icons.book, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(subject,
                              style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 8),
                        Text(book['title'] ?? 'Untitled',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.3)),
                        const Spacer(),
                        Row(
                          children: [
                            const Text('Continue Reading',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14,
                                color:
                                    AppColors.primary.withValues(alpha: 0.8)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Quiz Suggestions ─────────────────────────────────────────────────────────
class _QuizSuggestions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(quizListProvider);

    if (state.isLoading) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (state.quizzes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text("No quizzes available yet.",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    final recentQuizzes = state.quizzes.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentQuizzes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final quiz = recentQuizzes[i];
        final title = quiz['title'] ?? 'Quiz';
        final subject = quiz['subject']?['name'] ?? 'General';
        final questions = quiz['questions'] as List<dynamic>? ?? [];

        return GestureDetector(
          onTap: () {
            if (questions.isEmpty) return;
            ref.read(quizProvider.notifier).startQuiz(
                  quiz['_id'] ?? 'unknown_id',
                  title,
                  List<Map<String, dynamic>>.from(questions),
                );
            context.pushNamed(AppRoutes.quiz);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              boxShadow: isDark ? [] : const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Icon(Icons.subject_rounded,
                              size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          Text(subject,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13)),
                          const SizedBox(width: 8),
                          Icon(Icons.format_list_bulleted_rounded,
                              size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          Text('${questions.length} Questions',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
