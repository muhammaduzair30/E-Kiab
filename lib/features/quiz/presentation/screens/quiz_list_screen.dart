// lib/features/quiz/presentation/screens/quiz_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizListProvider.notifier).loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizListProvider);
    final authState = ref.watch(authStateProvider);
    final isTeacher = authState.user?.isTeacher == true;
    final historyAsync = ref.watch(quizHistoryProvider);
    final history = historyAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quizzes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (!isTeacher)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.pushNamed(AppRoutes.quizHistory),
              tooltip: 'My Progress',
            ),
        ],
      ),
      body: state.isLoading
          ? _buildShimmer()
          : state.error != null
              ? _buildError(state.error!)
              : state.quizzes.isEmpty
                  ? _buildEmpty(isTeacher)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(quizListProvider.notifier).loadQuizzes(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.quizzes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final quiz = state.quizzes[i];
                          final attempt = history.where((a) => a['quizId'] == quiz['_id']).firstOrNull;
                          return _QuizCard(quiz: quiz, attempt: attempt);
                        },
                      ),
                    ),
      floatingActionButton: isTeacher ? FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.teacherQuizUpload),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Create Quiz'),
      ) : null,
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceVariant,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isTeacher) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No quizzes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(isTeacher ? 'Create a quiz or generate one from a textbook chapter' : 'Your teachers have not assigned any quizzes yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          if (isTeacher)
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.teacherQuizUpload),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Quiz'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load quizzes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(quizListProvider.notifier).loadQuizzes(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends ConsumerWidget {
  final Map<String, dynamic> quiz;
  final Map<String, dynamic>? attempt;
  const _QuizCard({required this.quiz, this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = quiz['title'] ?? 'Quiz';
    final subject = quiz['subject']?['name'] ?? 'General';
    final questions = quiz['questions'] as List<dynamic>? ?? [];
    final totalQ = questions.length;
    final timeLimit = quiz['timeLimit'];
    final difficulty = quiz['difficulty'] ?? 'medium';
    final authState = ref.watch(authStateProvider);
    final isTeacher = authState.user?.isTeacher == true;

    Color diffColor;
    switch (difficulty) {
      case 'easy':
        diffColor = AppColors.success;
        break;
      case 'hard':
        diffColor = AppColors.error;
        break;
      case 'adaptive':
        diffColor = const Color(0xFF8B5CF6); // Purple for AI-generated
        break;
      default:
        diffColor = AppColors.warning;
    }

    return GestureDetector(
      onTap: () {
        if (questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This quiz has no questions.'), backgroundColor: AppColors.error),
          );
          return;
        }

        if (isTeacher) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quizzes can only be attempted by students.'),
              backgroundColor: AppColors.info,
            ),
          );
          return;
        }

        if (attempt != null) {
          // View result
          final firestoreAnswers = attempt!['selectedAnswers'] as Map<String, dynamic>? ?? {};
          ref.read(quizProvider.notifier).viewAttempt(
            quiz['_id'] ?? 'unknown_id',
            title,
            List<Map<String, dynamic>>.from(questions),
            firestoreAnswers,
          );
          context.pushNamed(AppRoutes.quizResult);
        } else {
          // Start quiz
          ref.read(quizProvider.notifier).startQuiz(
            quiz['_id'] ?? 'unknown_id',
            title,
            List<Map<String, dynamic>>.from(questions),
            timeLimit: timeLimit ?? 15,
          );
          context.pushNamed(AppRoutes.quiz);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subject,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    difficulty[0].toUpperCase() + difficulty.substring(1),
                    style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(icon: Icons.help_outline, label: '$totalQ questions'),
                if (timeLimit != null) ...[
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.timer_outlined, label: '$timeLimit min'),
                ],
                if (attempt != null) ...[
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.check_circle_rounded, label: 'Attempted', color: const Color(0xFF10B981)),
                ],
                const Spacer(),
                if (!isTeacher)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: attempt != null ? const Color(0xFF10B981).withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(attempt != null ? 'View Result →' : 'Start →',
                        style: TextStyle(color: attempt != null ? const Color(0xFF10B981) : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: effectiveColor, fontWeight: color != null ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
