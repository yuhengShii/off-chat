import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants/ble_constants.dart';
import '../models/device_info.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  final _scanResultsController = StreamController<List<DeviceInfo>>.broadcast();
  Stream<List<DeviceInfo>> get scanResults => _scanResultsController.stream;

  final _adapterStateController = StreamController<BluetoothAdapterState>.broadcast();
  Stream<BluetoothAdapterState> get adapterState => _adapterStateController.stream;

  bool get isScanning => FlutterBluePlus.isScanningNow;

  BleService() {
    _initAdapterStateListener();
  }

  void _initAdapterStateListener() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterStateController.add(state);
    });
  }

  Future<bool> startScan() async {
    if (isScanning) return false;

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      return false;
    }

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => DeviceInfo(
                id: r.device.remoteId.str,
                name: r.device.platformName,
                rssi: r.rssi,
              ))
          .toList();
      _scanResultsController.add(devices);
    });

    await FlutterBluePlus.startScan(
      timeout: BleConstants.scanDuration,
      withServices: [Guid(BleConstants.uartServiceUuid)],
    );

    return true;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> dispose() async {
    await stopScan();
    await _adapterStateSubscription?.cancel();
    await _scanResultsController.close();
    await _adapterStateController.close();
  }
}
