import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quiz_repository.dart';

class QuizState {
  final String quizId;
  final String quizTitle;
  final List<Map<String, dynamic>> questions;
  final Map<int, int> selectedAnswers;
  final int currentQuestionIndex;
  final bool isSubmitted;
  final int timeLimit;

  const QuizState({
    required this.quizId,
    required this.quizTitle,
    required this.questions,
    this.selectedAnswers = const {},
    this.currentQuestionIndex = 0,
    this.isSubmitted = false,
    this.timeLimit = 15,
  });

  int get score {
    int s = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]['correctAnswerIndex']) {
        s++;
      }
    }
    return s;
  }

  QuizState copyWith({
    Map<int, int>? selectedAnswers,
    int? currentQuestionIndex,
    bool? isSubmitted,
    int? timeLimit,
  }) {
    return QuizState(
      quizId: quizId,
      quizTitle: quizTitle,
      questions: questions,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState?> {
  final Ref ref;
  
  QuizNotifier(this.ref) : super(null);

  void startQuiz(String quizId, String quizTitle, List<Map<String, dynamic>> questions, {int timeLimit = 15}) {
    state = QuizState(
      quizId: quizId,
      quizTitle: quizTitle,
      questions: questions,
      timeLimit: timeLimit,
    );
  }

  void viewAttempt(String quizId, String quizTitle, List<Map<String, dynamic>> questions, Map<String, dynamic> firestoreAnswers) {
    final Map<int, int> selectedAnswers = {};
    firestoreAnswers.forEach((key, value) {
      selectedAnswers[int.parse(key)] = value as int;
    });
    state = QuizState(
      quizId: quizId,
      quizTitle: quizTitle,
      questions: questions,
      selectedAnswers: selectedAnswers,
      currentQuestionIndex: 0,
      isSubmitted: true,
    );
  }

  void selectAnswer(int optionIndex) {
    if (state == null || state!.isSubmitted) return;
    
    final newAnswers = Map<int, int>.from(state!.selectedAnswers);
    newAnswers[state!.currentQuestionIndex] = optionIndex;
    
    state = state!.copyWith(selectedAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state == null) return;
    if (state!.currentQuestionIndex < state!.questions.length - 1) {
      state = state!.copyWith(currentQuestionIndex: state!.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state == null) return;
    if (state!.currentQuestionIndex > 0) {
      state = state!.copyWith(currentQuestionIndex: state!.currentQuestionIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    if (state == null) return;
    
    // Save to Firestore, only mark submitted on success
    try {
      final repo = ref.read(quizRepositoryProvider);
      await repo.saveQuizAttempt(
        state!.quizId,
        state!.quizTitle,
        state!.score,
        state!.questions.length,
        state!.selectedAnswers,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Still allow the user to see their results even if save fails or times out
    }

    state = state!.copyWith(isSubmitted: true);
  }

  int get answeredCount => state?.selectedAnswers.length ?? 0;
  int get totalCount => state?.questions.length ?? 0;
  int get unansweredCount => totalCount - answeredCount;
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState?>((ref) {
  return QuizNotifier(ref);
});

class QuizListState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> quizzes;

  const QuizListState({
    this.isLoading = false,
    this.error,
    this.quizzes = const [],
  });
}

class QuizListNotifier extends StateNotifier<QuizListState> {
  final Ref ref;
  
  QuizListNotifier(this.ref) : super(const QuizListState());

  Future<void> loadQuizzes() async {
    state = const QuizListState(isLoading: true, quizzes: []);
    try {
      final repo = ref.read(quizRepositoryProvider);
      final fetchedQuizzes = await repo.getQuizzes();
      final validQuizzes = fetchedQuizzes.where((q) {
        final qList = q['questions'] as List<dynamic>?;
        return qList != null && qList.isNotEmpty;
      }).toList();
      state = QuizListState(isLoading: false, quizzes: validQuizzes);
    } catch (e) {
      state = QuizListState(isLoading: false, error: e.toString());
    }
  }

  Future<void> addQuizManually(String title, List<Map<String, dynamic>> questions, {int timeLimit = 15}) async {
    final repo = ref.read(quizRepositoryProvider);
    
    final newQuiz = {
      'title': title,
      'subject': {'name': 'Custom Upload'},
      'totalQuestions': questions.length,
      'totalMarks': questions.length,
      'timeLimit': timeLimit,
      'difficulty': 'medium',
      'questions': questions,
    };

    // Save to Firestore with timeout
    try {
      final newId = await repo.saveQuiz(newQuiz).timeout(const Duration(seconds: 5));
      newQuiz['_id'] = newId;

      // Update local state instantly so user sees it
      final currentQuizzes = List<Map<String, dynamic>>.from(state.quizzes);
      currentQuizzes.insert(0, newQuiz);

      state = QuizListState(
        isLoading: false,
        error: state.error,
        quizzes: currentQuizzes,
      );
    } catch (e) {
      state = QuizListState(
        isLoading: false,
        error: 'Network timeout: Failed to save quiz. Please try again.',
        quizzes: state.quizzes,
      );
    }
  }
}

final quizListProvider = StateNotifierProvider<QuizListNotifier, QuizListState>((ref) {
  return QuizListNotifier(ref);
});

final teacherQuizResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(quizRepositoryProvider);
  return repo.getGlobalQuizAttempts();
});

final quizHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(quizRepositoryProvider);
  return await repo.getUserQuizHistory();
});
