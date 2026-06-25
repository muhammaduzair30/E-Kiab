import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/services/ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isUser, bool? isStreaming}) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
  });
}

class ChatNotifier extends StateNotifier<ChatState> {
  final AiService _aiService;
  final List<Content> _history = [];
  String? _chapterContext;

  ChatNotifier(this._aiService) : super(const ChatState()) {
    _initDefaultState();
  }

  void _initDefaultState() {
    _chapterContext = null;
    _history.clear();
    state = const ChatState(
      messages: [
        ChatMessage(
          text: "Hi there! I am your AI Tutor. You can ask me any general question.\n\n*Tip: If you want to learn about a specific chapter, click on 'Learn with AI' from any book and we can discuss it!*",
          isUser: false,
        )
      ]
    );
  }

  void setChapterContext(String contextText, {String? chapterTitle}) {
    _chapterContext = contextText;
    _history.clear();
    state = const ChatState(
      messages: [
        ChatMessage(
          text: "I see you're studying a specific chapter. Let's learn it together! You can ask me to explain concepts, or use the 'Quiz Me' mode to test your knowledge.",
          isUser: false,
        )
      ]
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final newMessages = List<ChatMessage>.from(state.messages)
      ..add(ChatMessage(text: text, isUser: true));
    
    state = ChatState(messages: newMessages, isTyping: true);

    // Prepare a placeholder for the AI response
    int aiMessageIndex = newMessages.length;
    state = ChatState(
      messages: [...newMessages, const ChatMessage(text: "", isUser: false, isStreaming: true)],
      isTyping: false,
    );

    try {
      final stream = _aiService.streamChatResponse(text, _history, chapterContext: _chapterContext);
      
      String aiResponseText = "";
      await for (final chunk in stream) {
        aiResponseText += chunk;
        
        final currentMessages = List<ChatMessage>.from(state.messages);
        currentMessages[aiMessageIndex] = ChatMessage(text: aiResponseText, isUser: false, isStreaming: true);
        
        state = ChatState(messages: currentMessages, isTyping: false);
      }

      // Finalize message
      final finalMessages = List<ChatMessage>.from(state.messages);
      finalMessages[aiMessageIndex] = ChatMessage(text: aiResponseText, isUser: false, isStreaming: false);
      state = ChatState(messages: finalMessages, isTyping: false);

      // Add to history
      _history.add(Content.text(text));
      _history.add(Content.model([TextPart(aiResponseText)]));
      
    } catch (e) {
      final currentMessages = List<ChatMessage>.from(state.messages);
      currentMessages[aiMessageIndex] = ChatMessage(text: "Error: $e", isUser: false, isStreaming: false);
      state = ChatState(messages: currentMessages, isTyping: false);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(aiServiceProvider));
});
