import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/ble_connection_state.dart';

void main() {
  group('BleConnectionState', () {
    test('has correct enum values', () {
      expect(BleConnectionState.values, [
        BleConnectionState.disconnected,
        BleConnectionState.connecting,
        BleConnectionState.connected,
        BleConnectionState.disconnecting,
      ]);
    });
  });

  group('BleConnectionStateExtension', () {
    test('isDisconnected returns true only for disconnected', () {
      expect(BleConnectionState.disconnected.isDisconnected, true);
      expect(BleConnectionState.connecting.isDisconnected, false);
      expect(BleConnectionState.connected.isDisconnected, false);
      expect(BleConnectionState.disconnecting.isDisconnected, false);
    });

    test('isConnecting returns true only for connecting', () {
      expect(BleConnectionState.connecting.isConnecting, true);
      expect(BleConnectionState.disconnected.isConnecting, false);
      expect(BleConnectionState.connected.isConnecting, false);
      expect(BleConnectionState.disconnecting.isConnecting, false);
    });

    test('isConnected returns true only for connected', () {
      expect(BleConnectionState.connected.isConnected, true);
      expect(BleConnectionState.disconnected.isConnected, false);
      expect(BleConnectionState.connecting.isConnected, false);
      expect(BleConnectionState.disconnecting.isConnected, false);
    });

    test('isDisconnecting returns true only for disconnecting', () {
      expect(BleConnectionState.disconnecting.isDisconnecting, true);
      expect(BleConnectionState.disconnected.isDisconnecting, false);
      expect(BleConnectionState.connecting.isDisconnecting, false);
      expect(BleConnectionState.connected.isDisconnecting, false);
    });
  });

  group('displayName', () {
    test('disconnected shows correct Chinese name', () {
      expect(BleConnectionState.disconnected.displayName, '未连接');
    });

    test('connecting shows correct Chinese name', () {
      expect(BleConnectionState.connecting.displayName, '连接中...');
    });

    test('connected shows correct Chinese name', () {
      expect(BleConnectionState.connected.displayName, '已连接');
    });

    test('disconnecting shows correct Chinese name', () {
      expect(BleConnectionState.disconnecting.displayName, '断开中...');
    });
  });
}
