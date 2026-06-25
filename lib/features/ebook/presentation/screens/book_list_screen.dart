// lib/features/ebook/presentation/screens/book_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/book_provider.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedGrade;
  String? _selectedSubject;
  String? _selectedBoard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookListProvider.notifier).loadFilters();
      ref.read(bookListProvider.notifier).loadBooks();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    ref.read(bookListProvider.notifier).loadBooks(
      grade: _selectedGrade,
      subject: _selectedSubject,
      board: _selectedBoard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('E-Books Library'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (q) => ref.read(bookListProvider.notifier).search(q),
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(bookListProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Board Filter
                if (state.availableBoards.length > 1)
                  _buildDropdownFilter(
                    hint: 'Board',
                    value: _selectedBoard,
                    items: state.availableBoards,
                    onChanged: (val) {
                      setState(() => _selectedBoard = val == 'All' ? null : val);
                      _onFilterChanged();
                    },
                  ),
                if (state.availableBoards.length > 1) const SizedBox(width: 8),
                
                // Grade Filter
                _buildDropdownFilter(
                  hint: 'Grade',
                  value: _selectedGrade,
                  items: state.availableGrades,
                  onChanged: (val) {
                    setState(() => _selectedGrade = val == 'All' ? null : val);
                    _onFilterChanged();
                  },
                ),
                const SizedBox(width: 8),

                // Subject Filter
                _buildDropdownFilter(
                  hint: 'Subject',
                  value: _selectedSubject,
                  items: state.availableSubjects,
                  onChanged: (val) {
                    setState(() => _selectedSubject = val == 'All' ? null : val);
                    _onFilterChanged();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: state.isLoading
                ? _buildShimmer()
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.books.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(bookListProvider.notifier).loadBooks(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.books.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (_, i) =>
                                  _BookCard(book: state.books[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          value: value ?? 'All',
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item == 'All' ? 'All $hint' : item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceVariant,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No books available for this filter',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final Map<String, dynamic> book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher = ref.watch(authStateProvider).user?.isTeacher == true;
    final title = book['title'] ?? 'Untitled';
    final rawSubject = book['subject'];
    final subject = rawSubject is Map ? (rawSubject['name'] ?? 'General') : (rawSubject?.toString() ?? 'General');
    
    final rawGrade = book['grade'];
    final grade = rawGrade is Map ? (rawGrade['name'] ?? '') : (rawGrade?.toString() ?? '');
    final coverUrl = book['coverImage'];
    final downloaded = book['isDownloaded'] ?? false;

    // Color per subject
    final subjectColors = {
      'Mathematics': const Color(0xFF3B82F6),
      'Physics': const Color(0xFF8B5CF6),
      'Chemistry': const Color(0xFF10B981),
      'Biology': const Color(0xFF22C55E),
      'English': const Color(0xFFF59E0B),
      'Urdu': const Color(0xFFEF4444),
    };
    final color = subjectColors[subject] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => context.pushNamed(isTeacher ? AppRoutes.teacherBookDetail : AppRoutes.bookDetail,
          pathParameters: {'id': book['_id'] ?? ''}),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(
                width: 100,
                height: double.infinity,
                color: color.withValues(alpha: 0.1),
                child: coverUrl != null
                    ? Image.network(coverUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderCover(
                            subject: subject, color: color))
                    : _PlaceholderCover(subject: subject, color: color),
              ),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(subject,
                              style: TextStyle(color: color, fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (grade.isNotEmpty)
                          Text('Class $grade',
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              downloaded ? Icons.check_circle : Icons.cloud_download_outlined,
                              size: 16,
                              color: downloaded ? AppColors.success : AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(downloaded ? 'Downloaded' : 'Available',
                                style: TextStyle(color: downloaded ? AppColors.success : AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('Read',
                                style: TextStyle(color: color, fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final String subject;
  final Color color;
  const _PlaceholderCover({required this.subject, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, color: color.withValues(alpha: 0.8), size: 36),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(subject,
                style: TextStyle(color: color, fontSize: 10,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
