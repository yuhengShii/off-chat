import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/models/device_info.dart';

void main() {
  group('DeviceInfo', () {
    const baseDevice = DeviceInfo(
      id: 'aa:bb:cc:dd:ee:ff',
      name: 'Test Phone',
      rssi: -50,
    );

    test('creates with default isConnected', () {
      expect(baseDevice.isConnected, false);
    });

    test('creates with isConnected=true', () {
      const device = DeviceInfo(
        id: '11:22:33:44:55:66',
        name: 'Connected Device',
        rssi: -60,
        isConnected: true,
      );

      expect(device.isConnected, true);
    });

    test('copyWith updates isConnected', () {
      final updated = baseDevice.copyWith(isConnected: true);

      expect(updated.isConnected, true);
      expect(updated.id, baseDevice.id);
      expect(updated.name, baseDevice.name);
      expect(updated.rssi, baseDevice.rssi);
    });

    test('copyWith updates all fields', () {
      final updated = baseDevice.copyWith(
        id: 'new:id',
        name: 'New Name',
        rssi: -80,
        isConnected: true,
      );

      expect(updated.id, 'new:id');
      expect(updated.name, 'New Name');
      expect(updated.rssi, -80);
      expect(updated.isConnected, true);
    });

    test('copyWith with no args returns equal device', () {
      final copied = baseDevice.copyWith();

      expect(copied.id, baseDevice.id);
      expect(copied.name, baseDevice.name);
      expect(copied.rssi, baseDevice.rssi);
      expect(copied.isConnected, baseDevice.isConnected);
    });

    group('equality', () {
      test('equal when same id', () {
        const same = DeviceInfo(id: 'aa:bb:cc:dd:ee:ff', name: 'Different Name', rssi: -99);

        expect(baseDevice == same, true);
        expect(baseDevice.hashCode, same.hashCode);
      });

      test('not equal when different id', () {
        const different = DeviceInfo(id: 'xx:yy:zz:11:22:33', name: 'Test Phone', rssi: -50);

        expect(baseDevice == different, false);
      });
    });

    test('supports Chinese device name', () {
      const device = DeviceInfo(
        id: 'mac:address',
        name: '小米手机',
        rssi: -70,
      );

      expect(device.name, '小米手机');
    });

    test('supports empty name', () {
      const device = DeviceInfo(
        id: 'mac:addr',
        name: '',
        rssi: -40,
      );

      expect(device.name, '');
    });

    test('supports very weak signal', () {
      const device = DeviceInfo(
        id: 'far:away',
        name: 'Far Device',
        rssi: -100,
      );

      expect(device.rssi, -100);
    });

    test('supports strong signal', () {
      const device = DeviceInfo(
        id: 'close:by',
        name: 'Near Device',
        rssi: -30,
      );

      expect(device.rssi, -30);
    });
  });
}
