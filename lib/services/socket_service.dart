// lib/services/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_message.dart';
import '../utils/constants.dart';

class SocketService {
  static const String _socketUrl = AppConstants.baseUrl;

  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  void connect({
    String? accessToken,
    required void Function() onConnect,
    required void Function() onDisconnect,
    required void Function(String message) onError,
  }) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({
            if (accessToken != null && accessToken.isNotEmpty)
              'token': accessToken,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      onConnect();
    });

    _socket!.onDisconnect((_) {
      onDisconnect();
    });

    _socket!.onConnectError((error) {
      onError(error.toString());
    });

    _socket!.onError((error) {
      onError(error.toString());
    });

    _socket!.connect();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('chat:joinConversation', {
      'conversationId': conversationId,
    });
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('chat:leaveConversation', {
      'conversationId': conversationId,
    });
  }

  void joinCustomer(String customerId) {
    _socket?.emit('chat:joinCustomer', {
      'customerId': customerId,
    });
  }

  void joinRestaurant(String restaurantId) {
    _socket?.emit('chat:joinRestaurant', {
      'restaurantId': restaurantId,
    });
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String contenido,
  }) {
    _socket?.emit('chat:sendMessage', {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'contenido': contenido,
    });
  }

  void onNewMessage(void Function(ChatMessage message) callback) {
    _socket?.off('chat:newMessage');

    _socket?.on('chat:newMessage', (data) {
      if (data is Map) {
        final parsed = Map<String, dynamic>.from(data);
        callback(ChatMessage.fromJson(parsed));
      }
    });
  }

  void onTyping(void Function(String senderId) callback) {
    _socket?.off('chat:typing');

    _socket?.on('chat:typing', (data) {
      if (data is Map && data['senderId'] != null) {
        callback(data['senderId'].toString());
      }
    });
  }

  void emitTyping({
    required String conversationId,
    required String senderId,
    required String senderRole,
  }) {
    _socket?.emit('chat:typing', {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}