import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/chat_message.dart';
import 'package:off_chat/services/message_service.dart';

void main() {
  late MessageService service;

  setUp(() {
    service = MessageService();
  });

  group('createTextMessage', () {
    test('creates text message with correct fields', () {
      final message = service.createTextMessage(
        content: 'Hello',
        isFromMe: true,
      );

      expect(message.content, 'Hello');
      expect(message.type, MessageType.text);
      expect(message.isFromMe, true);
      expect(message.status, MessageStatus.sending);
      expect(message.id.isNotEmpty, true);
      expect(message.voicePath, isNull);
      expect(message.voiceDuration, isNull);
    });

    test('creates "from other" message correctly', () {
      final message = service.createTextMessage(
        content: 'Hi',
        isFromMe: false,
      );

      expect(message.isFromMe, false);
      expect(message.status, MessageStatus.delivered);
    });

    test('handles empty content', () {
      final message = service.createTextMessage(
        content: '',
        isFromMe: true,
      );

      expect(message.content, '');
    });

    test('handles long content', () {
      final longText = 'A' * 1000;
      final message = service.createTextMessage(
        content: longText,
        isFromMe: true,
      );

      expect(message.content.length, 1000);
    });
  });

  group('createVoiceMessage', () {
    test('creates voice message with correct fields', () {
      final message = service.createVoiceMessage(
        voicePath: '/path/to/audio',
        duration: 5000,
        isFromMe: true,
      );

      expect(message.content, '[语音消息]');
      expect(message.type, MessageType.voice);
      expect(message.isFromMe, true);
      expect(message.voicePath, '/path/to/audio');
      expect(message.voiceDuration, 5000);
    });
  });

  group('encodeMessage / decodeMessage round-trip', () {
    test('ASCII content round-trips correctly', () {
      final original = service.createTextMessage(
        content: 'Hello, World!',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.id, original.id);
      expect(decoded.content, 'Hello, World!');
      expect(decoded.type, MessageType.text);
      expect(decoded.isFromMe, false); // decode always sets isFromMe=false
      expect(decoded.timestamp.millisecondsSinceEpoch, original.timestamp.millisecondsSinceEpoch);
    });

    test('Chinese content round-trips correctly', () {
      final original = service.createTextMessage(
        content: '你好，世界！',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.content, '你好，世界！');
    });

    test('Mixed Chinese and ASCII round-trips correctly', () {
      final original = service.createTextMessage(
        content: '你好 World！测试 123',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.content, '你好 World！测试 123');
    });

    test('Emoji content round-trips correctly', () {
      final original = service.createTextMessage(
        content: 'Hello 😀 🌟 测试 👍',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.content, 'Hello 😀 🌟 测试 👍');
    });

    test('Special characters round-trips correctly', () {
      final original = service.createTextMessage(
        content: 'Line1\nLine2\tTabbed©™',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.content, 'Line1\nLine2\tTabbed©™');
    });

    test('Voice message round-trips correctly', () {
      final original = service.createVoiceMessage(
        voicePath: '/audio/test.mp3',
        duration: 3000,
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final decoded = service.decodeMessage(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.content, '[语音消息]');
      expect(decoded.type, MessageType.voice);
      expect(decoded.isFromMe, false);
      expect(decoded.voicePath, '/audio/test.mp3');
      expect(decoded.voiceDuration, 3000);
    });

    test('Multiple messages encode independently', () {
      final msgs = List.generate(5, (i) => service.createTextMessage(
        content: 'Message $i',
        isFromMe: true,
      ));

      for (final msg in msgs) {
        final encoded = service.encodeMessage(msg);
        final decoded = service.decodeMessage(encoded);
        expect(decoded, isNotNull);
        expect(decoded!.id, msg.id);
        expect(decoded.content, msg.content);
      }
    });
  });

  group('decodeMessage edge cases', () {
    test('returns null for empty data', () {
      final result = service.decodeMessage(Uint8List(0));
      expect(result, isNull);
    });

    test('returns null for invalid data', () {
      final result = service.decodeMessage(Uint8List.fromList([0, 1, 2, 3, 4]));
      expect(result, isNull);
    });

    test('returns null for non-JSON data', () {
      final result = service.decodeMessage(Uint8List.fromList(
        utf8.encode('this is not json'),
      ));
      expect(result, isNull);
    });

    test('returns null for JSON array', () {
      final result = service.decodeMessage(Uint8List.fromList(
        utf8.encode('[1, 2, 3]'),
      ));
      expect(result, isNull);
    });

    test('returns null for partial JSON', () {
      final result = service.decodeMessage(Uint8List.fromList(
        utf8.encode('{"id":"abc"'),
      ));
      expect(result, isNull);
    });
  });

  group('generateMessageId', () {
    test('generates unique IDs', () {
      final ids = Set<String>.from(
        List.generate(100, (_) => service.generateMessageId()),
      );
      expect(ids.length, 100);
    });

    test('generates non-empty IDs', () {
      final id = service.generateMessageId();
      expect(id.isNotEmpty, true);
    });
  });

  group('json encoding format', () {
    test('encoded bytes are valid UTF-8', () {
      final original = service.createTextMessage(
        content: '你好',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      // Verify we can decode the bytes as UTF-8 and parse as JSON
      final jsonString = utf8.decode(encoded);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['content'], '你好');
      expect(decoded['id'], original.id);
      expect(decoded['type'], MessageType.text.index);
      expect(decoded['isFromMe'], true);
    });

    test('UTF-8 encoded bytes are shorter than UTF-16 code units for ASCII', () {
      final original = service.createTextMessage(
        content: 'Hello World',
        isFromMe: true,
      );

      final encoded = service.encodeMessage(original);
      final jsonString = jsonEncode({
        'id': original.id,
        'content': original.content,
        'type': original.type.index,
        'timestamp': original.timestamp.millisecondsSinceEpoch,
        'isFromMe': original.isFromMe,
      });

      // UTF-8 for ASCII is same as UTF-16 low bytes
      expect(encoded.length, lessThanOrEqualTo(jsonString.codeUnits.length));
    });
  });
}
