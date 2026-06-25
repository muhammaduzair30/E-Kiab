import 'package:ekitab/core/theme/app_theme.dart';
import 'package:ekitab/features/ebook/presentation/providers/book_provider.dart';
import 'package:ekitab/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ekitab/features/quiz/presentation/providers/quiz_provider.dart';
import 'package:ekitab/features/ai_chat/presentation/providers/chat_provider.dart';
import 'package:ekitab/features/auth/presentation/providers/auth_provider.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double? _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load the book data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookDetailProvider(widget.bookId).notifier).loadBook(widget.bookId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startDownload() async {
    setState(() { _isDownloading = true; });
    // Simulate network delay for UI
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() { _isDownloading = false; _isDownloaded = true; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book downloaded for offline reading'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(bookDetailProvider(widget.bookId));

    if (detailState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (detailState.error != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text('Error: ${detailState.error}')),
      );
    }
    
    final book = detailState.book;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, book),
          SliverToBoxAdapter(child: _buildBookInfo(context, book)),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(child: _buildTabContent(book)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, book),
    );
  }

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> book) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      title: Text(book['title'] ?? 'Book Details', style: const TextStyle(fontSize: 16)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context, Map<String, dynamic> book) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Hero(
                tag: 'book_cover_${book['id'] ?? widget.bookId}',
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book['coverImage'] != null
                        ? Image.network(book['coverImage'], fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.menu_book_rounded,
                                size: 40, color: AppColors.primary),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book['title'] ?? 'Unknown Title',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(label: _getString(book['subject']), icon: Icons.subject_rounded, color: AppColors.primary),
                        _MetaChip(label: 'Grade ${_getString(book['grade'])}', icon: Icons.grade_rounded, color: AppColors.secondary),
                        _MetaChip(label: _getString(book['board']), icon: Icons.account_balance_rounded, color: const Color(0xFF8B5CF6)),
                        _MetaChip(label: '${book['totalPages'] ?? 0} pgs', icon: Icons.pages_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text('About this Book',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(book['description'] ?? 'No description available.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 16),

          // Reading progress if exists
          if (book['readingProgress'] != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reading Progress',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text('${(book['readingProgress'] * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: book['readingProgress'],
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _getString(dynamic val) {
    if (val is Map) return val['name']?.toString() ?? 'General';
    return val?.toString() ?? 'General';
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      tabs: const [
        Tab(text: 'Chapters'),
        Tab(text: 'Quizzes'),
      ],
    );
  }

  Widget _buildTabContent(Map<String, dynamic> book) {
    final chapters = (book['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(
        controller: _tabController,
        children: [
          _ChapterList(bookId: widget.bookId, bookTitle: book['title'] ?? 'Unknown Book', chapters: chapters),
          _RelatedQuizzes(bookId: widget.bookId, chapters: chapters),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Map<String, dynamic> book) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Download button
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _isDownloaded ? AppColors.successLight : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isDownloading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      value: _downloadProgress,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                      color: _isDownloaded ? AppColors.success : AppColors.primary,
                    ),
                    onPressed: _isDownloaded ? null : _startDownload,
                  ),
          ),
          const SizedBox(width: 12),

          // Read button
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final isTeacher = ref.read(authStateProvider).user?.isTeacher == true;
                  final chapters = (book['chapters'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                  final firstChapterId = chapters.isNotEmpty ? chapters.first['id'] : null;
                  if (firstChapterId != null) {
                    context.pushNamed(
                      isTeacher ? AppRoutes.teacherBookReader : AppRoutes.bookReader,
                      pathParameters: {'id': widget.bookId},
                      queryParameters: {'chapterId': firstChapterId},
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No chapters available')));
                  }
                },
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: Text(
                  book['readingProgress'] != null ? 'Continue Reading' : 'Start Reading',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chapter List ─────────────────────────────────────────────────────────────

class _ChapterList extends ConsumerWidget {
  final String bookId;
  final String bookTitle;
  final List<Map<String, dynamic>> chapters;
  const _ChapterList({required this.bookId, required this.bookTitle, required this.chapters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher = ref.watch(authStateProvider).user?.isTeacher == true;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final ch = chapters[i];
        final isCompleted = ch['completed'] == true;
        return InkWell(
          onTap: () {
            context.pushNamed(
              isTeacher ? AppRoutes.teacherBookReader : AppRoutes.bookReader,
              pathParameters: {'id': bookId},
              queryParameters: {'chapterId': ch['id']},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted 
                      ? const Icon(Icons.check_rounded, color: AppColors.success)
                      : Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch['title'],
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Starts at Page ${ch['pageNumber'] ?? '?'}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                if (!isTeacher)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                    tooltip: 'Learn with AI',
                    onPressed: () {
                      final contextText = "Book: $bookTitle\nChapter: ${ch['title']}\n\nThe student is studying this specific chapter. Please focus your answers on this topic and level.";
                      ref.read(chatProvider.notifier).setChapterContext(contextText, chapterTitle: ch['title']);
                      context.go(AppRoutes.aiChat);
                    },
                  ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Related Quizzes ──────────────────────────────────────────────────────────

class _RelatedQuizzes extends ConsumerWidget {
  final String bookId;
  final List<Map<String, dynamic>> chapters;
  const _RelatedQuizzes({required this.bookId, required this.chapters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher = ref.watch(authStateProvider).user?.isTeacher == true;
    
    // Filter chapters that actually have exercises
    final quizChapters = chapters.where((ch) => 
      ch['exercises'] != null && (ch['exercises'] as List).isNotEmpty
    ).toList();

    if (quizChapters.isEmpty) {
      return Center(
        child: Text('No quizzes available for this book.', 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: quizChapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final ch = quizChapters[i];
        final exercises = (ch['exercises'] as List).cast<Map<String, dynamic>>();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.quiz_rounded, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ch['title'] ?? 'Chapter Quiz',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('${exercises.length} questions',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              if (!isTeacher)
                ElevatedButton(
                  onPressed: () {
                    ref.read(quizProvider.notifier).startQuiz(
                      bookId, 
                      ch['id'], 
                      exercises,
                    );
                    context.pushNamed(AppRoutes.quiz);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MetaChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


