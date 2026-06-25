import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/quiz_provider.dart';

class QuizHistoryScreen extends ConsumerWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(quizHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (attempts) {
          if (attempts.isEmpty) {
            return Center(
              child: Text(
                'No quizzes taken yet!\nStart reading and take a quiz to see your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            );
          }

          // Calculate Analytics
          int totalQuizzes = attempts.length;
          int totalCorrect = 0;
          int totalQuestions = 0;
          
          for (var attempt in attempts) {
            totalCorrect += (attempt['score'] as int?) ?? 0;
            totalQuestions += (attempt['totalQuestions'] as int?) ?? 1; // avoid /0
          }
          
          final averageAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0.0;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(quizHistoryProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Dashboard Analytics Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Overall Accuracy', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('${averageAccuracy.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(label: 'Quizzes Taken', value: '$totalQuizzes'),
                          _StatColumn(label: 'Total Correct', value: '$totalCorrect'),
                          _StatColumn(label: 'Questions', value: '$totalQuestions'),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Recent Attempts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 16),

                // History List
                ...attempts.map((attempt) {
                  final score = attempt['score'] as int? ?? 0;
                  final total = attempt['totalQuestions'] as int? ?? 1;
                  final pct = (score / total) * 100;
                  final passed = pct >= 50;
                  final title = attempt['quizTitle'] as String? ?? 'Untitled Quiz';
                  
                  // Handle Firestore Timestamp formatting securely
                  String dateStr = 'Recent';
                  try {
                    final ts = attempt['timestamp'];
                    if (ts is Timestamp) {
                      dateStr = DateFormat('MMM d, yyyy • h:mm a').format(ts.toDate());
                    }
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: passed ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${pct.toInt()}%', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444)
                              )
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 4),
                              Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$score / $total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                            Text('Score', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
