import 'package:flutter/material.dart';

import '../../services/ai_services.dart';
import '../../theme/app_theme.dart';

/// Chat with Bucks. Questions go to AiService, which asks the `bucks-ai`
/// Edge Function (Gemini runs there, never in the app).

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.aiService});

  /// Injectable for tests; defaults to the real service.
  final AiService? aiService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Msg {
  final String text;
  final bool fromUser;
  final bool isError;
  final bool sessionExpired;

  /// For error bubbles: the question to resend.
  final String? retryText;
  const _Msg(
    this.text, {
    required this.fromUser,
    this.isError = false,
    this.sessionExpired = false,
    this.retryText,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  static const _suggestions = [
    'How am I doing this month?',
    'Where am I spending the most?',
    'Am I staying within my budget?',
    'How close am I to my savings goal?',
    'What can I improve this week?',
  ];

  late final AiService _ai = widget.aiService ?? AiService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[];
  bool _waiting = false;
  bool _handledRouteArgs = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledRouteArgs) return;
    _handledRouteArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ask(args);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _canSend => !_waiting && _controller.text.trim().isNotEmpty;

  void _sendTyped() {
    final text = _controller.text.trim();
    if (text.isEmpty || _waiting) return;
    _controller.clear();
    _ask(text);
  }

  /// Earlier real messages (no error bubbles) as context for Bucks.
  List<AiTurn> _history({required bool dropTrailingUser}) {
    final real = _messages.where((m) => !m.isError).toList();
    if (dropTrailingUser && real.isNotEmpty && real.last.fromUser) {
      real.removeLast();
    }
    return [
      for (final m in real) AiTurn(fromUser: m.fromUser, text: m.text),
    ];
  }

  Future<void> _ask(String text, {bool isRetry = false}) async {
    if (_waiting) return;
    final history = _history(dropTrailingUser: isRetry);
    setState(() {
      if (!isRetry) _messages.add(_Msg(text, fromUser: true));
      _waiting = true;
    });
    _scrollToEnd();

    _Msg? answer;
    try {
      final reply = await _ai.askBucksAssistant(text, history: history);
      answer = _Msg(reply, fromUser: false);
    } on AiException catch (e) {
      answer = _Msg(
        e.message,
        fromUser: false,
        isError: true,
        sessionExpired: e.sessionExpired,
        retryText: text,
      );
    } catch (_) {
      answer = _Msg(AiService.friendlyError,
          fromUser: false, isError: true, retryText: text);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(answer!);
      _waiting = false;
    });
    _scrollToEnd();
  }

  void _retry(_Msg errorMsg) {
    final text = errorMsg.retryText;
    if (text == null || _waiting) return;
    setState(() => _messages.remove(errorMsg));
    _ask(text, isRetry: true);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Bucks')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty && !_waiting
                      ? _buildIntro()
                      : _buildMessages(),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Hi! I'm Bucks. Ask me about your spending, budgets or savings "
          'goals, and I will look at your real numbers.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _suggestions)
              ActionChip(label: Text(s), onPressed: () => _ask(s)),
          ],
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_waiting ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTyping();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildBubble(_Msg m) {
    final Color bg = m.fromUser
        ? AppTheme.primary
        : (m.isError
            ? AppTheme.danger.withValues(alpha: 0.10)
            : AppTheme.surface);
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: m.fromUser
              ? null
              : Border.all(
                  color: m.isError
                      ? AppTheme.danger.withValues(alpha: 0.4)
                      : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.text, style: const TextStyle(color: AppTheme.textDark)),
            if (m.isError && m.retryText != null && !m.sessionExpired)
              TextButton(
                onPressed: _waiting ? null : () => _retry(m),
                child: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Bucks is thinking…'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat_input'),
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTyped(),
              minLines: 1,
              maxLines: 4,
              maxLength: AiService.maxQuestionChars,
              decoration: const InputDecoration(
                hintText: 'Ask Bucks about your money…',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('send_button'),
            onPressed: _canSend ? _sendTyped : null,
            icon: const Icon(Icons.send),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}
