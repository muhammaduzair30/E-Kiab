import 'package:ekitab/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../ebook/presentation/providers/book_provider.dart';

enum TaskType { general, reading }

class TeacherTasksScreen extends ConsumerStatefulWidget {
  const TeacherTasksScreen({super.key});

  @override
  ConsumerState<TeacherTasksScreen> createState() => _TeacherTasksScreenState();
}

class _TeacherTasksScreenState extends ConsumerState<TeacherTasksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();
  
  TaskType _taskType = TaskType.general;
  String? _selectedBookId;
  String? _selectedChapterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookState = ref.read(bookListProvider);
      if (bookState.books.isEmpty && !bookState.isLoading) {
        ref.read(bookListProvider.notifier).loadBooks();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  void _showAddTaskDialog() {
    setState(() {
      _taskType = TaskType.general;
      _selectedBookId = null;
      _selectedChapterId = null;
    });

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bookState = ref.watch(bookListProvider);
          
          return AlertDialog(
            title: const Text('New Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<TaskType>(
                      segments: const [
                        ButtonSegment(value: TaskType.general, label: Text('General')),
                        ButtonSegment(value: TaskType.reading, label: Text('Reading')),
                      ],
                      selected: {_taskType},
                      onSelectionChanged: (Set<TaskType> newSelection) {
                        setDialogState(() => _taskType = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      decoration: _inputDeco('Task Title', 'e.g., Complete Exercises'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      decoration: _inputDeco('Description', 'Detailed instructions...'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _marksCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Enter valid marks' : null,
                      decoration: _inputDeco('Total Marks', 'e.g., 10, 20, 50'),
                    ),
                    if (_taskType == TaskType.reading) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _inputDeco('Select Book', 'Choose a book'),
                        value: _selectedBookId,
                        items: bookState.books.map((b) => DropdownMenuItem(
                          value: b['_id'] as String,
                          child: Text(b['title'] ?? 'Unknown Book'),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            _selectedBookId = val;
                            _selectedChapterId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          List<Map<String, dynamic>> chapters = [];
                          if (_selectedBookId != null) {
                            final selectedBook = bookState.books.firstWhere((b) => b['_id'] == _selectedBookId);
                            chapters = (selectedBook['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                          }
                          return DropdownButtonFormField<String>(
                            decoration: _inputDeco('Select Chapter', 'Choose a chapter'),
                            value: _selectedChapterId,
                            items: chapters.map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['title'] ?? 'Chapter'),
                            )).toList(),
                            onChanged: chapters.isEmpty ? null : (val) {
                              setDialogState(() => _selectedChapterId = val);
                            },
                          );
                        }
                      ),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx), 
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    if (_taskType == TaskType.reading && (_selectedBookId == null || _selectedChapterId == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a book and chapter.'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    
                    setDialogState(() => isSubmitting = true);
                    
                    try {
                      await ref.read(teacherTaskListProvider.notifier).addTask(
                        _titleCtrl.text, 
                        _descCtrl.text,
                        type: _taskType == TaskType.reading ? 'reading' : 'general',
                        bookId: _selectedBookId,
                        chapterId: _selectedChapterId,
                        totalMarks: int.tryParse(_marksCtrl.text),
                      );
                      _titleCtrl.clear();
                      _descCtrl.clear();
                      _marksCtrl.clear();
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to assign task: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text('Assign'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherTaskListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: state.isLoading && state.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)))
              : state.tasks.isEmpty
                  ? Center(child: Text('No tasks created yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(teacherTaskListProvider.notifier).loadTasks(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                      itemCount: state.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final task = state.tasks[i];
                        final isReading = task['type'] == 'reading';
                        return InkWell(
                          onTap: () {
                            context.pushNamed(
                              AppRoutes.teacherTaskDetail,
                              extra: task,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: (isReading ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.2)),
                            ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: isReading ? AppColors.secondary : AppColors.primary, width: 5)),
                            ),
                            padding: const EdgeInsets.all(16),
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
                                        Text(task['title'] ?? 'Untitled Task',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (isReading)
                                          const Text('Reading Assignment', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(task['description'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Completed by: ${(task['completedBy'] as List?)?.length ?? 0} students',
                                      style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )));
                      },
                    ),
                  ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
