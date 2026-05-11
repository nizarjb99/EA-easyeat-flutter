// lib/models/chat_message.dart

class ChatMessage {
  final String id;
  final String contenido;
  final String usuario;
  final String organizacion;
  final bool leido;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatMessage({
    required this.id,
    required this.contenido,
    required this.usuario,
    required this.organizacion,
    required this.leido,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic value) {
      if (value == null) return '';

      if (value is String) return value;

      if (value is Map<String, dynamic>) {
        return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      }

      return value.toString();
    }

    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      usuario: extractId(json['usuario']),
      organizacion: extractId(json['organizacion']),
      leido: json['leido'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'contenido': contenido,
      'usuario': usuario,
      'organizacion': organizacion,
      'leido': leido,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}