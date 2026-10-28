import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

const _apiUrl = '${AppConstants.apiBaseUrl}/api/chat/stream';

const _suggestions = [
  'What is the normal range for temperature?',
  'What is hemoglobin?',
  'How do I book an appointment?',
  'What does LDL mean?',
];

const _welcomeMessage = 'Hello! I can help you with general health information'
    ' and guide you through the HayatiCare app. What would you like to know?';

class _Message {
  final String text;
  final bool isUser;
  const _Message({required this.text, required this.isUser});

  _Message copyWith({String? text}) =>
      _Message(text: text ?? this.text, isUser: isUser);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [
    const _Message(text: _welcomeMessage, isUser: false),
  ];
  bool _isLoading = false;
  http.Client? _activeClient;

  @override
  void dispose() {
    _activeClient?.close();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = (text ?? _ctrl.text).trim();
    if (question.isEmpty || _isLoading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_Message(text: question, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    _activeClient?.close();
    final client = http.Client();
    _activeClient = client;

    try {
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'question': question});

      final streamedResponse = await client.send(request);

      // Add empty assistant bubble — will be filled chunk by chunk
      setState(() {
        _messages.add(const _Message(text: '', isUser: false));
        _isLoading = false; // hide spinner as soon as stream starts
      });

      final buffer = StringBuffer();

      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6);
        if (payload == '[DONE]') break;

        buffer.write(payload);
        if (mounted) {
          setState(() {
            _messages[_messages.length - 1] =
                _messages.last.copyWith(text: buffer.toString());
          });
          _scrollToBottom();
        }
      }

      // If the stream produced nothing, show a fallback
      if (buffer.isEmpty && mounted) {
        setState(() {
          _messages[_messages.length - 1] = const _Message(
            text: 'Sorry, I could not get a response. Please try again.',
            isUser: false,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(const _Message(
            text: 'Network error. Please check your connection and try again.',
            isUser: false,
          ));
        });
      }
    } finally {
      client.close();
      if (_activeClient == client) _activeClient = null;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Medical Assistant', style: AppTextStyles.titleLarge),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SuggestionChips(onTap: _send),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingIndicator();
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          _InputBar(ctrl: _ctrl, isLoading: _isLoading, onSend: _send),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final void Function(String) onTap;
  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(_suggestions[i]),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Text(
                _suggestions[i],
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Thinking...',
            style: GoogleFonts.poppins(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    // Show cursor blink effect for the last empty/partial assistant bubble
    final isEmpty = !isUser && message.text.isEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(isUser ? 20 * (1 - v) : -20 * (1 - v), 0),
            child: child,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primaryBlue : AppColors.cardWhite,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: isEmpty
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                )
              : Text(
                  message.text,
                  style: GoogleFonts.poppins(
                    color: isUser ? Colors.white : AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: null,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundGrey,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: isLoading ? null : onSend,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
