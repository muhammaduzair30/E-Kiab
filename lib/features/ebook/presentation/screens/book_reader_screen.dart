import 'package:ekitab/features/ai_chat/presentation/providers/summary_provider.dart';
import 'package:ekitab/features/ai_chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../routes/route_names.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../providers/book_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
class BookReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String? chapterId;

  const BookReaderScreen({super.key, required this.bookId, this.chapterId});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfDocument? _pdfDocument;
  bool _isInitialJumpDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookDetailProvider(widget.bookId).notifier).loadBook(widget.bookId);
    });
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details, Map<String, dynamic> book) {
    _pdfDocument = details.document;
    if (!_isInitialJumpDone) {
      _isInitialJumpDone = true;
      
      // Jump to specific chapter if provided
      if (widget.chapterId != null) {
        final chapters = (book['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final chapter = chapters.firstWhere((c) => c['id'] == widget.chapterId, orElse: () => {});
        if (chapter.isNotEmpty && chapter['pageNumber'] != null) {
          final pageNum = chapter['pageNumber'] as int;
          // Syncfusion PDF viewer is 1-indexed for jumping
          _pdfViewerController.jumpToPage(pageNum);
        }
      } else {
        // Alternatively, jump to last read page if no chapter selected
        final detailState = ref.read(bookDetailProvider(widget.bookId));
        if (detailState.currentPage != null) {
          _pdfViewerController.jumpToPage(detailState.currentPage!);
        }
      }
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    // Save progress periodically
    if (details.newPageNumber % 5 == 0) {
       ref.read(bookDetailProvider(widget.bookId).notifier).saveProgress(widget.bookId, details.newPageNumber);
    }
  }

  void _showAiActionsSheet() {
    final detailState = ref.read(bookDetailProvider(widget.bookId));
    final authState = ref.read(authStateProvider);
    final isTeacher = authState.user?.isTeacher == true;
    final book = detailState.book;
    if (book == null) return;

    final chapters = (book['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    String chapterText = "Text not available.";
    
    // Find current chapter or just default to the first one for the demo
    final currentChapter = chapters.firstWhere(
      (c) => c['id'] == widget.chapterId, 
      orElse: () => chapters.isNotEmpty ? chapters.first : {}
    );

    if (_pdfDocument != null && currentChapter.isNotEmpty && currentChapter['pageNumber'] != null) {
      final startPage = currentChapter['pageNumber'] as int;
      int endPage = _pdfDocument!.pages.count;
      
      final currentIndex = chapters.indexOf(currentChapter);
      if (currentIndex >= 0 && currentIndex < chapters.length - 1) {
        final nextChapter = chapters[currentIndex + 1];
        if (nextChapter['pageNumber'] != null) {
           endPage = (nextChapter['pageNumber'] as int) - 1;
        }
      }

      int startIndex = startPage > 0 ? startPage - 1 : 0;
      int endIndex = endPage > 0 ? endPage - 1 : 0;
      if (endIndex >= _pdfDocument!.pages.count) {
        endIndex = _pdfDocument!.pages.count - 1;
      }
      if (startIndex <= endIndex) {
        try {
          chapterText = PdfTextExtractor(_pdfDocument!).extractText(startPageIndex: startIndex, endPageIndex: endIndex);
        } catch (e) {
          chapterText = "Failed to extract text from PDF: $e";
        }
      }
    } else if (currentChapter.isNotEmpty && currentChapter['sections'] != null) {
      // Fallback to database if PDF extraction is unavailable
      final sections = (currentChapter['sections'] as List).cast<Map<String, dynamic>>();
      chapterText = sections.map((s) => '${s['subtitle']}\n${s['content']}').join('\n\n');
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('AI Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary),
              ),
              title: const Text('Summarize Chapter'),
              subtitle: const Text('Get a quick markdown summary of this chapter.'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => _AiSummarySheet(
                    textToSummarize: chapterText,
                    chapterTitle: currentChapter['title'] as String?,
                  ),
                );
              },
            ),
            if (!isTeacher) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.school_rounded, color: AppColors.secondary),
                ),
                title: const Text('✨ Learn with AI'),
                subtitle: const Text('Ask questions and be tutored on this chapter.'),
                onTap: () {
                  Navigator.pop(context);
                  final contextText = "Book: ${book['title'] ?? 'Unknown Book'}\nChapter: ${currentChapter['title'] ?? 'Current Chapter'}\n\nChapter Content:\n$chapterText\n\nThe student is studying this specific chapter. Please focus your answers on this topic and level.";
                  ref.read(chatProvider.notifier).setChapterContext(contextText, chapterTitle: currentChapter['title'] as String?);
                  context.go(AppRoutes.aiChat);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndStartQuiz(String text, String? chapterTitle) async {
    // Show dialog and store its BuildContext
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // We capture this dialogContext so we can pop exactly this dialog
        _generateAndStartQuizInternal(text, chapterTitle, dialogContext);
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating Quiz...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndStartQuizInternal(String text, String? chapterTitle, BuildContext dialogContext) async {
    final aiService = ref.read(aiServiceProvider);
    
    List<Map<String, dynamic>> questions = [];
    String errorMessage = 'Failed to generate quiz.';

    try {
      // Add a timeout of 30 seconds so it doesn't spin forever
      questions = await aiService.generateQuiz(text, 5, chapterTitle: chapterTitle).timeout(const Duration(seconds: 30));
    } catch (e) {
      errorMessage = 'Error: $e';
    }
    
    if (!mounted) return;
    if (dialogContext.mounted) {
      Navigator.pop(dialogContext); // Close specifically the dialog
    }
    
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        )
      );
      return;
    }

    // Save AI quiz to Firestore so it has an ID
    final title = 'AI Quiz: ${chapterTitle ?? 'Chapter'}';
    final repo = ref.read(quizRepositoryProvider);
    try {
      final quizId = await repo.saveQuiz({
        'title': title,
        'subject': {'name': 'AI Generated'},
        'totalQuestions': questions.length,
        'totalMarks': questions.length,
        'timeLimit': 15,
        'difficulty': 'adaptive',
        'questions': questions,
      });

      ref.read(quizProvider.notifier).startQuiz(quizId, title, questions);
      if (mounted) {
        context.pushNamed(AppRoutes.quiz);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not initialize quiz instance'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(bookDetailProvider(widget.bookId).select((s) => s.isLoading));
    final book = ref.watch(bookDetailProvider(widget.bookId).select((s) => s.book));
    final pdfUrl = ref.watch(bookDetailProvider(widget.bookId).select((s) => s.pdfUrl));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(book?['title'] ?? 'Reader', style: const TextStyle(fontSize: 16)),
      ),
      body: Stack(
        children: [
          if (isLoading || book == null)
            const Center(child: CircularProgressIndicator())
          else if (pdfUrl == null || pdfUrl.isEmpty)
            const Center(child: Text("PDF file not available for this book.", style: TextStyle(color: Colors.red)))
          else
            SfPdfViewer.network(
              pdfUrl,
              controller: _pdfViewerController,
              interactionMode: PdfInteractionMode.pan, // Bypasses text selection hover logic
              enableTextSelection: false,
              enableDocumentLinkAnnotation: false,
              onDocumentLoaded: (details) => _onDocumentLoaded(details, book),
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF Load Failed: ${details.error}\n${details.description}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 10),
                  ),
                );
              },
              onPageChanged: _onPageChanged,
              canShowScrollHead: false,
              pageSpacing: 4,
            ),
            
          // Bottom FAB for AI actions
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _showAiActionsSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('AI Actions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummarySheet extends ConsumerStatefulWidget {
  final String textToSummarize;
  final String? chapterTitle;
  const _AiSummarySheet({required this.textToSummarize, this.chapterTitle});

  @override
  ConsumerState<_AiSummarySheet> createState() => _AiSummarySheetState();
}

class _AiSummarySheetState extends ConsumerState<_AiSummarySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(summaryProvider.notifier).summarizeText(widget.textToSummarize, chapterTitle: widget.chapterTitle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('AI Chapter Summary', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 20),
            if (state.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else if (state.error != null) ...[
              Expanded(child: Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)))),
            ] else if (state.summary != null) ...[
              Expanded(
                child: Markdown(
                  data: state.summary!,
                  controller: ctrl,
                  padding: EdgeInsets.zero,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
