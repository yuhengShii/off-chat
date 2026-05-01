import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show FlutterBluePlus, ScanResult, BluetoothAdapterState;
import 'package:permission_handler/permission_handler.dart';
import '../models/device_info.dart';
import '../core/constants/ble_constants.dart';

class BluetoothService {
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final _adapterStateController = StreamController<BluetoothAdapterState>.broadcast();
  Stream<BluetoothAdapterState> get adapterState => _adapterStateController.stream;

  final _scanResultsController = StreamController<List<DeviceInfo>>.broadcast();
  Stream<List<DeviceInfo>> get scanResults => _scanResultsController.stream;

  final List<DeviceInfo> _discoveredDevices = [];

  BluetoothService() {
    _initAdapterStateListener();
  }

  void _initAdapterStateListener() {
    _stateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterStateController.add(state);
    });
  }

  Future<bool> isAdapterEnabled() async {
    return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
  }

  Future<bool> requestEnable() async {
    try {
      await FlutterBluePlus.turnOn();
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  bool get isScanning => _scanSubscription != null;

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final deviceId = result.device.remoteId.str;
      if (deviceId.isEmpty) continue;

      final hasNus = result.advertisementData.serviceUuids
          .any((uuid) => uuid.str == BleConstants.uartServiceUuid);
      if (!hasNus) continue;

      final name = result.advertisementData.advName;
      final displayName = name.isNotEmpty ? name : (result.device.platformName.isNotEmpty ? result.device.platformName : 'Unknown Device');

      final device = DeviceInfo(
        id: deviceId,
        name: displayName,
        rssi: result.rssi,
        isConnected: false,
      );

      final existingIndex = _discoveredDevices.indexWhere((d) => d.id == device.id);
      if (existingIndex >= 0) {
        _discoveredDevices[existingIndex] = device;
      } else {
        _discoveredDevices.add(device);
      }
    }
    _scanResultsController.add(List.from(_discoveredDevices));
  }

  Future<bool> startScan() async {
    if (_scanSubscription != null) return true;

    try {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();
    } catch (_) {
      return false;
    }

    if (!await isAdapterEnabled()) return false;

    _discoveredDevices.clear();
    _scanResultsController.add(List.from(_discoveredDevices));

    // 必须在 startScan 之前设置 subscription，否则会错过扫描结果
    _scanSubscription = FlutterBluePlus.scanResults.listen(_onScanResults);

    try {
      await FlutterBluePlus.startScan(timeout: BleConstants.scanDuration);
      return true;
    } catch (_) {
      _scanSubscription?.cancel();
      _scanSubscription = null;
      return false;
    }
  }

  Future<void> stopScan() async {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopScan();
    await _stateSubscription?.cancel();
    await _adapterStateController.close();
    await _scanResultsController.close();
  }
}
