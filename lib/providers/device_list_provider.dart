import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../services/ble_service.dart';

class DeviceListProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  List<DeviceInfo> _devices = [];
  bool _isScanning = false;
  String? _errorMessage;
  StreamSubscription? _scanSub;

  List<DeviceInfo> get devices => _devices;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  DeviceListProvider() {
    _init();
  }

  void _init() {
    _scanSub = _bleService.scanResults.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    _errorMessage = null;
    _devices = [];
    _isScanning = true;
    notifyListeners();

    final success = await _bleService.startScan();
    if (!success) {
      _errorMessage = '无法开始扫描，请检查蓝牙是否开启';
    }
    _isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  void clearDevices() {
    _devices = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
