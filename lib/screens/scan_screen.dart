import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../providers/device_list_provider.dart';
import '../models/device_info.dart';
import 'chat_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    final deviceListProvider = context.read<DeviceListProvider>();
    final bleProvider = context.read<BleProvider>();
    await deviceListProvider.startScan();
    await bleProvider.startScan();
  }

  Future<void> _stopScan() async {
    final deviceListProvider = context.read<DeviceListProvider>();
    final bleProvider = context.read<BleProvider>();
    await deviceListProvider.stopScan();
    await bleProvider.stopScan();
  }

  Future<void> _connectToDevice(DeviceInfo device) async {
    final bleProvider = context.read<BleProvider>();
    await _stopScan();
    final success = await bleProvider.connectToDevice(device);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描设备'),
        actions: [
          Consumer<DeviceListProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(provider.isScanning ? Icons.stop : Icons.refresh),
                onPressed: () {
                  if (provider.isScanning) {
                    _stopScan();
                  } else {
                    _startScan();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<DeviceListProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _startScan,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.isScanning && provider.devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在扫描...'),
                ],
              ),
            );
          }

          if (provider.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('未发现设备'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _startScan,
                    child: const Text('重新扫描'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _startScan,
            child: ListView.builder(
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return _DeviceTile(
                  device: device,
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, size: 32),
        title: Text(device.name),
        subtitle: Text('信号: ${device.rssi} dBm'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
