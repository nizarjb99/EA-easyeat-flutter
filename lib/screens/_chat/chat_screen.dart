// lib/screens/_common/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

const Color _orange = Color(0xFFFF7A1A);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class ChatScreen extends StatefulWidget {
  final Restaurant restaurant;

  const ChatScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _restaurantId => widget.restaurant.id;
  String get _restaurantName => widget.restaurant.profile.name;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();

      final customerId = auth.currentCustomer?.id;
      final token = auth.accessToken;

      if (customerId == null || customerId.isEmpty) {
        return;
      }

      chat.initChat(
        organizacionId: _restaurantId,
        usuarioId: customerId,
        accessToken: token,
      );
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().closeChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    final customerId = auth.currentCustomer?.id;
    final token = auth.accessToken;
    final text = _messageController.text.trim();

    if (customerId == null || customerId.isEmpty || text.isEmpty) {
      return;
    }

    chat.sendMessage(
      contenido: text,
      usuario: customerId,
      organizacion: _restaurantId,
      accessToken: token,
    );

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final currentUserId = auth.currentCustomer?.id ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _dark),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _orange.withValues(alpha: 0.12),
              child: const Icon(Icons.restaurant, color: _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _restaurantName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Icon(
                chat.isSocketConnected ? Icons.circle : Icons.circle_outlined,
                color: chat.isSocketConnected ? Colors.green : Colors.grey,
                size: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.08),
              child: Text(
                chat.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(18),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final message = chat.messages[index];
                          final isMine = message.usuario == currentUserId;

                          return _MessageBubble(
                            text: message.contenido,
                            isMine: isMine,
                            createdAt: message.createdAt,
                            leido: message.leido,
                          );
                        },
                      ),
          ),

          _MessageInput(
            controller: _messageController,
            isSending: chat.isSending,
            onSend: _sendMessage,
            onChanged: (_) {
              if (currentUserId.isNotEmpty) {
                context.read<ChatProvider>().emitTyping(
                      usuario: currentUserId,
                      organizacion: _restaurantId,
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: _grey),
            SizedBox(height: 12),
            Text(
              'Todavía no hay mensajes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Escribe el primer mensaje para contactar con el restaurante.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final bool leido;
  final DateTime? createdAt;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.leido,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final backgroundColor = isMine ? _orange : Colors.white;
    final textColor = isMine ? Colors.white : _dark;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 6, right: 6),
          child: Text(
            _formatTime(createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: _grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime? date) {
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: isSending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}