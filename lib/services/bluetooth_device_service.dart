import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_connection_state.dart';
import '../core/constants/ble_constants.dart';

class BluetoothDeviceService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notificationSub;

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;

  final _dataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get dataStream => _dataController.stream;

  BleConnectionState _state = BleConnectionState.disconnected;
  BleConnectionState get state => _state;

  Future<bool> connect(String deviceId, {int retryCount = 0}) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }
      try {
        _updateState(BleConnectionState.connecting);

        _device = BluetoothDevice.fromId(deviceId);

        _connectionSub = _device!.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            _onDisconnected();
          }
        });

        await _device!.connect(timeout: BleConstants.connectionTimeout);

        // 请求 MTU 升级，确保能发送大消息（默认 MTU=23，升级后最大 517）
        try {
          await _device!.requestMtu(517);
        } catch (_) {
          // MTU 协商失败不影响连接
        }

        final services = await _device!.discoverServices();

        final nusService = services.firstWhere(
          (s) => s.uuid.str.toUpperCase() == BleConstants.uartServiceUuid.toUpperCase(),
        );

        for (final char in nusService.characteristics) {
          final uuid = char.uuid.str.toUpperCase();
          if (uuid == BleConstants.txCharacteristicUuid.toUpperCase()) {
            _txCharacteristic = char;
          } else if (uuid == BleConstants.rxCharacteristicUuid.toUpperCase()) {
            _rxCharacteristic = char;
          }
        }

        if (_txCharacteristic == null || _rxCharacteristic == null) {
          throw Exception('NUS characteristics not found');
        }

        await _rxCharacteristic!.setNotifyValue(true);
        _notificationSub = _rxCharacteristic!.onValueReceived.listen((data) {
          _dataController.add(Uint8List.fromList(data));
        });

        _updateState(BleConnectionState.connected);
        return true;
      } catch (e) {
        debugPrint('connect attempt ${attempt+1}/$retryCount failed: $e');
        await _cleanupAfterFailedConnect();
      }
    }
    _updateState(BleConnectionState.disconnected);
    return false;
  }

  Future<void> _cleanupAfterFailedConnect() async {
    _notificationSub?.cancel();
    _notificationSub = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
  }

  Future<void> disconnect() async {
    _updateState(BleConnectionState.disconnecting);
    _notificationSub?.cancel();
    _notificationSub = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    _updateState(BleConnectionState.disconnected);
  }

  Future<bool> sendData(Uint8List data) async {
    if (_txCharacteristic == null) return false;
    try {
      await _txCharacteristic!.write(data, withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendString(String text) async {
    final data = Uint8List.fromList(utf8.encode(text));
    return sendData(data);
  }

  void _onDisconnected() {
    _notificationSub?.cancel();
    _notificationSub = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _device = null;
    _updateState(BleConnectionState.disconnected);
  }

  void _updateState(BleConnectionState state) {
    _state = state;
    _connectionStateController.add(state);
  }

  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _dataController.close();
  }
}
