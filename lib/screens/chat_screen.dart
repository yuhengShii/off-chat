import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ble_connection_state.dart';
import '../models/chat_message.dart';
import '../providers/ble_provider.dart';
import '../providers/chat_provider.dart';
import '../services/message_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = context.read<BleProvider>();
      context.read<ChatProvider>()
        ..setChatActive(true)
        ..setDataStream(bleProvider.dataStream);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 100.0;
    _isNearBottom = _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <=
        threshold;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  Future<void> _sendMessage(String content) async {
    final chatProvider = context.read<ChatProvider>();
    final bleProvider = context.read<BleProvider>();

    final sent = await chatProvider.sendTextMessage(content);
    if (sent) {
      _scrollToBottom();
      final messages = chatProvider.messages;
      if (messages.isNotEmpty) {
        final lastMsg = messages.last;
        final encoded = _messageService.encodeMessage(lastMsg);
        final delivered = await bleProvider.sendMessage(encoded);
        chatProvider.updateMessageStatus(lastMsg.id, delivered ? MessageStatus.delivered : MessageStatus.failed);
      }
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

                if (_isNearBottom && messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(animated: false);
                  });
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
