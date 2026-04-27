import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/chat_message.dart';
import 'package:off_chat/models/device_info.dart';

void main() {
  group('ChatMessage', () {
    test('creates text message correctly', () {
      final message = ChatMessage(
        id: '1',
        content: 'Hello',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        isFromMe: true,
      );

      expect(message.content, 'Hello');
      expect(message.type, MessageType.text);
      expect(message.isFromMe, true);
    });

    test('copyWith works correctly', () {
      final message = ChatMessage(
        id: '1',
        content: 'Hello',
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isFromMe: true,
      );

      final updated = message.copyWith(status: MessageStatus.sent);
      expect(updated.status, MessageStatus.sent);
      expect(updated.content, 'Hello');
    });

    test('isTextMessage returns correct value', () {
      final textMessage = ChatMessage(
        id: '1',
        content: 'Hello',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        isFromMe: true,
      );

      final voiceMessage = ChatMessage(
        id: '2',
        content: '[语音]',
        type: MessageType.voice,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        isFromMe: true,
      );

      expect(textMessage.isTextMessage, true);
      expect(textMessage.isVoiceMessage, false);
      expect(voiceMessage.isVoiceMessage, true);
    });
  });

  group('DeviceInfo', () {
    test('creates device info correctly', () {
      const device = DeviceInfo(
        id: 'abc123',
        name: 'Test Device',
        rssi: -50,
      );

      expect(device.id, 'abc123');
      expect(device.name, 'Test Device');
      expect(device.rssi, -50);
      expect(device.isConnected, false);
    });

    test('copyWith works correctly', () {
      const device = DeviceInfo(
        id: 'abc123',
        name: 'Test Device',
        rssi: -50,
      );

      final connected = device.copyWith(isConnected: true);
      expect(connected.isConnected, true);
      expect(connected.name, 'Test Device');
    });

    test('equality works correctly', () {
      const device1 = DeviceInfo(id: 'abc', name: 'Device A', rssi: -50);
      const device2 = DeviceInfo(id: 'abc', name: 'Device B', rssi: -60);
      const device3 = DeviceInfo(id: 'xyz', name: 'Device A', rssi: -50);

      expect(device1 == device2, true);
      expect(device1 == device3, false);
    });
  });
}
