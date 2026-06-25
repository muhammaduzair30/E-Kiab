// lib/features/ebook/presentation/providers/book_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────

class BookListState {
  final bool isLoading;
  final List<Map<String, dynamic>> books;
  final String? error;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  
  // Dynamic filters
  final List<String> availableGrades;
  final List<String> availableSubjects;
  final List<String> availableBoards;

  const BookListState({
    this.isLoading = false,
    this.books = const [],
    this.error,
    this.lastDocument,
    this.hasMore = true,
    this.availableGrades = const ['All'],
    this.availableSubjects = const ['All'],
    this.availableBoards = const ['All'],
  });

  BookListState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? books,
    String? error,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    List<String>? availableGrades,
    List<String>? availableSubjects,
    List<String>? availableBoards,
  }) {
    return BookListState(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      availableGrades: availableGrades ?? this.availableGrades,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      availableBoards: availableBoards ?? this.availableBoards,
    );
  }
}

class BookListNotifier extends StateNotifier<BookListState> {
  final FirestoreService _firestore;
  BookListNotifier(this._firestore) : super(const BookListState());

  Future<void> loadFilters() async {
    try {
      final snapshot = await _firestore.booksCol.get();
      final Set<String> grades = {'All'};
      final Set<String> subjects = {'All'};
      final Set<String> boards = {'All'};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['grade'] != null) grades.add(data['grade'].toString());
        if (data['subject'] != null) subjects.add(data['subject'].toString());
        if (data['board'] != null) boards.add(data['board'].toString());
      }

      state = state.copyWith(
        availableGrades: grades.toList()..sort(),
        availableSubjects: subjects.toList()..sort(),
        availableBoards: boards.toList()..sort(),
      );
    } catch (e) {
      // Ignore filter load errors
    }
  }

  Future<void> loadBooks({String? grade, String? subject, String? board, bool loadMore = false}) async {
    if (loadMore && !state.hasMore) return;
    
    state = state.copyWith(
      isLoading: !loadMore,
    );

    try {
      Query<Map<String, dynamic>> query = _firestore.booksCol;

      bool hasFilters = false;

      if (grade != null && grade != 'All') {
        query = query.where('grade', isEqualTo: grade);
        hasFilters = true;
      }
      if (subject != null && subject != 'All') {
        query = query.where('subject', isEqualTo: subject);
        hasFilters = true;
      }
      if (board != null && board != 'All') {
        query = query.where('board', isEqualTo: board);
        hasFilters = true;
      }

      if (!hasFilters) {
        query = query.orderBy('createdAt', descending: true);
      }
      
      query = query.limit(20);

      if (loadMore && state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.get();
      final newBooks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        books: loadMore ? [...state.books, ...newBooks] : newBooks,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loadBooks();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      // Fetch all to do robust case-insensitive local search for MVP
      final snapshot = await _firestore.booksCol.get();
      final lowerQuery = query.toLowerCase();

      final books = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        return data;
      }).where((data) {
        final title = (data['title'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery);
      }).take(20).toList();

      state = state.copyWith(
        isLoading: false,
        books: books, 
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final bookListProvider = StateNotifierProvider<BookListNotifier, BookListState>(
  (ref) => BookListNotifier(ref.watch(firestoreServiceProvider)),
);

// ── Book detail ────────────────────────────────────────────────────────────

class BookDetailState {
  final bool isLoading;
  final Map<String, dynamic>? book;
  final String? pdfUrl;
  final String? error;
  final bool isDownloaded;
  final int? currentPage;

  const BookDetailState({
    this.isLoading = false,
    this.book,
    this.pdfUrl,
    this.error,
    this.isDownloaded = false,
    this.currentPage,
  });

  BookDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? book,
    String? pdfUrl,
    String? error,
    bool? isDownloaded,
    int? currentPage,
  }) =>
      BookDetailState(
        isLoading: isLoading ?? this.isLoading,
        book: book ?? this.book,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        error: error ?? this.error,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        currentPage: currentPage ?? this.currentPage,
      );
}

class BookDetailNotifier extends StateNotifier<BookDetailState> {
  final FirestoreService _firestore;
  final String? _uid;

  BookDetailNotifier(this._firestore, this._uid) : super(const BookDetailState());

  Future<void> loadBook(String bookId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final doc = await _firestore.booksCol.doc(bookId).get();
      if (!doc.exists) throw Exception('Book not found');

      final book = doc.data()!;
      book['_id'] = doc.id;
      
      int? currentPage;
      if (_uid != null) {
        final progressDoc = await _firestore.usersCol
            .doc(_uid)
            .collection('bookProgress')
            .doc(bookId)
            .get();
        if (progressDoc.exists) {
          currentPage = progressDoc.data()?['lastPageRead'] as int?;
        }
      }

      state = state.copyWith(
        isLoading: false, 
        book: book, 
        pdfUrl: book['fileUrl'],
        currentPage: currentPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveProgress(String bookId, int page) async {
    if (_uid == null) return;
    try {
      await _firestore.usersCol
          .doc(_uid)
          .collection('bookProgress')
          .doc(bookId)
          .set({
            'lastPageRead': page,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      state = state.copyWith(currentPage: page);
    } catch (_) {}
  }

  Future<void> addBookmark(String bookId, int page) async {
    if (_uid == null) return;
    try {
      await _firestore.usersCol
          .doc(_uid)
          .collection('bookmarks')
          .doc(bookId)
          .set({
            'pages': FieldValue.arrayUnion([page]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}

final bookDetailProvider =
    StateNotifierProvider.family<BookDetailNotifier, BookDetailState, String>(
  (ref, bookId) {
    final uid = ref.watch(authStateProvider).user?.id;
    return BookDetailNotifier(ref.watch(firestoreServiceProvider), uid);
  },
);

