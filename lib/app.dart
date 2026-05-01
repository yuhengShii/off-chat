import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/ble_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';

class OffChatApp extends StatefulWidget {
  const OffChatApp({super.key});

  @override
  State<OffChatApp> createState() => _OffChatAppState();
}

class _OffChatAppState extends State<OffChatApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OffChat',
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _HandshakeHandler(
          navigatorKey: _navigatorKey,
          child: child!,
        );
      },
    );
  }
}

/// 全局握手处理器 — 在任何界面收到连接请求时弹出对话框
class _HandshakeHandler extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _HandshakeHandler({
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<_HandshakeHandler> createState() => _HandshakeHandlerState();
}

class _HandshakeHandlerState extends State<_HandshakeHandler> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<BleProvider>(
      builder: (context, bleProvider, _) {
        switch (bleProvider.handshakePhase) {
          case HandshakePhase.incoming:
            if (!_dialogShown) {
              _dialogShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showIncomingDialog(bleProvider);
              });
            }
          case HandshakePhase.accepted:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                bleProvider.resetHandshake();
                _navigateToChat();
              }
            });
          case HandshakePhase.rejected:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                bleProvider.resetHandshake();
                _showRejectedSnackBar();
              }
            });
          default:
            break;
        }
        return widget.child;
      },
    );
  }

  void _showIncomingDialog(BleProvider bleProvider) {
    final navState = widget.navigatorKey.currentState;
    if (navState == null) return;

    showDialog(
      context: navState.overlay!.context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('连接请求'),
        content: Text('${bleProvider.pendingRequestFrom ?? "对方"} 请求与你连接'),
        actions: [
          TextButton(
            onPressed: () {
              _dialogShown = false;
              bleProvider.rejectHandshake();
              Navigator.of(ctx).pop();
            },
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () {
              _dialogShown = false;
              bleProvider.acceptHandshake();
              Navigator.of(ctx).pop();
            },
            child: const Text('接受'),
          ),
        ],
      ),
    ).then((_) {
      _dialogShown = false;
    });
  }

  void _navigateToChat() {
    context.read<ChatProvider>().clearMessages();
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _showRejectedSnackBar() {
    final navState = widget.navigatorKey.currentState;
    if (navState == null) return;
    ScaffoldMessenger.of(navState.overlay!.context).showSnackBar(
      const SnackBar(
        content: Text('对方拒绝了连接'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
