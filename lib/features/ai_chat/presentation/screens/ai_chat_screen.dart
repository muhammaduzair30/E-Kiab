// lib/features/ai_chat/presentation/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

// ─── Chat Screen ──────────────────────────────────────────────────────────────
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final FlutterTts _tts = FlutterTts();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  // Tutor Modes
  final _tutorModes = [
    {'label': '🧠 Explain a Concept', 'prompt': 'Can you explain the main concept of this topic?'},
    {'label': '📝 Quiz Me', 'prompt': 'Please give me a multiple-choice quiz on this topic to test my knowledge.'},
    {'label': '🤔 Guide Me', 'prompt': 'I need help understanding a problem. Please guide me step-by-step without giving the direct answer.'},
  ];

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isTyping = chatState.isTyping;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Scroll when new messages arrive or when typing starts
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary]
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tutor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Online • Gemini', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == messages.length) {
                  return _MessageBubble(
                    message: const ChatMessage(text: "...", isUser: false),
                    onSpeak: _speak,
                    isTypingIndicator: true,
                  );
                }
                return _MessageBubble(
                  message: messages[i],
                  onSpeak: _speak,
                );
              },
            ),
          ),

          // Quick prompts (only when no conversation yet)
          if (messages.length <= 1)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tutorModes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  elevation: 0,
                  pressElevation: 0,
                  backgroundColor: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(_tutorModes[i]['label']!, style: TextStyle(fontSize: 13, color: isDark ? Colors.blue[300] : AppColors.primary, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    _ctrl.text = _tutorModes[i]['prompt']!;
                    _send();
                  },
                ),
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15))),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? theme.scaffoldBackgroundColor : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _focusNode.hasFocus ? AppColors.primary.withValues(alpha: 0.5) : theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focusNode,
                              maxLines: 5,
                              minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onChanged: (v) => setState(() {}),
                              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Message AI Tutor...',
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, right: 6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(10),
                                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                                onPressed: _send,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, right: 6),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(10),
                              icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                              onPressed: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String) onSpeak;
  final bool isTypingIndicator;

  const _MessageBubble({
    required this.message, 
    required this.onSpeak,
    this.isTypingIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                    ],
                    border: isUser ? null : Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: isTypingIndicator
                      ? _TypingIndicator()
                      : (isUser
                          ? Text(
                              message.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            )
                          : MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(fontSize: 15, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
                                h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                listBullet: const TextStyle(color: AppColors.primary, fontSize: 15),
                                code: const TextStyle(backgroundColor: Color(0xFFEFF3FF), fontFamily: 'monospace', color: AppColors.primary),
                                codeblockDecoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser && !isTypingIndicator && !message.isStreaming) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onSpeak(message.text),
                        child: Icon(Icons.volume_up_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 150), c.repeat);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _ctrls[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3 + _ctrls[i].value * 0.7),
            shape: BoxShape.circle,
          ),
        ),
      )),
    );
  }
}
