// lib/features/quiz/presentation/screens/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isAutoSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(quizProvider);
      if (state != null && state.timeLimit > 0) {
        _secondsRemaining = state.timeLimit * 60;
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  Future<void> _autoSubmit() async {
    if (!mounted || _isAutoSubmitting) return;
    _isAutoSubmitting = true;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Time's up! Submitting quiz automatically."), backgroundColor: AppColors.error),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    await ref.read(quizProvider.notifier).submitQuiz();
    
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    context.pushReplacementNamed(AppRoutes.quizResult);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    if (state == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Quiz not started')),
      );
    }

    final questions = state.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('No questions available')),
      );
    }

    final q = questions[state.currentQuestionIndex];
    final selectedOptionIndex = state.selectedAnswers[state.currentQuestionIndex];
    final options = q['options'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Chapter Quiz', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (state.currentQuestionIndex + 1) / questions.length,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 4,
          ),

          // Question counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${state.currentQuestionIndex + 1} of ${questions.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                if (state.timeLimit > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondsRemaining < 60 ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(_formatTime(_secondsRemaining), 
                          style: TextStyle(
                            color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Text(q['question'] ?? '',
                        style: TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  ...List.generate(
                    options.length,
                    (i) {
                      final opt = options[i];
                      final selected = selectedOptionIndex == i;
                      return GestureDetector(
                        onTap: () => ref.read(quizProvider.notifier).selectAnswer(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (!selected)
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                                  border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.border,
                                      width: 2),
                                ),
                                child: selected
                                    ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                                    : Center(
                                        child: Text(
                                          String.fromCharCode(65 + i),
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(opt.toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        color: selected
                                            ? AppColors.primary
                                            : Theme.of(context).colorScheme.onSurface)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                if (state.currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () => ref.read(quizProvider.notifier).previousQuestion(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const Spacer(),
                if (state.currentQuestionIndex < questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () => ref.read(quizProvider.notifier).nextQuestion(),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _confirmAndSubmit(context, ref),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSubmit(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(quizProvider.notifier);
    final unanswered = notifier.unansweredCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Quiz?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question${unanswered > 1 ? 's' : ''}. Unanswered questions will be marked as incorrect.\n\nAre you sure you want to submit?'
              : 'Once submitted, you cannot change your answers.\n\nAre you sure you want to submit?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _timer?.cancel();

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await notifier.submitQuiz();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    context.pushReplacementNamed(AppRoutes.quizResult);
  }
}
