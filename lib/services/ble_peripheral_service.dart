import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BlePeripheralService {
  static const _channel = MethodChannel('off_chat/ble_gatt_server');
  static const _eventChannel = EventChannel('off_chat/ble_gatt_server_events');

  final _incomingDataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get incomingData => _incomingDataController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get centralConnectionState => _connectionStateController.stream;

  StreamSubscription? _eventSub;
  bool _initialized = false;
  bool _isAdvertising = false;

  bool get isAdvertising => _isAdvertising;

  Future<bool> initialize() async {
    if (_initialized) return true;

    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      debugPrint('BlePeripheralService event: $event');
      if (event is Map) {
        final type = event['type'] as String?;
        debugPrint('BlePeripheralService type: $type');
        switch (type) {
          case 'data':
            final rawData = event['data'];
            debugPrint('BlePeripheralService data: $rawData');
            if (rawData is List) {
              try {
                final bytes = Uint8List.fromList(rawData.cast<int>());
                _incomingDataController.add(bytes);
                debugPrint('BlePeripheralService data forwarded, len=${bytes.length}');
              } catch (e, st) {
                debugPrint('BlePeripheralService data parse error: $e\n$st');
              }
            }
            break;
          case 'connected':
            debugPrint('BlePeripheralService connected');
            _connectionStateController.add(true);
            break;
          case 'disconnected':
            debugPrint('BlePeripheralService disconnected');
            _connectionStateController.add(false);
            break;
        }
      }
    });

    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _initialized = result ?? false;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  Future<bool> startAdvertising() async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return false;
    }
    try {
      await Permission.bluetoothAdvertise.request();
    } catch (_) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('startAdvertising');
      _isAdvertising = result ?? false;
      return _isAdvertising;
    } catch (_) {
      _isAdvertising = false;
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod<void>('stopAdvertising');
    } catch (_) {}
    _isAdvertising = false;
  }

  Future<bool> sendNotification(Uint8List data) async {
    if (!_initialized) return false;
    try {
      final result = await _channel.invokeMethod<bool>('sendNotification', {
        'data': data.toList(),
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAdapterName(String name) async {
    try {
      final result = await _channel.invokeMethod<bool>('setAdapterName', {
        'name': name,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    _isAdvertising = false;
    _initialized = false;
    await _eventSub?.cancel();
    _eventSub = null;
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {}
    await _incomingDataController.close();
    await _connectionStateController.close();
  }
}
