enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

extension BleConnectionStateExtension on BleConnectionState {
  bool get isDisconnected => this == BleConnectionState.disconnected;
  bool get isConnecting => this == BleConnectionState.connecting;
  bool get isConnected => this == BleConnectionState.connected;
  bool get isDisconnecting => this == BleConnectionState.disconnecting;

  String get displayName {
    switch (this) {
      case BleConnectionState.disconnected:
        return '未连接';
      case BleConnectionState.connecting:
        return '连接中...';
      case BleConnectionState.connected:
        return '已连接';
      case BleConnectionState.disconnecting:
        return '断开中...';
    }
  }
}
