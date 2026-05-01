import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothAdapterState, FlutterBluePlus;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_service.dart';
import '../services/bluetooth_device_service.dart';
import '../services/ble_peripheral_service.dart';
import '../models/ble_connection_state.dart';
import '../models/device_info.dart';

enum HandshakePhase { none, waiting, incoming, accepted, rejected }

class BleProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  final BluetoothDeviceService _deviceService = BluetoothDeviceService();
  final BlePeripheralService _peripheralService = BlePeripheralService();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  DeviceInfo? _connectedDevice;
  String? _errorMessage;
  String _deviceName = '';

  HandshakePhase _handshakePhase = HandshakePhase.none;
  String? _pendingRequestFrom;

  Timer? _handshakeTimer;

  final List<String> _debugLog = [];
  String get debugLog => _debugLog.join('\n');
  void _log(String msg) {
    _debugLog.add('${DateTime.now().second.toString().padLeft(2, '0')}:${DateTime.now().millisecond.toString().padLeft(3, '0')} $msg');
    if (_debugLog.length > 50) _debugLog.removeAt(0);
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<BleConnectionState>? _connectionStateSub;
  StreamSubscription<bool>? _peripheralConnSub;
  StreamSubscription<Uint8List>? _deviceDataSub;
  StreamSubscription<Uint8List>? _peripheralDataSub;

  final _incomingDataController = StreamController<Uint8List>.broadcast();

  BluetoothAdapterState get adapterState => _adapterState;
  BleConnectionState get connectionState => _connectionState;
  DeviceInfo? get connectedDevice => _connectedDevice;
  String? get errorMessage => _errorMessage;
  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;
  bool get isConnected => _connectionState == BleConnectionState.connected;

  Stream<List<DeviceInfo>> get scanResults => _bluetoothService.scanResults;
  bool get isAdvertising => _peripheralService.isAdvertising;
  HandshakePhase get handshakePhase => _handshakePhase;
  String? get pendingRequestFrom => _pendingRequestFrom;
  String get deviceName => _deviceName;
  Stream<Uint8List> get dataStream => _incomingDataController.stream;

  BleProvider() {
    _init();
    _initPeripheral();
    _initDataMerge();
  }

  void _init() {
    _adapterStateSub = _bluetoothService.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    _connectionStateSub = _deviceService.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  Future<void> _initPeripheral() async {
    final ok = await _peripheralService.initialize();
    _log('peripheral init: ${ok ? "OK" : "FAIL"}');

    try {
      _deviceName = await FlutterBluePlus.adapterName;
    } catch (_) {
      _deviceName = '';
    }
    // 加载用户自定义设备名
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('device_name');
      if (saved != null && saved.isNotEmpty) {
        _deviceName = saved;
      }
    } catch (_) {}
    _log('device name: $_deviceName');

    _peripheralConnSub = _peripheralService.centralConnectionState.listen((connected) {
      _log('central conn state: $connected');
      if (!connected && _deviceService.state == BleConnectionState.disconnected) {
        _connectionState = BleConnectionState.disconnected;
        _connectedDevice = null;
        notifyListeners();
      }
    });
  }

  void _initDataMerge() {
    _deviceDataSub = _deviceService.dataStream.listen(_processIncomingData);
    _peripheralDataSub = _peripheralService.incomingData.listen(_processIncomingData);
  }

  void _processIncomingData(Uint8List data) {
    final message = utf8.decode(data);
    _log('incoming raw: $message');
    if (message.startsWith('{"type":"connection_')) {
      _handleHandshakeMessage(message);
    } else {
      _incomingDataController.add(data);
    }
  }

  void _handleHandshakeMessage(String message) {
    _log('handshake msg: $message');
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String;
      switch (type) {
        case 'connection_request':
          _log('HS: incoming request from ${data['name']}');
          _connectionState = BleConnectionState.connected;
          _pendingRequestFrom = data['name'] as String? ?? '未知设备';
          _connectedDevice = DeviceInfo(
            id: '',
            name: _pendingRequestFrom!,
            rssi: 0,
            isConnected: true,
          );
          _handshakePhase = HandshakePhase.incoming;
          notifyListeners();
        case 'connection_accepted':
          _log('HS: accepted');
          _cancelHandshakeTimer();
          _handshakePhase = HandshakePhase.accepted;
          notifyListeners();
        case 'connection_rejected':
          _log('HS: rejected');
          _cancelHandshakeTimer();
          _handshakePhase = HandshakePhase.rejected;
          _errorMessage = '对方拒绝了连接';
          disconnect();
          notifyListeners();
      }
    } catch (e) {
      _log('HS: parse error: $e');
    }
  }

  void _cancelHandshakeTimer() {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
  }

  Future<bool> initiateHandshake(DeviceInfo device) async {
    _cancelHandshakeTimer();
    _log('initiateHandshake: ${device.id} name=${device.name}');
    _errorMessage = null;
    _connectedDevice = device;
    _handshakePhase = HandshakePhase.waiting;
    notifyListeners();

    _log('connecting to ${device.id}...');
    final connected = await _deviceService.connect(device.id, retryCount: 2);
    _log('connect result: $connected');
    if (!connected) {
      _errorMessage = '连接失败';
      _connectedDevice = null;
      _handshakePhase = HandshakePhase.none;
      notifyListeners();
      return false;
    }

    final request = jsonEncode({
      'type': 'connection_request',
      'name': _deviceName,
    });
    _log('sending request: $request');
    final sent = await _deviceService.sendString(request);
    _log('request sent: $sent');
    if (!sent) {
      _errorMessage = '发送连接请求失败';
      _connectedDevice = null;
      _handshakePhase = HandshakePhase.none;
      disconnect();
      notifyListeners();
      return false;
    }

    _handshakeTimer = Timer(const Duration(seconds: 15), () {
      if (_handshakePhase == HandshakePhase.waiting) {
        _log('handshake timeout');
        _errorMessage = '连接超时：对方未响应';
        _handshakePhase = HandshakePhase.none;
        disconnect();
        notifyListeners();
      }
    });

    return true;
  }

  Future<void> acceptHandshake() async {
    _cancelHandshakeTimer();
    _log('acceptHandshake');
    final response = jsonEncode({
      'type': 'connection_accepted',
      'name': _deviceName,
    });
    await _peripheralService.sendNotification(Uint8List.fromList(utf8.encode(response)));
    _handshakePhase = HandshakePhase.accepted;
    _pendingRequestFrom = null;
    notifyListeners();
  }

  Future<void> rejectHandshake() async {
    _cancelHandshakeTimer();
    _log('rejectHandshake');
    final response = jsonEncode({
      'type': 'connection_rejected',
    });
    await _peripheralService.sendNotification(Uint8List.fromList(utf8.encode(response)));
    _handshakePhase = HandshakePhase.none;
    _pendingRequestFrom = null;
    await disconnect();
    notifyListeners();
  }

  void resetHandshake() {
    _cancelHandshakeTimer();
    _handshakePhase = HandshakePhase.none;
    _pendingRequestFrom = null;
    notifyListeners();
  }

  Future<bool> startAdvertising() async {
    final result = await _peripheralService.startAdvertising();
    notifyListeners();
    return result;
  }

  Future<void> stopAdvertising() async {
    await _peripheralService.stopAdvertising();
    notifyListeners();
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

  Future<void> setDeviceName(String name) async {
    if (name.trim().isEmpty) return;
    _deviceName = name.trim();
    await _peripheralService.setAdapterName(_deviceName);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_name', _deviceName);
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> sendMessage(Uint8List data) async {
    var sent = await _deviceService.sendData(data);
    if (!sent) {
      sent = await _peripheralService.sendNotification(data);
    }
    return sent;
  }

  @override
  void dispose() {
    _cancelHandshakeTimer();
    _adapterStateSub?.cancel();
    _connectionStateSub?.cancel();
    _peripheralConnSub?.cancel();
    _deviceDataSub?.cancel();
    _peripheralDataSub?.cancel();
    _bluetoothService.dispose();
    _deviceService.dispose();
    _peripheralService.dispose();
    _incomingDataController.close();
    super.dispose();
  }
}
