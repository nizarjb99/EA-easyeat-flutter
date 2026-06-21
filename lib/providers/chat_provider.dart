// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();

  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isSending = false;
  bool _isSocketConnected = false;
  String? _error;
  String? _currentConversationId;
  String? _currentUsuarioId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isSocketConnected => _isSocketConnected;
  String? get error => _error;
  String? get currentConversationId => _currentConversationId;

  Future<void> initChat({
    required String organizacionId,
    required String usuarioId,
    String? accessToken,
  }) async {
    _currentUsuarioId = usuarioId;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final conv = await _chatService.crearOObtenerConversacion(
        customerId: usuarioId,
        restaurantId: organizacionId,
        accessToken: accessToken,
      );

      final conversationId = conv['_id']?.toString() ?? conv['id']?.toString() ?? '';
      _currentConversationId = conversationId;

      final loadedMessages = await _chatService.obtenerMensajesPorConversacion(
        conversationId: conversationId,
        accessToken: accessToken,
      );

      _messages
        ..clear()
        ..addAll(loadedMessages);

      _connectSocket(
        conversationId: conversationId,
        usuarioId: usuarioId,
        accessToken: accessToken,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _connectSocket({
    required String conversationId,
    required String usuarioId,
    String? accessToken,
  }) {
    _socketService.connect(
      accessToken: accessToken,
      onConnect: () {
        _isSocketConnected = true;
        _error = null; // Clear connection errors upon successful connection
        _socketService.joinConversation(conversationId);
        _socketService.joinCustomer(usuarioId);
        notifyListeners();
      },
      onDisconnect: () {
        _isSocketConnected = false;
        notifyListeners();
      },
      onError: (message) {
        _error = message;
        notifyListeners();
      },
    );

    _socketService.onNewMessage((message) {
      final isSameConversation = message.conversation == _currentConversationId;
      final alreadyExists = _messages.any((item) => item.id == message.id);

      if (isSameConversation && !alreadyExists) {
        _messages.add(message);
        _messages.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
        notifyListeners();
      }
    });
  }

  Future<void> sendMessage({
    required String contenido,
    required String usuario,
    required String organizacion,
    String? accessToken,
  }) async {
    final cleanContent = contenido.trim();

    if (cleanContent.isEmpty || _currentConversationId == null) {
      return;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      if (_socketService.isConnected) {
        _socketService.sendMessage(
          conversationId: _currentConversationId!,
          senderId: usuario,
          senderRole: 'customer',
          contenido: cleanContent,
        );
      } else {
        final created = await _chatService.crearMensaje(
          conversationId: _currentConversationId!,
          senderId: usuario,
          senderRole: 'customer',
          contenido: cleanContent,
          accessToken: accessToken,
        );

        _messages.add(created);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isSending = false;
    notifyListeners();
  }

  Future<void> markMessageAsRead({
    required String mensajeId,
    String? accessToken,
  }) async {
    if (_currentUsuarioId == null) return;
    try {
      final updated = await _chatService.marcarMensajeComoLeido(
        mensajeId: mensajeId,
        usuarioId: _currentUsuarioId!,
        accessToken: accessToken,
      );

      final index = _messages.indexWhere((item) => item.id == mensajeId);

      if (index != -1) {
        _messages[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void emitTyping({
    required String usuario,
    required String organizacion,
  }) {
    if (_currentConversationId != null) {
      _socketService.emitTyping(
        conversationId: _currentConversationId!,
        senderId: usuario,
        senderRole: 'customer',
      );
    }
  }

  void closeChat() {
    if (_currentConversationId != null) {
      _socketService.leaveConversation(_currentConversationId!);
    }

    _currentConversationId = null;
    _currentUsuarioId = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}