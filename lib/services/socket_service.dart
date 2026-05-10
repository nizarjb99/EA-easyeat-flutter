// lib/services/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_message.dart';

class SocketService {
  static const String _socketUrl = 'http://localhost:3000';

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
          .setTransports(['websocket'])
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

  void joinOrganizacion(String organizacionId) {
    _socket?.emit('chat:joinOrganization', {
      'organizacionId': organizacionId,
    });
  }

  void leaveOrganizacion(String organizacionId) {
    _socket?.emit('chat:leaveOrganization', {
      'organizacionId': organizacionId,
    });
  }

  void sendMessage({
    required String contenido,
    required String usuario,
    required String organizacion,
  }) {
    _socket?.emit('chat:sendMessage', {
      'contenido': contenido,
      'usuario': usuario,
      'organizacion': organizacion,
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

  void onTyping(void Function(String usuarioId) callback) {
    _socket?.off('chat:typing');

    _socket?.on('chat:typing', (data) {
      if (data is Map && data['usuario'] != null) {
        callback(data['usuario'].toString());
      }
    });
  }

  void emitTyping({
    required String usuario,
    required String organizacion,
  }) {
    _socket?.emit('chat:typing', {
      'usuario': usuario,
      'organizacion': organizacion,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}