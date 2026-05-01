import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../services/bluetooth_service.dart';

class DeviceListProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();

  List<DeviceInfo> _devices = [];
  String? _errorMessage;
  StreamSubscription? _scanSub;

  List<DeviceInfo> get devices => _devices;
  bool get isScanning => _bluetoothService.isScanning;
  String? get errorMessage => _errorMessage;

  DeviceListProvider() {
    _init();
  }

  void _init() {
    _scanSub = _bluetoothService.scanResults.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    _errorMessage = null;
    _devices = [];
    notifyListeners();

    final success = await _bluetoothService.startScan();
    if (!success) {
      _errorMessage = '无法开始扫描，请检查蓝牙是否开启';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
    notifyListeners();
  }

  void clearDevices() {
    _devices = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}