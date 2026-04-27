import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/message_service.dart';

class ChatProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  final List<ChatMessage> _messages = [];
  StreamSubscription? _dataSubscription;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void setDataStream(Stream<Uint8List> dataStream) {
    _dataSubscription?.cancel();
    _dataSubscription = dataStream.listen(_onDataReceived);
  }

  void _onDataReceived(Uint8List data) {
    final message = _messageService.decodeMessage(data);
    if (message != null) {
      _messages.add(message);
      notifyListeners();
    }
  }

  Future<bool> sendTextMessage(String content) async {
    if (content.trim().isEmpty) return false;

    final message = _messageService.createTextMessage(
      content: content,
      isFromMe: true,
    );

    _messages.add(message);
    notifyListeners();

    return true;
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
