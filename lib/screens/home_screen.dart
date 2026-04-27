import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';
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
                const SizedBox(height: 32),
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

  Widget _buildConnectedActions(BuildContext context, BleProvider provider) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
          icon: const Icon(Icons.chat),
          label: const Text('进入聊天'),
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
    return FilledButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        );
      },
      icon: const Icon(Icons.bluetooth_searching),
      label: const Text('扫描设备'),
    );
  }
}
