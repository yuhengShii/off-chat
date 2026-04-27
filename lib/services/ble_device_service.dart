import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants/ble_constants.dart';
import '../models/ble_connection_state.dart';

class BleDeviceService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get connectionState => _connectionStateController.stream;

  final _dataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get dataStream => _dataController.stream;

  BleConnectionState _state = BleConnectionState.disconnected;
  BleConnectionState get state => _state;

  Future<bool> connect(String deviceId) async {
    try {
      _updateState(BleConnectionState.connecting);

      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(
        timeout: BleConstants.connectionTimeout,
      );

      _connectedDevice = device;
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      final services = await device.discoverServices();
      final uartService = services.firstWhere(
        (s) => s.uuid.str.toLowerCase() == BleConstants.uartServiceUuid,
      );

      _txCharacteristic = uartService.characteristics.firstWhere(
        (c) => c.uuid.str.toLowerCase() == BleConstants.txCharacteristicUuid,
      );

      _rxCharacteristic = uartService.characteristics.firstWhere(
        (c) => c.uuid.str.toLowerCase() == BleConstants.rxCharacteristicUuid,
      );

      await _rxCharacteristic!.setNotifyValue(true);
      _rxCharacteristic!.onValueReceived.listen((value) {
        _dataController.add(Uint8List.fromList(value));
      });

      _updateState(BleConnectionState.connected);
      return true;
    } catch (e) {
      _updateState(BleConnectionState.disconnected);
      return false;
    }
  }

  Future<void> disconnect() async {
    _updateState(BleConnectionState.disconnecting);
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _updateState(BleConnectionState.disconnected);
  }

  Future<bool> sendData(Uint8List data) async {
    if (_txCharacteristic == null || _state != BleConnectionState.connected) {
      return false;
    }
    try {
      await _txCharacteristic!.write(data, withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendString(String text) async {
    final data = Uint8List.fromList(text.codeUnits);
    return sendData(data);
  }

  void _onDisconnected() {
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
