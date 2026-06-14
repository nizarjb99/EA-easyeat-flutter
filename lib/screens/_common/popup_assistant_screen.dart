import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/llm.dart';
import '../../providers/auth_provider.dart';
import '../../services/llm_service.dart';

class PopupAssistantScreen extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const PopupAssistantScreen({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<PopupAssistantScreen> createState() => _PopupAssistantScreenState();
}

class _LocalMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  _LocalMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class _PopupAssistantScreenState extends State<PopupAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_LocalMessage> _messages = [];
  final LlmService _llmService = LlmService();

  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  bool get _canUseState => !_isDisposed && mounted;

  void _safeSetState(VoidCallback fn) {
    if (!_canUseState) return;
    setState(fn);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearChat() {
    _safeSetState(() {
      _messages.clear();
      _error = null;
    });
  }

  void _scrollToBottomDelayed() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_canUseState) return;
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    final userMessage = _LocalMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    _safeSetState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _error = null;
    });
    _scrollToBottomDelayed();

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.accessToken ?? '';

      final response = await _llmService.askAssistant(text, token);

      final assistantMessage = _LocalMessage(
        id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: response.response,
        timestamp: DateTime.now(),
      );

      _safeSetState(() {
        _messages.add(assistantMessage);
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'assistant.error'.tr();
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
      _scrollToBottomDelayed();
    }
  }

  void _applySuggestion(String suggestion) {
    _safeSetState(() {
      _messageController.text = suggestion;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFFF7A1A);
    const Color dark = Color(0xFF0F172A);
    const Color grey = Color(0xFF64748B);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.74,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE9D9),
                  child: Icon(Icons.smart_toy_rounded, color: orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'assistant.title'.tr(),
                        style: const TextStyle(
                          color: dark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'assistant.subtitle'.tr(),
                        style: const TextStyle(
                          color: orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'assistant.notes1'.tr()} · ${'assistant.notes2'.tr()}',
                        style: const TextStyle(
                          color: grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_messages.isNotEmpty)
                  IconButton(
                    onPressed: _clearChat,
                    tooltip: 'assistant.clear'.tr(),
                    icon: const Icon(Icons.rotate_left_rounded, color: grey),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: _messages.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : _buildMessagesList(orange, dark, grey),
            ),

            const SizedBox(height: 8),

            // Message Input Area
            _buildMessageInput(orange),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    const Color orange = Color(0xFFFF7A1A);
    const Color dark = Color(0xFF0F172A);
    const Color grey = Color(0xFF64748B);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'assistant.empty_title'.tr(),
                style: TextStyle(
                  color: dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'assistant.empty_desc'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ..._buildSuggestions(orange, dark, grey),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSuggestions(Color orange, Color dark, Color grey) {
    final suggestions = [
      'assistant.suggestion_1'.tr(),
      'assistant.suggestion_2'.tr(),
      'assistant.suggestion_3'.tr(),
    ];

    return suggestions.map((suggestion) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton(
          onPressed: () => _applySuggestion(suggestion),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFFE9D9), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: Colors.white,
          ),
          child: Text(
            suggestion,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMessagesList(Color orange, Color dark, Color grey) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingBubble();
        }

        final message = _messages[index];
        final isUser = message.role == 'user';

        return _buildMessageBubble(message, isUser);
      },
    );
  }

  Widget _buildLoadingBubble() {
    const Color orange = Color(0xFFFF7A1A);
    const Color dark = Color(0xFF0F172A);
    const Color grey = Color(0xFF64748B);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 6),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFFFFE9D9),
              child: Icon(Icons.smart_toy_rounded, color: orange, size: 12),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(orange),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'assistant.thinking'.tr(),
                  style: TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_LocalMessage message, bool isUser) {
    const Color orange = Color(0xFFFF7A1A);
    const Color dark = Color(0xFF0F172A);
    const Color grey = Color(0xFF64748B);

    final timeStr =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 6),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFFFE9D9),
                child: Icon(Icons.smart_toy_rounded, color: orange, size: 12),
              ),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? orange : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUser)
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      color: isUser ? Colors.white70 : grey,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Color orange) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            focusNode: _focusNode,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'assistant.placeholder'.tr(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(Icons.send_rounded),
          ),
        ),
      ],
    );
  }
}
