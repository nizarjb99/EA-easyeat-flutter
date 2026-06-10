// lib/services/chat_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/chat_message.dart';

class ChatService {
  static const String _baseUrl = AppConstants.baseUrl;

  Map<String, String> _headers({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Future<Map<String, dynamic>> crearOObtenerConversacion({
    required String customerId,
    required String restaurantId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/conversations');

    final response = await http.post(
      uri,
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({
        'customerId': customerId,
        'restaurantId': restaurantId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al obtener o crear conversación: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> && decoded['data'] != null
        ? decoded['data']
        : decoded;

    return data as Map<String, dynamic>;
  }

  Future<ChatMessage> crearMensaje({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String contenido,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.post(
      uri,
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({
        'senderId': senderId,
        'senderRole': senderRole,
        'contenido': contenido,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear mensaje: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final data = decoded is Map<String, dynamic> && decoded['data'] != null
        ? decoded['data']
        : decoded;

    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> obtenerMensajesPorConversacion({
    required String conversationId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.get(
      uri,
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener mensajes: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final rawList = decoded is Map<String, dynamic> && decoded['data'] != null
        ? decoded['data']
        : decoded;

    if (rawList is! List) {
      return [];
    }

    return rawList
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> marcarMensajeComoLeido({
    required String mensajeId,
    required String usuarioId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/messages/$mensajeId/read');

    final response = await http.patch(
      uri,
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({
        'userId': usuarioId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al marcar mensaje como leído: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final data = decoded is Map<String, dynamic> && decoded['data'] != null
        ? decoded['data']
        : decoded;

    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<void> marcarConversacionComoLeida({
    required String conversationId,
    required String usuarioId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/conversations/$conversationId/read');

    final response = await http.patch(
      uri,
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({
        'userId': usuarioId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al marcar conversación como leída: ${response.body}');
    }
  }

  Future<void> eliminarMensaje({
    required String mensajeId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/messages/$mensajeId');

    final response = await http.delete(
      uri,
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar mensaje: ${response.body}');
    }
  }
}