import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/quiz_provider.dart';

class QuizQuestionForm {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(4, (_) => TextEditingController());
  int correctAnswerIndex = 0;
  final TextEditingController explanationController = TextEditingController();

  void dispose() {
    questionController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
    explanationController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      "question": questionController.text.trim(),
      "options": optionControllers.map((c) => c.text.trim()).toList(),
      "correctAnswerIndex": correctAnswerIndex,
      "explanation": explanationController.text.trim(),
    };
  }

  bool isValid() {
    if (questionController.text.trim().isEmpty) return false;
    if (optionControllers.any((c) => c.text.trim().isEmpty)) return false;
    return true;
  }
}

class QuizUploadScreen extends ConsumerStatefulWidget {
  const QuizUploadScreen({super.key});

  @override
  ConsumerState<QuizUploadScreen> createState() => _QuizUploadScreenState();
}

class _QuizUploadScreenState extends ConsumerState<QuizUploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<QuizQuestionForm> _questions = [QuizQuestionForm()];
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int _timeLimit = 15;

  void _addQuestion() {
    setState(() {
      _questions.add(QuizQuestionForm());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    }
  }

  Future<void> _validateAndSubmit() async {
    if (_isSubmitting) return; // Prevent double-tap
    if (!_formKey.currentState!.validate()) return;
    
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a quiz title.'), backgroundColor: AppColors.error),
      );
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields and options for Question ${i + 1}.'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final questionsData = _questions.map((q) => q.toJson()).toList();
      await ref.read(quizListProvider.notifier).addQuizManually(title, questionsData, timeLimit: _timeLimit);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully!'), backgroundColor: AppColors.success),
      );
      
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDeco(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz Builder', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border.withValues(alpha: 0.3), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Icon(Icons.edit_document, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Quiz Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    decoration: _inputDeco('Enter a descriptive title for this quiz'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: _inputDeco('Time Limit (minutes)'),
                    value: _timeLimit,
                    items: [5, 10, 15, 20, 30, 45, 60].map((num) => DropdownMenuItem(
                      value: num,
                      child: Text('$num Minutes'),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _timeLimit = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(height: 16),

            // Questions List
            ..._questions.asMap().entries.map((entry) {
              int index = entry.key;
              QuizQuestionForm form = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Question ${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        if (_questions.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _removeQuestion(index),
                            tooltip: 'Remove Question',
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: form.questionController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      maxLines: 2,
                      decoration: _inputDeco('Type your question here...'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('Answers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const Spacer(),
                        Icon(Icons.touch_app_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('Tap letter to mark correct', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    ...List.generate(4, (optionIndex) {
                      final labels = ['A', 'B', 'C', 'D'];
                      final isSelected = form.correctAnswerIndex == optionIndex;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => form.correctAnswerIndex = optionIndex),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 64 : 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.success : (isDark ? AppColors.darkSurfaceVariant : Colors.white),
                                  border: Border.all(color: isSelected ? AppColors.success : Theme.of(context).colorScheme.outline, width: isSelected ? 0 : 1),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                                  ] : null,
                                ),
                                child: isSelected
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                          const SizedBox(width: 2),
                                          Text(
                                            labels[optionIndex],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        labels[optionIndex],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: form.optionControllers[optionIndex],
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Option ${labels[optionIndex]}',
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                  filled: true,
                                  fillColor: isSelected
                                      ? AppColors.success.withValues(alpha: isDark ? 0.15 : 0.05)
                                      : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isSelected ? AppColors.success.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isSelected ? AppColors.success.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isSelected ? AppColors.success : Theme.of(context).colorScheme.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: form.explanationController,
                      decoration: _inputDeco('Explanation (Optional) - Why is this correct?'),
                    ),
                  ],
                ),
              );
            }),

            // Add Question Button
            OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Question'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
              ),
            ),
            const SizedBox(height: 100), // spacing for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _validateAndSubmit,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_isSubmitting ? 'Saving...' : 'Save & Publish Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
