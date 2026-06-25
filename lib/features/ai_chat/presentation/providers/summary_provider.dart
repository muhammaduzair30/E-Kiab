import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_service.dart';

class SummaryState {
  final bool isLoading;
  final String? summary;
  final String? error;

  const SummaryState({
    this.isLoading = false,
    this.summary,
    this.error,
  });
}

class SummaryNotifier extends StateNotifier<SummaryState> {
  final AiService _aiService;

  SummaryNotifier(this._aiService) : super(const SummaryState());

  Future<void> summarizeText(String text, {String? chapterTitle}) async {
    state = const SummaryState(isLoading: true);
    try {
      final result = await _aiService.summarizeText(text, chapterTitle: chapterTitle);
      state = SummaryState(isLoading: false, summary: result);
    } catch (e) {
      state = SummaryState(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const SummaryState();
  }
}

final summaryProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  return SummaryNotifier(ref.watch(aiServiceProvider));
});
