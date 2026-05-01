import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/chat_message.dart';
import 'package:off_chat/providers/chat_provider.dart';
import 'package:off_chat/services/message_service.dart';

void main() {
  late ChatProvider provider;
  late MessageService messageService;

  setUp(() {
    provider = ChatProvider();
    messageService = MessageService();
  });

  tearDown(() {
    provider.dispose();
  });

  group('sendTextMessage', () {
    test('adds text message to the list', () {
      final result = provider.sendTextMessage('Hello');

      expect(result, completes);
      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, 'Hello');
      expect(provider.messages.first.type, MessageType.text);
      expect(provider.messages.first.isFromMe, true);
    });

    test('empty content returns false and does not add message', () async {
      final result = await provider.sendTextMessage('');

      expect(result, false);
      expect(provider.messages, isEmpty);
    });

    test('whitespace-only content returns false', () async {
      final result = await provider.sendTextMessage('   ');

      expect(result, false);
      expect(provider.messages, isEmpty);
    });

    test('multiple messages are added in order', () async {
      await provider.sendTextMessage('First');
      await provider.sendTextMessage('Second');
      await provider.sendTextMessage('Third');

      expect(provider.messages.length, 3);
      expect(provider.messages[0].content, 'First');
      expect(provider.messages[1].content, 'Second');
      expect(provider.messages[2].content, 'Third');
    });

    test('each message has a unique ID', () async {
      await provider.sendTextMessage('A');
      await provider.sendTextMessage('B');

      expect(provider.messages[0].id, isNot(provider.messages[1].id));
    });
  });

  group('addMessage', () {
    test('adds a message directly', () {
      final message = ChatMessage(
        id: 'test-id',
        content: 'Direct',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        isFromMe: false,
      );

      provider.addMessage(message);

      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, 'Direct');
    });
  });

  group('setDataStream / receive messages', () {
    test('receives valid encoded message', () async {
      final controller = StreamController<Uint8List>();
      provider.setDataStream(controller.stream);

      final original = messageService.createTextMessage(
        content: '你好',
        isFromMe: false,
      );
      final encoded = messageService.encodeMessage(original);

      controller.add(encoded);
      // Give the stream listener time to process
      await Future.delayed(Duration.zero);

      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, '你好');
      expect(provider.messages.first.isFromMe, false);

      await controller.close();
    });

    test('receives chinese message correctly', () async {
      final controller = StreamController<Uint8List>();
      provider.setDataStream(controller.stream);

      final original = messageService.createTextMessage(
        content: '你好世界！测试中文消息。',
        isFromMe: false,
      );
      controller.add(messageService.encodeMessage(original));
      await Future.delayed(Duration.zero);

      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, '你好世界！测试中文消息。');

      await controller.close();
    });

    test('receives emoji message correctly', () async {
      final controller = StreamController<Uint8List>();
      provider.setDataStream(controller.stream);

      final original = messageService.createTextMessage(
        content: 'Hey 😀👍',
        isFromMe: false,
      );
      controller.add(messageService.encodeMessage(original));
      await Future.delayed(Duration.zero);

      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, 'Hey 😀👍');

      await controller.close();
    });

    test('invalid data is ignored', () async {
      final controller = StreamController<Uint8List>();
      provider.setDataStream(controller.stream);

      controller.add(Uint8List.fromList([0, 1, 2, 3]));
      await Future.delayed(Duration.zero);

      expect(provider.messages, isEmpty);

      await controller.close();
    });

    test('multiple messages are received in order', () async {
      final controller = StreamController<Uint8List>();
      provider.setDataStream(controller.stream);

      final msgs = List.generate(5, (i) => messageService.createTextMessage(
        content: 'Msg $i',
        isFromMe: false,
      ));

      for (final msg in msgs) {
        controller.add(messageService.encodeMessage(msg));
      }
      await Future.delayed(Duration.zero);

      expect(provider.messages.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(provider.messages[i].content, 'Msg $i');
      }

      await controller.close();
    });

    test('replacing data stream cancels previous subscription', () async {
      final controller1 = StreamController<Uint8List>();
      final controller2 = StreamController<Uint8List>();

      provider.setDataStream(controller1.stream);

      final msg = messageService.createTextMessage(content: 'From 1', isFromMe: false);
      controller1.add(messageService.encodeMessage(msg));
      await Future.delayed(Duration.zero);
      expect(provider.messages.length, 1);

      // Replace stream
      provider.setDataStream(controller2.stream);

      // Data from controller1 should no longer be received
      final msg2 = messageService.createTextMessage(content: 'Also From 1', isFromMe: false);
      controller1.add(messageService.encodeMessage(msg2));
      await Future.delayed(Duration.zero);
      expect(provider.messages.length, 1); // Still 1, not 2

      // Data from controller2 should be received
      final msg3 = messageService.createTextMessage(content: 'From 2', isFromMe: false);
      controller2.add(messageService.encodeMessage(msg3));
      await Future.delayed(Duration.zero);
      expect(provider.messages.length, 2);
      expect(provider.messages.last.content, 'From 2');

      await controller1.close();
      await controller2.close();
    });
  });

  group('updateMessageStatus', () {
    test('updates status of existing message', () async {
      await provider.sendTextMessage('Test');

      final msgId = provider.messages.first.id;
      provider.updateMessageStatus(msgId, MessageStatus.delivered);

      expect(provider.messages.first.status, MessageStatus.delivered);
    });

    test('does nothing for unknown message id', () async {
      await provider.sendTextMessage('Test');

      provider.updateMessageStatus('nonexistent', MessageStatus.delivered);

      expect(provider.messages.first.status, MessageStatus.sending);
    });

    test('multiple status updates work', () async {
      await provider.sendTextMessage('Test');
      final msgId = provider.messages.first.id;

      provider.updateMessageStatus(msgId, MessageStatus.sent);
      expect(provider.messages.first.status, MessageStatus.sent);

      provider.updateMessageStatus(msgId, MessageStatus.delivered);
      expect(provider.messages.first.status, MessageStatus.delivered);
    });
  });

  group('clearMessages', () {
    test('clears all messages', () async {
      await provider.sendTextMessage('A');
      await provider.sendTextMessage('B');
      expect(provider.messages.length, 2);

      provider.clearMessages();

      expect(provider.messages, isEmpty);
    });
  });

  group('messages getter', () {
    test('returns unmodifiable list', () async {
      await provider.sendTextMessage('Test');

      expect(provider.messages, isA<List<ChatMessage>>());
      expect(() => provider.messages.clear(), throwsUnsupportedError);
    });
  });
}
