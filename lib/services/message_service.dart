import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class MessageService {
  final _uuid = const Uuid();

  String generateMessageId() => _uuid.v4();

  Uint8List encodeMessage(ChatMessage message) {
    final data = {
      'id': message.id,
      'content': message.content,
      'type': message.type.index,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'isFromMe': message.isFromMe,
      if (message.voicePath != null) 'voicePath': message.voicePath,
      if (message.voiceDuration != null) 'voiceDuration': message.voiceDuration,
    };
    final jsonString = jsonEncode(data);
    return Uint8List.fromList(jsonString.codeUnits);
  }

  ChatMessage? decodeMessage(Uint8List data) {
    try {
      final jsonString = String.fromCharCodes(data);
      final dataMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChatMessage(
        id: dataMap['id'] as String,
        content: dataMap['content'] as String,
        type: MessageType.values[dataMap['type'] as int],
        status: MessageStatus.delivered,
        timestamp: DateTime.fromMillisecondsSinceEpoch(dataMap['timestamp'] as int),
        isFromMe: false,
        voicePath: dataMap['voicePath'] as String?,
        voiceDuration: dataMap['voiceDuration'] as int?,
      );
    } catch (e) {
      return null;
    }
  }

  ChatMessage createTextMessage({
    required String content,
    required bool isFromMe,
  }) {
    return ChatMessage(
      id: generateMessageId(),
      content: content,
      type: MessageType.text,
      status: isFromMe ? MessageStatus.sending : MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromMe: isFromMe,
    );
  }

  // 预留：创建语音消息
  ChatMessage createVoiceMessage({
    required String voicePath,
    required int duration,
    required bool isFromMe,
  }) {
    return ChatMessage(
      id: generateMessageId(),
      content: '[语音消息]',
      type: MessageType.voice,
      status: isFromMe ? MessageStatus.sending : MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromMe: isFromMe,
      voicePath: voicePath,
      voiceDuration: duration,
    );
  }
}
