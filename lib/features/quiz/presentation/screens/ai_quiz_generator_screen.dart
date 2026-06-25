import 'package:ekitab/features/ebook/presentation/providers/book_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/quiz_provider.dart';

enum QuizGenMode { book, manual }

class AiQuizGeneratorScreen extends ConsumerStatefulWidget {
  const AiQuizGeneratorScreen({super.key});

  @override
  ConsumerState<AiQuizGeneratorScreen> createState() => _AiQuizGeneratorScreenState();
}

class _AiQuizGeneratorScreenState extends ConsumerState<AiQuizGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterNameCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  
  QuizGenMode _mode = QuizGenMode.book;
  bool _isGenerating = false;

  // Book mode state
  String? _selectedBookId;
  String? _selectedChapterId;
  int _mcqQuantity = 5;
  int _timeLimit = 15;

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
    _chapterNameCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_mode == QuizGenMode.manual && !_formKey.currentState!.validate()) return;
    if (_mode == QuizGenMode.book) {
      if (_selectedBookId == null || _selectedChapterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a book and a chapter.'), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    
    setState(() => _isGenerating = true);
    
    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    String topicName = '';
    if (_mode == QuizGenMode.manual) {
      topicName = _chapterNameCtrl.text;
    } else {
      final books = ref.read(bookListProvider).books;
      final selectedBook = books.firstWhere((b) => b['_id'] == _selectedBookId);
      final chapters = (selectedBook['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final selectedChapter = chapters.firstWhere((c) => c['id'] == _selectedChapterId, orElse: () => {'title': 'Chapter'});
      topicName = '${selectedBook['title']} - ${selectedChapter['title']}';
    }

    // Mock generated quiz
    final generatedQuestions = List.generate(_mode == QuizGenMode.book ? _mcqQuantity : 5, (index) {
      return {
        "question": "What is the main theme of $topicName (Q${index+1})?",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correctAnswerIndex": index % 4,
        "explanation": "AI generated explanation based on the chapter content.",
      };
    });

    try {
      await ref.read(quizListProvider.notifier).addQuizManually(
        '$topicName - AI Quiz',
        generatedQuestions,
        timeLimit: _timeLimit,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz generated successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating quiz: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  InputDecoration _inputDeco(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Quiz Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 64, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 16),
            Text(
              'Generate Quizzes Instantly',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a book chapter or enter context manually to let our AI generate a complete quiz for your students.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            
            // Mode Toggle
            SegmentedButton<QuizGenMode>(
              segments: const [
                ButtonSegment(value: QuizGenMode.book, icon: Icon(Icons.menu_book_rounded), label: Text('From Book')),
                ButtonSegment(value: QuizGenMode.manual, icon: Icon(Icons.edit_note_rounded), label: Text('Manual')),
              ],
              selected: {_mode},
              onSelectionChanged: (Set<QuizGenMode> newSelection) {
                setState(() => _mode = newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return const Color(0xFF8B5CF6).withValues(alpha: 0.1);
                  return Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return const Color(0xFF8B5CF6);
                  return Theme.of(context).colorScheme.onSurfaceVariant;
                }),
              ),
            ),
            const SizedBox(height: 32),

            if (_mode == QuizGenMode.book) ...[
              if (bookState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (bookState.books.isEmpty)
                const Text('No books available. Please add some books first.', style: TextStyle(color: AppColors.error))
              else ...[
                DropdownButtonFormField<String>(
                  decoration: _inputDeco('Select Book', 'Choose a book'),
                  value: _selectedBookId,
                  items: bookState.books.map((b) => DropdownMenuItem(
                    value: b['_id'] as String,
                    child: Text(b['title'] ?? 'Unknown Book'),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBookId = val;
                      _selectedChapterId = null; // Reset chapter when book changes
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
                        setState(() => _selectedChapterId = val);
                      },
                    );
                  }
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _inputDeco('Number of MCQs', 'e.g., 5, 10'),
                  value: _mcqQuantity,
                  items: [5, 10, 15, 20].map((num) => DropdownMenuItem(
                    value: num,
                    child: Text('$num Questions'),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _mcqQuantity = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _inputDeco('Time Limit (minutes)', 'e.g., 15'),
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
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _chapterNameCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Chapter name is required' : null,
                      decoration: _inputDeco('Chapter Name / Topic', 'e.g., Photosynthesis'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contextCtrl,
                      maxLines: 5,
                      decoration: _inputDeco('Chapter Content (Optional)', 'Paste key points or text from the chapter...'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: _inputDeco('Time Limit (minutes)', 'e.g., 15'),
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
            ],

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateQuiz,
              icon: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate AI Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
