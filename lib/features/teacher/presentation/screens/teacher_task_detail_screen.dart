import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class TeacherTaskDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;

  const TeacherTaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TeacherTaskDetailScreen> createState() => _TeacherTaskDetailScreenState();
}

class _TeacherTaskDetailScreenState extends ConsumerState<TeacherTaskDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRatingDialog(BuildContext context, String studentId, String studentName) {
    final int? totalMarks = widget.task['totalMarks'];
    int rating = 5;
    final scoreCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    bool isSubmitting = false;

    // Pre-fill if already rated
    final ratings = widget.task['ratings'] as Map<String, dynamic>? ?? {};
    if (ratings.containsKey(studentId)) {
      rating = ratings[studentId]['rating'] as int? ?? 5;
      scoreCtrl.text = rating.toString();
      feedbackCtrl.text = ratings[studentId]['feedback'] as String? ?? '';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Rate $studentName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalMarks != null)
                  TextField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Score (out of $totalMarks)',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = index + 1);
                        },
                      );
                    }),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackCtrl,
                  decoration: InputDecoration(
                    labelText: 'Feedback (Optional)',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  int finalScore = rating;
                  if (totalMarks != null) {
                    final parsed = int.tryParse(scoreCtrl.text);
                    if (parsed == null || parsed < 0 || parsed > totalMarks) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid score'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    finalScore = parsed;
                  }

                  setDialogState(() => isSubmitting = true);
                  try {
                    await ref.read(teacherTaskListProvider.notifier).rateStudentTask(
                          widget.task['id'],
                          studentId,
                          finalScore,
                          feedbackCtrl.text,
                        );
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    // Watch tasks from provider to get updated ratings dynamically
    final tasksState = ref.watch(teacherTaskListProvider);
    final updatedTask = tasksState.tasks.firstWhere(
      (t) => t['id'] == widget.task['id'],
      orElse: () => widget.task,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(updatedTask['title'] ?? 'Task Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Remaining'),
          ],
        ),
      ),
      body: studentsAsync.when(
        data: (students) {
          final completedBy = List<String>.from(updatedTask['completedBy'] ?? []);
          final completedStudents = students.where((s) => completedBy.contains(s['id'])).toList();
          final remainingStudents = students.where((s) => !completedBy.contains(s['id'])).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Completed Tab
              completedStudents.isEmpty
                  ? Center(child: Text('No students have completed this task yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: completedStudents.length,
                      itemBuilder: (context, index) {
                        final student = completedStudents[index];
                        final ratings = updatedTask['ratings'] as Map<String, dynamic>? ?? {};
                        final hasRated = ratings.containsKey(student['id']);
                        final ratingScore = hasRated ? ratings[student['id']]['rating'] : 0;
                        final int? totalMarks = updatedTask['totalMarks'];
                        final submissions = updatedTask['submissions'] as Map<String, dynamic>? ?? {};
                        final hasSubmission = submissions.containsKey(student['id']);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          title: Text(student['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: hasRated
                              ? (totalMarks != null
                                  ? Text('Score: $ratingScore / $totalMarks', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))
                                  : Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < ratingScore ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      )),
                                    ))
                              : const Text('Not rated yet', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasSubmission && submissions[student['id']]['fileUrl'] != null)
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: AppColors.secondary),
                                  onPressed: () async {
                                    final url = Uri.parse(submissions[student['id']]['fileUrl']);
                                    try {
                                      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open file. No app found to handle this link.'), backgroundColor: AppColors.error),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error opening file: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ElevatedButton(
                                onPressed: () => _showRatingDialog(context, student['id'], student['name'] ?? 'Student'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasRated ? Theme.of(context).colorScheme.surfaceContainerHighest : AppColors.primary,
                                  foregroundColor: hasRated ? Theme.of(context).colorScheme.onSurface : Colors.white,
                                  elevation: 0,
                                ),
                                child: Text(hasRated ? 'Edit' : 'Rate'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              
              // Remaining Tab
              remainingStudents.isEmpty
                  ? Center(child: Text('All students have completed this task!', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: remainingStudents.length,
                      itemBuilder: (context, index) {
                        final student = remainingStudents[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            child: const Icon(Icons.person_outline, color: Colors.grey),
                          ),
                          title: Text(student['name'] ?? 'Unknown Student'),
                          subtitle: const Text('Not completed'),
                        );
                      },
                    ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading students: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }
}
