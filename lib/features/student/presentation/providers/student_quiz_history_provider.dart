import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';

final studentQuizHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(quizRepositoryProvider);
  return repo.getUserQuizHistory();
});
