import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('关于蓝牙'),
            subtitle: const Text('使用 BLE 蓝牙进行近距离通信'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'OffChat',
                applicationVersion: '1.0.0',
                applicationLegalese: '基于 Flutter 的蓝牙聊天应用',
              );
            },
          ),
        ],
      ),
    );
  }
}
