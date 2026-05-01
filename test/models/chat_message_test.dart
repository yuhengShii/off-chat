import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final now = DateTime.now();
    const baseId = 'msg-001';

    ChatMessage createMessage({
      String id = baseId,
      String content = 'Hello',
      MessageType type = MessageType.text,
      MessageStatus status = MessageStatus.sent,
      DateTime? timestamp,
      bool isFromMe = true,
      String? voicePath,
      int? voiceDuration,
    }) {
      return ChatMessage(
        id: id,
        content: content,
        type: type,
        status: status,
        timestamp: timestamp ?? now,
        isFromMe: isFromMe,
        voicePath: voicePath,
        voiceDuration: voiceDuration,
      );
    }

    test('creates text message correctly', () {
      final message = createMessage();

      expect(message.id, baseId);
      expect(message.content, 'Hello');
      expect(message.type, MessageType.text);
      expect(message.status, MessageStatus.sent);
      expect(message.timestamp, now);
      expect(message.isFromMe, true);
      expect(message.isTextMessage, true);
      expect(message.isVoiceMessage, false);
      expect(message.isSystemMessage, false);
    });

    test('creates voice message correctly', () {
      final message = createMessage(
        content: '[语音消息]',
        type: MessageType.voice,
        voicePath: '/audio/file',
        voiceDuration: 3000,
      );

      expect(message.isVoiceMessage, true);
      expect(message.isTextMessage, false);
      expect(message.voicePath, '/audio/file');
      expect(message.voiceDuration, 3000);
    });

    test('creates system message correctly', () {
      final message = createMessage(
        content: '连接已建立',
        type: MessageType.system,
        isFromMe: false,
      );

      expect(message.isSystemMessage, true);
      expect(message.isTextMessage, false);
      expect(message.isVoiceMessage, false);
    });

    test('copyWith preserves unchanged fields', () {
      final message = createMessage(status: MessageStatus.sending);
      final updated = message.copyWith(status: MessageStatus.sent);

      expect(updated.status, MessageStatus.sent);
      expect(updated.id, message.id);
      expect(updated.content, message.content);
      expect(updated.type, message.type);
      expect(updated.timestamp, message.timestamp);
      expect(updated.isFromMe, message.isFromMe);
    });

    test('copyWith with no args returns equal message', () {
      final message = createMessage();
      final copied = message.copyWith();

      expect(copied.id, message.id);
      expect(copied.content, message.content);
      expect(copied.status, message.status);
    });

    test('copyWith overrides all fields', () {
      final message = createMessage();
      final newTime = DateTime.now().add(const Duration(hours: 1));

      final updated = message.copyWith(
        id: 'new-id',
        content: 'New content',
        type: MessageType.system,
        status: MessageStatus.delivered,
        timestamp: newTime,
        isFromMe: false,
      );

      expect(updated.id, 'new-id');
      expect(updated.content, 'New content');
      expect(updated.type, MessageType.system);
      expect(updated.status, MessageStatus.delivered);
      expect(updated.timestamp, newTime);
      expect(updated.isFromMe, false);
    });

    test('voice fields are optional', () {
      final message = createMessage();

      expect(message.voicePath, isNull);
      expect(message.voiceDuration, isNull);
    });

    test('supports Chinese content', () {
      final message = createMessage(content: '你好世界');

      expect(message.content, '你好世界');
    });

    test('supports emoji content', () {
      final message = createMessage(content: '😀🌟👍');

      expect(message.content, '😀🌟👍');
    });

    test('supports very long content', () {
      final longContent = 'x' * 500;
      final message = createMessage(content: longContent);

      expect(message.content.length, 500);
    });

    test('empty content is allowed', () {
      final message = createMessage(content: '');

      expect(message.content, '');
    });
  });

  group('MessageType', () {
    test('has correct enum values', () {
      expect(MessageType.values, [MessageType.text, MessageType.voice, MessageType.system]);
    });

    test('text has index 0', () {
      expect(MessageType.text.index, 0);
    });

    test('voice has index 1', () {
      expect(MessageType.voice.index, 1);
    });

    test('system has index 2', () {
      expect(MessageType.system.index, 2);
    });
  });

  group('MessageStatus', () {
    test('has correct enum values', () {
      expect(MessageStatus.values, [
        MessageStatus.sending,
        MessageStatus.sent,
        MessageStatus.delivered,
        MessageStatus.failed,
      ]);
    });

    test('sending has index 0', () {
      expect(MessageStatus.sending.index, 0);
    });

    test('sent has index 1', () {
      expect(MessageStatus.sent.index, 1);
    });

    test('delivered has index 2', () {
      expect(MessageStatus.delivered.index, 2);
    });

    test('failed has index 3', () {
      expect(MessageStatus.failed.index, 3);
    });
  });
}
