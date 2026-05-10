// lib/features/chat/data/chat_message_model.dart
// ChatMessage — local model (mirrors ChatMessage from chat.py)
// History stored in memory only (Zero-Knowledge: stateless server)

class ChatMessageModel {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final List<Map<String, String>> sources; // [{doctor_name, specialization}]

  ChatMessageModel({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.sources = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
