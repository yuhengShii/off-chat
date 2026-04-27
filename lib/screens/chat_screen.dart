import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ble_connection_state.dart';
import '../providers/ble_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = context.read<BleProvider>();
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setDataStream(bleProvider.dataStream);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String content) async {
    final chatProvider = context.read<ChatProvider>();
    final bleProvider = context.read<BleProvider>();

    final sent = await chatProvider.sendTextMessage(content);
    if (sent) {
      _scrollToBottom();
      await bleProvider.sendMessage(content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<BleProvider>(
          builder: (context, provider, child) {
            return Text(provider.connectedDevice?.name ?? '聊天');
          },
        ),
      ),
      body: Column(
        children: [
          Consumer<BleProvider>(
            builder: (context, provider, child) {
              if (!provider.isConnected && provider.connectionState != BleConnectionState.connecting) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '连接已断开',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('返回'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('开始聊天吧'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          MessageInput(onSend: _sendMessage),
        ],
      ),
    );
  }
}
