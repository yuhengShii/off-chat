import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/ble_device_service.dart';
import '../models/ble_connection_state.dart';
import '../models/device_info.dart';

class BleProvider extends ChangeNotifier {
  final BleService _bleService = BleService();
  final BleDeviceService _deviceService = BleDeviceService();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  DeviceInfo? _connectedDevice;
  String? _errorMessage;

  StreamSubscription? _adapterStateSub;
  StreamSubscription? _connectionStateSub;

  BluetoothAdapterState get adapterState => _adapterState;
  BleConnectionState get connectionState => _connectionState;
  DeviceInfo? get connectedDevice => _connectedDevice;
  String? get errorMessage => _errorMessage;
  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;
  bool get isConnected => _connectionState == BleConnectionState.connected;

  Stream<List<DeviceInfo>> get scanResults => _bleService.scanResults;

  BleProvider() {
    _init();
  }

  void _init() {
    _adapterStateSub = _bleService.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    _connectionStateSub = _deviceService.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _deviceService.dataStream.listen((data) {
      // 数据接收由 ChatProvider 处理
    });
  }

  Future<bool> startScan() async {
    _errorMessage = null;
    final result = await _bleService.startScan();
    if (!result) {
      _errorMessage = '无法开始扫描，请检查蓝牙是否开启';
      notifyListeners();
    }
    return result;
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
  }

  Future<bool> connectToDevice(DeviceInfo device) async {
    _errorMessage = null;
    _connectedDevice = device;
    notifyListeners();

    final result = await _deviceService.connect(device.id);
    if (!result) {
      _errorMessage = '连接失败';
      _connectedDevice = null;
      notifyListeners();
    }
    return result;
  }

  Future<void> disconnect() async {
    await _deviceService.disconnect();
    _connectedDevice = null;
  }

  Future<bool> sendMessage(String text) async {
    return _deviceService.sendString(text);
  }

  Stream<Uint8List> get dataStream => _deviceService.dataStream;

  @override
  void dispose() {
    _adapterStateSub?.cancel();
    _connectionStateSub?.cancel();
    _bleService.dispose();
    _deviceService.dispose();
    super.dispose();
  }
}
