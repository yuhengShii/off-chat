import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../providers/device_list_provider.dart';
import '../models/device_info.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isActionInProgress = false;
  DeviceListProvider? _deviceListProvider;

  @override
  void initState() {
    super.initState();
    _deviceListProvider = context.read<DeviceListProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _deviceListProvider?.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;

    await _deviceListProvider?.startScan();

    _isActionInProgress = false;
  }

  Future<void> _stopScan() async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;

    await _deviceListProvider?.stopScan();

    _isActionInProgress = false;
  }

  Future<void> _connectToDevice(DeviceInfo device) async {
    final bleProvider = context.read<BleProvider>();
    await _stopScan();
    await bleProvider.initiateHandshake(device);
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = context.watch<BleProvider>();

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
      body: Stack(
        children: [
          bleProvider.handshakePhase == HandshakePhase.waiting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('等待对方确认...'),
                      SizedBox(height: 8),
                      Text('对方将收到连接请求', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : Consumer<DeviceListProvider>(
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
                            const Text('未发现附近设备'),
                            const SizedBox(height: 8),
                            const Text('请确保对方已开启蓝牙并设为可见', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _debugLogView(bleProvider),
          ),
        ],
      ),
    );
  }

  Widget _debugLogView(BleProvider bleProvider) {
    final log = bleProvider.debugLog;
    if (log.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showFullLog(bleProvider),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('DEBUG', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.open_in_full, size: 12, color: Colors.grey.shade500),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  log,
                  style: const TextStyle(fontSize: 9, color: Colors.green, fontFamily: 'monospace', height: 1.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullLog(BleProvider bleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('DEBUG LOG', style: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  bleProvider.debugLog,
                  style: const TextStyle(fontSize: 10, color: Colors.green, fontFamily: 'monospace', height: 1.4),
                ),
              ),
            ),
          ],
        ),
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
