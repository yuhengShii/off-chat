import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isFromMe = message.isFromMe;
    final timeFormat = DateFormat('HH:mm');

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromMe ? Colors.blue.shade500 : Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isFromMe ? const Radius.circular(4) : null,
            bottomLeft: !isFromMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isFromMe ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeFormat.format(message.timestamp),
                  style: TextStyle(
                    color: isFromMe ? Colors.white60 : Colors.black45,
                    fontSize: 11,
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 6),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 14, color: Colors.white60);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white60);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white60);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: Colors.red.shade300);
    }
  }
}
