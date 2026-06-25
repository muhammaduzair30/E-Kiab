
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StudentTasksScreen extends ConsumerStatefulWidget {
  const StudentTasksScreen({super.key});

  @override
  ConsumerState<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends ConsumerState<StudentTasksScreen> {
  void _showUploadDialog(Map<String, dynamic> task) {
    bool isSubmitting = false;
    Uint8List? selectedFileBytes;
    String? selectedFileName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Submit Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['title'] ?? 'Untitled Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Attach your completed assignment document here.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          withData: true,
                        );
                        if (result != null && result.files.single.bytes != null) {
                          setDialogState(() {
                            selectedFileBytes = result.files.single.bytes;
                            selectedFileName = result.files.single.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Attach File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        elevation: 0,
                      ),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedFileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setDialogState(() {
                            selectedFileBytes = null;
                            selectedFileName = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (isSubmitting || selectedFileBytes == null) ? null : () async {
                  setDialogState(() => isSubmitting = true);
                  try {
                    await ref.read(studentTaskListProvider.notifier).submitTask(
                      task['id'],
                      selectedFileBytes!,
                      selectedFileName!,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment submitted successfully!'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentTaskListProvider);
    final uid = ref.watch(authStateProvider).user?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: state.isLoading && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)))
              : state.tasks.isEmpty
                  ? Center(child: Text('You have no tasks! Relax.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(studentTaskListProvider.notifier).loadTasks(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                      itemCount: state.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final task = state.tasks[i];
                        final isReading = task['type'] == 'reading';
                        final List completedBy = task['completedBy'] ?? [];
                        final isCompleted = uid != null && completedBy.contains(uid);
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isReading ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(isReading ? Icons.menu_book_rounded : Icons.assignment_rounded, 
                                      color: isReading ? AppColors.secondary : AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text((task['title'] ?? 'Untitled Task').trim(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        if (isReading)
                                          const Text('Reading Assignment', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if ((task['description'] ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  (task['description'] ?? '').trim(), 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4)
                                ),
                              ],
                              if (isCompleted && task['ratings']?[uid] != null) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Teacher Remarks'),
                                        content: SingleChildScrollView(
                                          child: Text((task['ratings'][uid]['feedback'] ?? 'No additional remarks.').trim(), style: const TextStyle(height: 1.5)),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Teacher Score: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13)),
                                            if (task['totalMarks'] != null)
                                              Text('${task['ratings'][uid]['rating']} / ${task['totalMarks']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13))
                                            else
                                              ...List.generate(5, (idx) => Icon(
                                                idx < (task['ratings'][uid]['rating'] as int? ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                                                color: Colors.amber,
                                                size: 16,
                                              )),
                                          ],
                                        ),
                                        if ((task['ratings'][uid]['feedback'] as String?)?.trim().isNotEmpty == true) ...[
                                          const SizedBox(height: 6),
                                          Text('"${(task['ratings'][uid]['feedback'] as String).trim()}"', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isReading && task['bookId'] != null) ...[
                                    ElevatedButton.icon(
                                      onPressed: () {
                                          context.pushNamed(
                                          AppRoutes.bookReader,
                                          pathParameters: {'id': task['bookId']},
                                          queryParameters: task['chapterId'] != null ? {'chapterId': task['chapterId']} : <String, dynamic>{},
                                        );
                                      },
                                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                                      label: const Text('Start Reading'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (isCompleted)
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        if (task['submissions'] != null && task['submissions'][uid] != null && task['submissions'][uid]['fileUrl'] != null) {
                                          final url = Uri.parse(task['submissions'][uid]['fileUrl']);
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
                                        }
                                      },
                                      icon: Icon(
                                        task['submissions'] != null && task['submissions'][uid] != null ? Icons.attach_file : Icons.check_circle_rounded, 
                                        size: 16
                                      ),
                                      label: Text(task['submissions'] != null && task['submissions'][uid] != null ? 'View Submitted Doc' : 'Completed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                        foregroundColor: AppColors.success,
                                        elevation: 0,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else if (!isReading)
                                    ElevatedButton.icon(
                                      onPressed: () => _showUploadDialog(task),
                                      icon: const Icon(Icons.upload_file, size: 16),
                                      label: const Text('Submit Assignment'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(studentTaskListProvider.notifier).markTaskComplete(task['id']);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Marked as complete!'), backgroundColor: AppColors.success),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        foregroundColor: AppColors.primary,
                                        elevation: 0,
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      child: const Text('Mark Complete'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    ));
  }
}
