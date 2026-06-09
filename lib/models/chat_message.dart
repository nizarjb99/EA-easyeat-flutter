// lib/models/chat_message.dart

class ChatMessage {
  final String id;
  final String conversation;
  final String customer;
  final String restaurant;
  final String sender;
  final String senderRole;
  final String contenido;
  final List<String> readBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Compatibility getters for existing UI
  String get usuario => sender;
  String get organizacion => restaurant;
  bool get leido => readBy.length > 1;

  ChatMessage({
    required this.id,
    required this.conversation,
    required this.customer,
    required this.restaurant,
    required this.sender,
    required this.senderRole,
    required this.contenido,
    required this.readBy,
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

    final readByList = json['readBy'] as List?;
    final readBy = readByList?.map((e) => extractId(e)).toList() ?? [];

    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      conversation: extractId(json['conversation']),
      customer: extractId(json['customer']),
      restaurant: extractId(json['restaurant'] ?? json['organizacion']),
      sender: extractId(json['sender'] ?? json['usuario']),
      senderRole: json['senderRole']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      readBy: List<String>.from(readBy),
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
      'conversation': conversation,
      'customer': customer,
      'restaurant': restaurant,
      'sender': sender,
      'senderRole': senderRole,
      'contenido': contenido,
      'readBy': readBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}