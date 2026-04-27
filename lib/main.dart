import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/ble_provider.dart';
import 'providers/device_list_provider.dart';
import 'providers/chat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => DeviceListProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const OffChatApp(),
    ),
  );
}
