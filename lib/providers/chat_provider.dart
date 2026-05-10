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
  String? _currentOrganizacionId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isSocketConnected => _isSocketConnected;
  String? get error => _error;

  Future<void> initChat({
    required String organizacionId,
    required String usuarioId,
    String? accessToken,
  }) async {
    _currentOrganizacionId = organizacionId;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final loadedMessages = await _chatService.obtenerMensajesPorOrganizacion(
        organizacionId: organizacionId,
        accessToken: accessToken,
      );

      _messages
        ..clear()
        ..addAll(loadedMessages);

      _connectSocket(
        organizacionId: organizacionId,
        accessToken: accessToken,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _connectSocket({
    required String organizacionId,
    String? accessToken,
  }) {
    _socketService.connect(
      accessToken: accessToken,
      onConnect: () {
        _isSocketConnected = true;
        _socketService.joinOrganizacion(organizacionId);
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
      final isSameOrganization = message.organizacion == _currentOrganizacionId;
      final alreadyExists = _messages.any((item) => item.id == message.id);

      if (isSameOrganization && !alreadyExists) {
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

    if (cleanContent.isEmpty) {
      return;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      if (_socketService.isConnected) {
        _socketService.sendMessage(
          contenido: cleanContent,
          usuario: usuario,
          organizacion: organizacion,
        );
      } else {
        final created = await _chatService.crearMensaje(
          contenido: cleanContent,
          usuario: usuario,
          organizacion: organizacion,
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
    try {
      final updated = await _chatService.marcarMensajeComoLeido(
        mensajeId: mensajeId,
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
    _socketService.emitTyping(
      usuario: usuario,
      organizacion: organizacion,
    );
  }

  void closeChat() {
    if (_currentOrganizacionId != null) {
      _socketService.leaveOrganizacion(_currentOrganizacionId!);
    }

    _currentOrganizacionId = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}