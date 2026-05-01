import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/core/constants/ble_constants.dart';

void main() {
  group('BleConstants', () {
    test('UART service UUID is correct', () {
      expect(BleConstants.uartServiceUuid, '6e400001-b5a3-f393-e0a9-e50e24dcca9e');
    });

    test('TX characteristic UUID is correct', () {
      expect(BleConstants.txCharacteristicUuid, '6e400002-b5a3-f393-e0a9-e50e24dcca9e');
    });

    test('RX characteristic UUID is correct', () {
      expect(BleConstants.rxCharacteristicUuid, '6e400003-b5a3-f393-e0a9-e50e24dcca9e');
    });

    test('scan duration is 15 seconds', () {
      expect(BleConstants.scanDuration.inSeconds, 15);
    });

    test('connection timeout is 30 seconds', () {
      expect(BleConstants.connectionTimeout.inSeconds, 30);
    });

    test('max reconnect attempts is 3', () {
      expect(BleConstants.maxReconnectAttempts, 3);
    });

    test('reconnect delay is 2 seconds', () {
      expect(BleConstants.reconnectDelay.inSeconds, 2);
    });

    test('max message length is 512', () {
      expect(BleConstants.maxMessageLength, 512);
    });
  });
}
