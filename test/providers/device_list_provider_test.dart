import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:off_chat/models/device_info.dart';
import 'package:off_chat/providers/device_list_provider.dart';
import 'package:off_chat/services/bluetooth_service.dart';

class MockBluetoothService extends Mock implements BluetoothService {}

void main() {
  late MockBluetoothService mockService;
  late StreamController<List<DeviceInfo>> scanController;
  late DeviceListProvider provider;

  setUp(() {
    mockService = MockBluetoothService();
    scanController = StreamController<List<DeviceInfo>>.broadcast();

    when(() => mockService.scanResults).thenAnswer((_) => scanController.stream);
    when(() => mockService.isScanning).thenReturn(false);
    when(() => mockService.startScan()).thenAnswer((_) async => true);
    when(() => mockService.stopScan()).thenAnswer((_) async {});
    when(() => mockService.dispose()).thenAnswer((_) async {});

    provider = DeviceListProvider(bluetoothService: mockService);
  });

  tearDown(() {
    provider.dispose();
    scanController.close();
  });

  group('initial state', () {
    test('devices list is empty', () {
      expect(provider.devices, isEmpty);
    });

    test('errorMessage is null', () {
      expect(provider.errorMessage, isNull);
    });

    test('isScanning returns service value', () {
      expect(provider.isScanning, false);
    });
  });

  group('scan results', () {
    test('receives devices from scan stream', () async {
      final devices = [
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
        const DeviceInfo(id: '2', name: 'Device B', rssi: -60),
      ];

      scanController.add(devices);
      await Future.delayed(Duration.zero);

      expect(provider.devices.length, 2);
      expect(provider.devices[0].name, 'Device A');
      expect(provider.devices[1].name, 'Device B');
    });

    test('updates when scan stream emits new list', () async {
      scanController.add([
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
      ]);
      await Future.delayed(Duration.zero);
      expect(provider.devices.length, 1);

      scanController.add([
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
        const DeviceInfo(id: '2', name: 'Device B', rssi: -60),
      ]);
      await Future.delayed(Duration.zero);
      expect(provider.devices.length, 2);
    });

    test('empty scan list clears devices', () async {
      scanController.add([
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
      ]);
      await Future.delayed(Duration.zero);
      expect(provider.devices.length, 1);

      scanController.add([]);
      await Future.delayed(Duration.zero);
      expect(provider.devices, isEmpty);
    });
  });

  group('startScan', () {
    test('calls service startScan', () async {
      await provider.startScan();

      verify(() => mockService.startScan()).called(1);
    });

    test('does not set error when scan succeeds', () async {
      await provider.startScan();

      expect(provider.errorMessage, isNull);
    });

    test('sets error when scan fails', () async {
      when(() => mockService.startScan()).thenAnswer((_) async => false);

      await provider.startScan();

      expect(provider.errorMessage, isNotNull);
    });

    test('clears devices before starting scan', () async {
      scanController.add([
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
      ]);
      await Future.delayed(Duration.zero);
      expect(provider.devices, isNotEmpty);

      await provider.startScan();

      // startScan clears devices before calling service
      expect(provider.devices, isEmpty);
    });
  });

  group('stopScan', () {
    test('calls service stopScan', () async {
      await provider.stopScan();

      verify(() => mockService.stopScan()).called(1);
    });

    test('multiple stopScan calls are safe', () async {
      await provider.stopScan();
      await provider.stopScan();

      verify(() => mockService.stopScan()).called(2);
    });
  });

  group('clearDevices', () {
    test('clears device list', () async {
      scanController.add([
        const DeviceInfo(id: '1', name: 'Device A', rssi: -50),
      ]);
      await Future.delayed(Duration.zero);
      expect(provider.devices, isNotEmpty);

      provider.clearDevices();

      expect(provider.devices, isEmpty);
    });
  });

  group('isScanning', () {
    test('reflects service scanning state', () {
      when(() => mockService.isScanning).thenReturn(true);
      expect(provider.isScanning, true);

      when(() => mockService.isScanning).thenReturn(false);
      expect(provider.isScanning, false);
    });
  });

  group('dispose', () {
    test('calls service dispose', () {
      final p = DeviceListProvider(bluetoothService: mockService);
      p.dispose();

      verify(() => mockService.dispose()).called(1);
    });

    test('multiple dispose calls throw', () {
      final p = DeviceListProvider(bluetoothService: mockService);
      p.dispose();
      expect(() => p.dispose(), throwsA(isA<FlutterError>()));
    });
  });
}
