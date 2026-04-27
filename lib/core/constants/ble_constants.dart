class BleConstants {
  // Nordic UART Service UUID
  static const String uartServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  // TX Characteristic (Write) - 发送数据给设备
  static const String txCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  // RX Characteristic (Notify) - 从设备接收数据
  static const String rxCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // 扫描参数
  static const Duration scanDuration = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 15);

  // 重连参数
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);

  // 消息参数
  static const int maxMessageLength = 512;
}
