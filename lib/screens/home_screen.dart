import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
import '../providers/chat_provider.dart';
import '../models/ble_connection_state.dart';
import 'scan_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OffChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BleProvider>(
        builder: (context, bleProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildConnectionStatus(bleProvider),
                const SizedBox(height: 24),
                _buildDeviceName(context, bleProvider),
                const SizedBox(height: 16),
                if (bleProvider.isConnected)
                  _buildConnectedActions(context, bleProvider)
                else
                  _buildDisconnectedActions(context, bleProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BleProvider provider) {
    final state = provider.connectionState;
    final device = provider.connectedDevice;

    IconData icon = Icons.bluetooth_disabled;
    Color color = Colors.grey;
    String text = '未连接';

    switch (state) {
      case BleConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        text = '已连接: ${device?.name ?? "未知设备"}';
      case BleConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.orange;
        text = '连接中...';
      case BleConnectionState.disconnecting:
        icon = Icons.bluetooth_disabled;
        color = Colors.orange;
        text = '断开中...';
      case BleConnectionState.disconnected:
        icon = Icons.bluetooth_disabled;
        color = Colors.grey;
        text = '未连接';
    }

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(text, style: TextStyle(fontSize: 18, color: color)),
      ],
    );
  }

  Widget _buildDeviceName(BuildContext context, BleProvider provider) {
    return GestureDetector(
      onTap: () => _showEditDeviceNameDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              provider.deviceName,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showEditDeviceNameDialog(BuildContext context, BleProvider provider) {
    final controller = TextEditingController(text: provider.deviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改设备名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入设备名',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.setDeviceName(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  Widget _buildConnectedActions(BuildContext context, BleProvider provider) {
    return Column(
      children: [
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Badge(
              isLabelVisible: chatProvider.unreadCount > 0,
              label: Text('${chatProvider.unreadCount}'),
              child: FilledButton.icon(
                onPressed: () {
                  chatProvider.setChatActive(true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ).then((_) {
                    chatProvider.setChatActive(false);
                  });
                },
                icon: const Icon(Icons.chat),
                label: const Text('进入聊天'),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => provider.disconnect(),
          icon: const Icon(Icons.bluetooth_disabled),
          label: const Text('断开连接'),
        ),
      ],
    );
  }

  Widget _buildDisconnectedActions(BuildContext context, BleProvider provider) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            );
          },
          icon: const Icon(Icons.bluetooth_searching),
          label: const Text('扫描设备'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            if (provider.isAdvertising) {
              provider.stopAdvertising();
            } else {
              provider.startAdvertising();
            }
          },
          icon: Icon(provider.isAdvertising ? Icons.visibility_off : Icons.visibility),
          label: Text(provider.isAdvertising ? '停止可见' : '设为可见'),
        ),
      ],
    );
  }
}
