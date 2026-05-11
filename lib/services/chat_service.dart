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

  Future<ChatMessage> crearMensaje({
    required String contenido,
    required String usuario,
    required String organizacion,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat');

    final response = await http.post(
      uri,
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({
        'contenido': contenido,
        'usuario': usuario,
        'organizacion': organizacion,
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

  Future<List<ChatMessage>> obtenerMensajesPorOrganizacion({
    required String organizacionId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/organizacion/$organizacionId');

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

  Future<List<ChatMessage>> obtenerMensajesNoLeidos({
    required String usuarioId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/no-leidos/$usuarioId');

    final response = await http.get(
      uri,
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener mensajes no leídos: ${response.body}');
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
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/$mensajeId/leido');

    final response = await http.patch(
      uri,
      headers: _headers(accessToken: accessToken),
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

  Future<void> eliminarMensaje({
    required String mensajeId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/$mensajeId');

    final response = await http.delete(
      uri,
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar mensaje: ${response.body}');
    }
  }
}