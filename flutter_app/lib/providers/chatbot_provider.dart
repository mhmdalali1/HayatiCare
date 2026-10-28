import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/medical_ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

class ChatbotState {
  final List<ChatMessage> messages;
  final List<String> faqs;
  final bool isLoading;

  const ChatbotState({
    this.messages = const [],
    this.faqs = const [],
    this.isLoading = false,
  });
}

const _sampleQuestions = [
  'What is the normal range for temperature?',
  'What is the range of PLT?',
  'What is the role of hemoglobin?',
  'What does blood glucose do?',
  'What is WBC used for?',
];

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier() : super(const ChatbotState()) {
    _init();
  }

  void _init() {
    final welcome = const ChatMessage(
      text: 'Hello! I can answer questions about medical test ranges and '
          'test functions.\n\n'
          'Ask me about:\n'
          '• Normal ranges for any test\n'
          '• What each test does\n\n'
          'Tap a question below or type your own.',
      isUser: false,
    );
    state = ChatbotState(messages: [welcome], faqs: _sampleQuestions);
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = ChatbotState(
      messages: [...state.messages, userMsg],
      faqs: state.faqs,
      isLoading: true,
    );

    final reply = getAiResponse(text);
    final botMsg = ChatMessage(text: reply, isUser: false);
    state = ChatbotState(
      messages: [...state.messages, botMsg],
      faqs: state.faqs,
    );
  }
}

final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});
