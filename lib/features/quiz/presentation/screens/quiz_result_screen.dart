// lib/features/quiz/presentation/screens/quiz_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: Text('No quiz data found')));
    }

    final totalQuestions = state.questions.length;
    final score = state.score;
    final answered = state.selectedAnswers.length;
    final skipped = totalQuestions - answered;
    final wrong = answered - score;
    final pct = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
    final passed = pct >= 50;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
          // Premium Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: passed
                    ? [const Color(0xFF0D9488), const Color(0xFF047857)] // Premium Teal/Green
                    : [const Color(0xFFE11D48), const Color(0xFFBE123C)], // Premium Rose/Red
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: (passed ? const Color(0xFF047857) : const Color(0xFFBE123C)).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 16,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  passed ? 'Outstanding!' : 'Keep Trying!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  passed ? 'You successfully conquered this quiz.' : 'You did not pass this time, but learning takes time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),

                // Animated Score Circle
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: pct),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Score',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                        label: 'Correct',
                        value: '$score',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Wrong',
                        value: '$wrong',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                      if (skipped > 0) ...[
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Skipped',
                          value: '$skipped',
                          icon: Icons.remove_circle_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Performance bar
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                            _PerformanceBadge(percentage: pct),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: pct / 100),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation(
                                  pct >= 80
                                      ? const Color(0xFF10B981)
                                      : pct >= 50
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444),
                                ),
                                minHeight: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0%', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Passing: 50%', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('100%', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.quizList),
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('All Quizzes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(AppRoutes.studentHome),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Review Answers Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Review Answers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        ...List.generate(state.questions.length, (i) {
                          final q = state.questions[i];
                          final options = q['options'] as List<dynamic>? ?? [];
                          final correctIdx = q['correctAnswerIndex'] as int? ?? 0;
                          final selectedIdx = state.selectedAnswers[i];
                          final isCorrect = selectedIdx == correctIdx;
                          final explanation = q['explanation'] as String?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF10B981).withValues(alpha: 0.05)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle_rounded : (selectedIdx == null ? Icons.remove_circle_rounded : Icons.cancel_rounded),
                                      color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Q${i + 1}', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(q['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, height: 1.4)),
                                const SizedBox(height: 8),
                                if (selectedIdx != null && selectedIdx < options.length)
                                  Text('Your answer: ${options[selectedIdx]}',
                                      style: TextStyle(color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
                                if (selectedIdx == null)
                                  const Text('Skipped', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13)),
                                if (!isCorrect && correctIdx < options.length)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Correct answer: ${options[correctIdx]}',
                                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                if (explanation != null && explanation.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(explanation, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4))),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PerformanceBadge extends StatelessWidget {
  final double percentage;
  const _PerformanceBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    if (percentage >= 90) {
      label = 'Excellent';
      color = const Color(0xFF10B981);
      icon = Icons.workspace_premium_rounded;
    } else if (percentage >= 75) {
      label = 'Great Work';
      color = const Color(0xFF3B82F6);
      icon = Icons.thumb_up_rounded;
    } else if (percentage >= 50) {
      label = 'Good Effort';
      color = const Color(0xFFF59E0B);
      icon = Icons.sentiment_satisfied_rounded;
    } else {
      label = 'Keep Practicing';
      color = const Color(0xFFEF4444);
      icon = Icons.school_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
