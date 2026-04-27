enum MessageType { text, voice, system }

enum MessageStatus { sending, sent, delivered, failed }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isFromMe;
  final String? voicePath; // 语音消息路径（预留）
  final int? voiceDuration; // 语音时长（毫秒）（预留）

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.isFromMe,
    this.voicePath,
    this.voiceDuration,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    bool? isFromMe,
    String? voicePath,
    int? voiceDuration,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      voicePath: voicePath ?? this.voicePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }

  bool get isTextMessage => type == MessageType.text;
  bool get isVoiceMessage => type == MessageType.voice;
  bool get isSystemMessage => type == MessageType.system;
}
