// lib/features/search/presentation/screens/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../routes/route_names.dart';

final _searchResultsProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier(ref.watch(firestoreServiceProvider)));

class SearchState {
  final bool isLoading;
  final List<Map<String, dynamic>> results;
  final String? error;
  final String query;

  const SearchState({
    this.isLoading = false,
    this.results = const [],
    this.error,
    this.query = '',
  });
}

class SearchNotifier extends StateNotifier<SearchState> {
  final FirestoreService _firestore;
  Timer? _debounce;

  SearchNotifier(this._firestore) : super(const SearchState());

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = SearchState(isLoading: true, query: query);
    _debounce = Timer(const Duration(milliseconds: 400), () => _execute(query));
  }

  Future<void> _execute(String query) async {
    try {
      final lowerQuery = query.toLowerCase();

      final booksSnapshot = await _firestore.booksCol.get();
      final quizzesSnapshot = await _firestore.quizzesCol.get();

      final List<Map<String, dynamic>> results = [];

      for (var doc in booksSnapshot.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final subject = data['subject'] is Map
            ? (data['subject']['name'] ?? '').toString().toLowerCase()
            : (data['subject'] ?? '').toString().toLowerCase();
            
        if (title.contains(lowerQuery) || subject.contains(lowerQuery)) {
          data['_id'] = doc.id;
          data['type'] = 'book';
          results.add(data);
        }
      }

      for (var doc in quizzesSnapshot.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final subject = data['subject'] is Map
            ? (data['subject']['name'] ?? '').toString().toLowerCase()
            : (data['subject'] ?? '').toString().toLowerCase();
            
        if (title.contains(lowerQuery) || subject.contains(lowerQuery)) {
          data['_id'] = doc.id;
          data['type'] = 'quiz';
          results.add(data);
        }
      }

      state = SearchState(results: results.take(20).toList(), query: query);
    } catch (e) {
      state = SearchState(error: e.toString(), query: query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  final List<String> _recentSearches = [
    'Mathematics Class 9',
    'Photosynthesis',
    'Pakistan Studies',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_searchResultsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          onChanged: (q) => ref.read(_searchResultsProvider.notifier).search(q),
          decoration: const InputDecoration(
            hintText: 'Search books, quizzes, subjects...',
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 15),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                ref.read(_searchResultsProvider.notifier).search('');
              },
            ),
        ],
      ),
      body: state.query.isEmpty
          ? _buildSuggestions()
          : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text(state.error!))
                  : state.results.isEmpty
                      ? _buildNoResults(state.query)
                      : _buildResults(state.results),
    );
  }

  Widget _buildSuggestions() {
    final trending = [
      'Class 10 Physics',
      'Urdu Grammar',
      'Algebra',
      'Biology Chapter 5',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((s) => GestureDetector(
                onTap: () {
                  _ctrl.text = s;
                  ref.read(_searchResultsProvider.notifier).search(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(s, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          const Text('Trending',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...trending.map((t) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: AppColors.primary, size: 18),
                ),
                title: Text(t, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12,
                    color: AppColors.textHint),
                onTap: () {
                  _ctrl.text = t;
                  ref.read(_searchResultsProvider.notifier).search(t);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildResults(List<Map<String, dynamic>> results) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _SearchResultTile(result: results[i]),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No results for "$query"',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          const Text('Try a different keyword',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final type = result['type'] ?? 'book';
    final title = result['title'] ?? result['name'] ?? 'Untitled';

    IconData icon;
    Color color;
    String subtitle;
    String route;
    String id = result['_id'] ?? '';

    switch (type) {
      case 'quiz':
        icon = Icons.quiz;
        color = const Color(0xFF8B5CF6);
        subtitle = 'Quiz • ${result['totalQuestions']} questions';
        route = AppRoutes.quiz;
        break;
      case 'subject':
        icon = Icons.subject;
        color = AppColors.secondary;
        subtitle = 'Subject';
        route = AppRoutes.bookList;
        break;
      default:
        icon = Icons.menu_book;
        color = AppColors.primary;
        subtitle = 'Book • ${result['subject']?['name'] ?? ''}';
        route = AppRoutes.bookDetail;
    }

    return GestureDetector(
      onTap: () => context.pushNamed(route, pathParameters: {
        (type == 'quiz' ? 'id' : 'id'): id
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
