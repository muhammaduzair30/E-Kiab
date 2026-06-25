import 'package:ekitab/features/quiz/presentation/providers/quiz_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';


class TeacherResultsScreen extends ConsumerWidget {
  const TeacherResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(teacherQuizResultsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Performance Evaluation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: resultsAsync.when(
        data: (attempts) {
          if (attempts.isEmpty) {
            return Center(
              child: Text('No quiz attempts yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            );
          }

          // Aggregate attempts by quiz
          final Map<String, List<Map<String, dynamic>>> groupedAttempts = {};
          for (var attempt in attempts) {
            final quizId = attempt['quizId'] ?? 'unknown';
            groupedAttempts.putIfAbsent(quizId, () => []).add(attempt);
          }

          final aggregatedData = groupedAttempts.entries.map((entry) {
            final attempts = entry.value;
            final quizTitle = attempts.first['quizTitle'] ?? 'Unknown Quiz';
            
            double totalScore = 0;
            int totalQuestions = attempts.first['totalQuestions'] ?? 1;
            
            for (var a in attempts) {
              totalScore += a['score'] ?? 0;
            }
            
            double avgScore = totalScore / attempts.length;
            double avgPercentage = avgScore / totalQuestions;

            return {
              'quizId': entry.key,
              'quizTitle': quizTitle,
              'attemptCount': attempts.length,
              'avgScore': avgScore,
              'totalQuestions': totalQuestions,
              'avgPercentage': avgPercentage,
              'attempts': attempts,
            };
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: aggregatedData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final data = aggregatedData[i];
              final double percentage = data['avgPercentage'] as double;
              
              Color scoreColor = AppColors.success;
              if (percentage < 0.5) scoreColor = AppColors.error;
              else if (percentage < 0.8) scoreColor = AppColors.secondary;

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(percentage * 100).round()}%',
                        style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(data['quizTitle'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('${data['attemptCount']} Attempts',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(data['avgScore'] as double).toStringAsFixed(1)} / ${data['totalQuestions']}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Avg Score', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                  children: [
                    const Divider(height: 1),
                    ...(data['attempts'] as List<dynamic>).map((attempt) {
                      final p = (attempt['score'] / attempt['totalQuestions']);
                      Color pColor = AppColors.success;
                      if (p < 0.5) pColor = AppColors.error;
                      else if (p < 0.8) pColor = AppColors.secondary;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text('Student ID: ${attempt['userId']}', style: const TextStyle(fontSize: 13)),
                        trailing: Text(
                          '${attempt['score']}/${attempt['totalQuestions']} (${(p * 100).round()}%)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: pColor, fontSize: 13),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }
}
