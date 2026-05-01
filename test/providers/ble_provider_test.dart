import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:off_chat/models/ble_connection_state.dart';
import 'package:off_chat/models/device_info.dart';
import 'package:off_chat/providers/ble_provider.dart';
import 'package:off_chat/services/bluetooth_service.dart';
import 'package:off_chat/services/bluetooth_device_service.dart';
import 'package:off_chat/services/ble_peripheral_service.dart';

class MockBluetoothService extends Mock implements BluetoothService {}
class MockBluetoothDeviceService extends Mock implements BluetoothDeviceService {}
class MockBlePeripheralService extends Mock implements BlePeripheralService {}

void main() {
  late MockBluetoothService mockBtService;
  late MockBluetoothDeviceService mockDeviceService;
  late MockBlePeripheralService mockPeripheralService;

  late StreamController<BleConnectionState> connStateController;
  late StreamController<Uint8List> deviceDataController;
  late StreamController<Uint8List> peripheralDataController;
  late StreamController<bool> centralConnController;

  late BleProvider provider;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'device_name': 'TestDevice'});

    mockBtService = MockBluetoothService();
    mockDeviceService = MockBluetoothDeviceService();
    mockPeripheralService = MockBlePeripheralService();

    connStateController = StreamController<BleConnectionState>.broadcast();
    deviceDataController = StreamController<Uint8List>.broadcast();
    peripheralDataController = StreamController<Uint8List>.broadcast();
    centralConnController = StreamController<bool>.broadcast();

    // BluetoothService stubs
    when(() => mockBtService.adapterState).thenAnswer((_) => const Stream.empty());
    when(() => mockBtService.scanResults).thenAnswer((_) => const Stream.empty());
    when(() => mockBtService.dispose()).thenAnswer((_) async {});
    when(() => mockBtService.isScanning).thenReturn(false);

    // BluetoothDeviceService stubs
    when(() => mockDeviceService.connectionState).thenAnswer((_) => connStateController.stream);
    when(() => mockDeviceService.dataStream).thenAnswer((_) => deviceDataController.stream);
    when(() => mockDeviceService.state).thenReturn(BleConnectionState.disconnected);
    when(() => mockDeviceService.connect(any(), retryCount: any(named: 'retryCount')))
        .thenAnswer((_) async => true);
    when(() => mockDeviceService.disconnect()).thenAnswer((_) async {});
    when(() => mockDeviceService.sendData(any())).thenAnswer((_) async => true);
    when(() => mockDeviceService.sendString(any())).thenAnswer((_) async => true);
    when(() => mockDeviceService.dispose()).thenAnswer((_) async {});

    // BlePeripheralService stubs
    when(() => mockPeripheralService.initialize()).thenAnswer((_) async => true);
    when(() => mockPeripheralService.isAdvertising).thenReturn(false);
    when(() => mockPeripheralService.centralConnectionState)
        .thenAnswer((_) => centralConnController.stream);
    when(() => mockPeripheralService.incomingData)
        .thenAnswer((_) => peripheralDataController.stream);
    when(() => mockPeripheralService.startAdvertising()).thenAnswer((_) async => true);
    when(() => mockPeripheralService.stopAdvertising()).thenAnswer((_) async {});
    when(() => mockPeripheralService.sendNotification(any())).thenAnswer((_) async => true);
    when(() => mockPeripheralService.setAdapterName(any())).thenAnswer((_) async => true);
    when(() => mockPeripheralService.dispose()).thenAnswer((_) async {});

    provider = BleProvider(
      bluetoothService: mockBtService,
      deviceService: mockDeviceService,
      peripheralService: mockPeripheralService,
    );

    // Wait for async init
    await Future.delayed(Duration.zero);
  });

  tearDown(() async {
    provider.dispose();
    await connStateController.close();
    await deviceDataController.close();
    await peripheralDataController.close();
    await centralConnController.close();
  });

  group('initial state', () {
    test('connection state is disconnected', () {
      expect(provider.connectionState, BleConnectionState.disconnected);
    });

    test('isConnected is false', () {
      expect(provider.isConnected, false);
    });

    test('handshake phase is none', () {
      expect(provider.handshakePhase, HandshakePhase.none);
    });

    test('pendingRequestFrom is null', () {
      expect(provider.pendingRequestFrom, isNull);
    });

    test('connectedDevice is null', () {
      expect(provider.connectedDevice, isNull);
    });

    test('errorMessage is null', () {
      expect(provider.errorMessage, isNull);
    });

    test('isAdvertising is false', () {
      expect(provider.isAdvertising, false);
    });

    test('deviceName loads from SharedPreferences', () {
      expect(provider.deviceName, 'TestDevice');
    });

    test('dataStream is a broadcast stream', () {
      expect(provider.dataStream, isA<Stream<List<int>>>());
    });
  });

  group('connection state stream', () {
    test('updates connection state from service stream', () async {
      connStateController.add(BleConnectionState.connecting);
      await Future.delayed(Duration.zero);
      expect(provider.connectionState, BleConnectionState.connecting);

      connStateController.add(BleConnectionState.connected);
      await Future.delayed(Duration.zero);
      expect(provider.connectionState, BleConnectionState.connected);

      expect(provider.isConnected, true);
    });

    test('isConnected reflects connection state', () async {
      expect(provider.isConnected, false);

      connStateController.add(BleConnectionState.connected);
      await Future.delayed(Duration.zero);
      expect(provider.isConnected, true);

      connStateController.add(BleConnectionState.disconnected);
      await Future.delayed(Duration.zero);
      expect(provider.isConnected, false);
    });
  });

  group('resetHandshake', () {
    test('sets phase to none', () {
      provider.resetHandshake();
      expect(provider.handshakePhase, HandshakePhase.none);
    });

    test('clears pendingRequestFrom', () {
      provider.resetHandshake();
      expect(provider.pendingRequestFrom, isNull);
    });

    test('multiple calls do not throw', () {
      provider.resetHandshake();
      provider.resetHandshake();
      provider.resetHandshake();
    });
  });

  group('setDeviceName', () {
    test('updates device name', () async {
      await provider.setDeviceName('NewName');
      expect(provider.deviceName, 'NewName');
    });

    test('ignores empty name', () async {
      await provider.setDeviceName('');
      expect(provider.deviceName, 'TestDevice');
    });

    test('ignores whitespace-only name', () async {
      await provider.setDeviceName('   ');
      expect(provider.deviceName, 'TestDevice');
    });

    test('trims whitespace from name', () async {
      await provider.setDeviceName('  TrimmedName  ');
      expect(provider.deviceName, 'TrimmedName');
    });

    test('calls setAdapterName on peripheral service', () async {
      await provider.setDeviceName('NewName');
      verify(() => mockPeripheralService.setAdapterName('NewName')).called(1);
    });
  });

  group('startAdvertising', () {
    test('delegates to peripheral service', () async {
      final result = await provider.startAdvertising();
      expect(result, true);
      verify(() => mockPeripheralService.startAdvertising()).called(1);
    });

    test('returns false when peripheral fails', () async {
      when(() => mockPeripheralService.startAdvertising()).thenAnswer((_) async => false);
      final result = await provider.startAdvertising();
      expect(result, false);
    });
  });

  group('stopAdvertising', () {
    test('delegates to peripheral service', () async {
      await provider.stopAdvertising();
      verify(() => mockPeripheralService.stopAdvertising()).called(1);
    });
  });

  group('isAdvertising', () {
    test('reflects peripheral advertising state', () {
      when(() => mockPeripheralService.isAdvertising).thenReturn(true);
      expect(provider.isAdvertising, true);
    });
  });

  group('connectToDevice', () {
    const device = DeviceInfo(id: 'aa:bb', name: 'Test', rssi: -50);

    test('sets connectedDevice on success', () async {
      final result = await provider.connectToDevice(device);
      expect(result, true);
      expect(provider.connectedDevice?.id, 'aa:bb');
      expect(provider.connectedDevice?.name, 'Test');
    });

    test('sets error on failure', () async {
      when(() => mockDeviceService.connect(device.id)).thenAnswer((_) async => false);
      final result = await provider.connectToDevice(device);
      expect(result, false);
      expect(provider.errorMessage, isNotNull);
      expect(provider.connectedDevice, isNull);
    });
  });

  group('disconnect', () {
    test('clears connectedDevice', () async {
      await provider.connectToDevice(const DeviceInfo(id: 'x', name: 'X', rssi: 0));
      expect(provider.connectedDevice, isNotNull);

      await provider.disconnect();
      expect(provider.connectedDevice, isNull);
    });

    test('calls service disconnect', () async {
      await provider.disconnect();
      verify(() => mockDeviceService.disconnect()).called(1);
    });
  });

  group('dataStream', () {
    test('forwards data from device service', () async {
      final received = <Uint8List>[];
      provider.dataStream.listen((d) => received.add(d));

      final data = Uint8List.fromList([104, 101, 108, 108, 111]); // "hello"
      deviceDataController.add(data);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received[0], data);
    });

    test('forwards data from peripheral service', () async {
      final received = <Uint8List>[];
      provider.dataStream.listen((d) => received.add(d));

      final data = Uint8List.fromList([119, 111, 114, 108, 100]); // "world"
      peripheralDataController.add(data);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received[0], data);
    });

    test('routes non-handshake data to stream', () async {
      final received = <Uint8List>[];
      provider.dataStream.listen((d) => received.add(d));

      // Handshake data should NOT be forwarded
      final handshakeData = Uint8List.fromList(
        '{"type":"connection_request","name":"Test"}'.codeUnits,
      );
      deviceDataController.add(handshakeData);
      await Future.delayed(Duration.zero);

      // Handshake data is not forwarded to the public stream
      expect(received, isEmpty);
    });
  });

  group('sendMessage', () {
    test('sends via device service first', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      final result = await provider.sendMessage(data);
      expect(result, true);
      verify(() => mockDeviceService.sendData(data)).called(1);
    });

    test('falls back to peripheral when device fails', () async {
      when(() => mockDeviceService.sendData(any())).thenAnswer((_) async => false);
      final data = Uint8List.fromList([1, 2, 3]);
      final result = await provider.sendMessage(data);
      expect(result, true);
      verify(() => mockDeviceService.sendData(data)).called(1);
      verify(() => mockPeripheralService.sendNotification(data)).called(1);
    });

    test('returns false when both send fail', () async {
      when(() => mockDeviceService.sendData(any())).thenAnswer((_) async => false);
      when(() => mockPeripheralService.sendNotification(any())).thenAnswer((_) async => false);
      final data = Uint8List.fromList([1, 2, 3]);
      final result = await provider.sendMessage(data);
      expect(result, false);
    });
  });

  group('dispose', () {
    test('disposes all services', () {
      final p = BleProvider(
        bluetoothService: mockBtService,
        deviceService: mockDeviceService,
        peripheralService: mockPeripheralService,
      );
      p.dispose();
      verify(() => mockBtService.dispose()).called(1);
      verify(() => mockDeviceService.dispose()).called(1);
      verify(() => mockPeripheralService.dispose()).called(1);
    });
  });
}
