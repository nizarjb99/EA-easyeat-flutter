import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

const String _apiBaseUrl = AppConstants.baseUrl;

class PopupChatScreen extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const PopupChatScreen({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<PopupChatScreen> createState() => _PopupChatScreenState();
}

class _PopupChatScreenState extends State<PopupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatConversation> _conversations = [];
  final List<_ChatMessage> _messages = [];

  io.Socket? _socket;

  bool _isLoading = false;
  bool _isSending = false;
  bool _socketConnected = false;
  bool _isDisposed = false;

  String? _error;
  String? _currentUserId;
  String? _currentRestaurantId;

  String _senderRole = 'customer';
  bool _isEmployee = false;

  _ChatConversation? _selectedConversation;

  bool get _openedFromRestaurant =>
      widget.restaurantId != null && widget.restaurantId!.isNotEmpty;

  bool get _hasSelectedConversation => _selectedConversation != null;

  bool get _canUseState => !_isDisposed && mounted;

  void _safeSetState(VoidCallback fn) {
    if (!_canUseState) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!_canUseState) return;

      final auth = context.read<AuthProvider>();

      _isEmployee = auth.isEmployee;
      _currentUserId = auth.id;

      if (auth.isEmployee) {
        _currentRestaurantId = auth.currentEmployee?.restaurantId;
        _senderRole = auth.isOwner ? 'owner' : 'employee';
      } else {
        _senderRole = 'customer';
      }

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        _safeSetState(() {
          _error = 'No s’ha pogut obtenir l’ID de l’usuari actual.';
        });
        return;
      }

      _connectSocket();

      if (_openedFromRestaurant) {
        await _openConversationFromRestaurant();
      } else {
        await _loadConversationsForCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    if (_selectedConversation != null) {
      _socket?.emit('chat:leaveConversation', {
        'conversationId': _selectedConversation!.id,
      });
    }

    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');
    _socket?.off('chat:newMessage');
    _socket?.off('chat:conversationUpdated');
    _socket?.off('chat:error');

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _connectSocket() {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;

    _socket = io.io(
      _apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({
            if (token != null && token.isNotEmpty)
              'token': token,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      if (!_canUseState) return;

      _safeSetState(() {
        _socketConnected = true;
        // Clear socket-related errors once connected
        if (_error != null &&
            (_error!.startsWith('No s’ha pogut connectar') ||
             _error!.startsWith('Error de socket:'))) {
          _error = null;
        }
      });

      if (_isEmployee) {
        if (_currentRestaurantId != null && _currentRestaurantId!.isNotEmpty) {
          _socket?.emit('chat:joinRestaurant', {
            'restaurantId': _currentRestaurantId,
          });
        }
      } else {
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          _socket?.emit('chat:joinCustomer', {
            'customerId': _currentUserId,
          });
        }
      }

      if (_selectedConversation != null) {
        _socket?.emit('chat:joinConversation', {
          'conversationId': _selectedConversation!.id,
        });
        if (!_isLoading) {
          _loadConversationMessages(_selectedConversation!.id);
        }
      } else {
        if (!_openedFromRestaurant && !_isLoading) {
          _loadConversationsForCurrentUser();
        }
      }
    });

    _socket!.onDisconnect((_) {
      if (!_canUseState) return;

      _safeSetState(() {
        _socketConnected = false;
      });
    });

    _socket!.onConnectError((error) {
      debugPrint('SOCKET CONNECT ERROR: $error');

      if (!_canUseState) return;

      _safeSetState(() {
        _socketConnected = false;
        _error =
            'No s’ha pogut connectar amb el xat en temps real. Comprova que el backend estigui encès i que API_BASE_URL sigui correcte.';
      });
    });

    _socket!.onError((error) {
      debugPrint('SOCKET ERROR: $error');

      if (!_canUseState) return;

      _safeSetState(() {
        _error = 'Error de socket: $error';
      });
    });

    _socket!.on('chat:newMessage', (data) {
      if (!_canUseState || data == null || _selectedConversation == null) {
        return;
      }

      final message = _ChatMessage.fromJson(
        Map<String, dynamic>.from(data as Map),
      );

      if (message.conversationId != _selectedConversation!.id) return;

      final alreadyExists = _messages.any((item) => item.id == message.id);
      if (alreadyExists) return;

      _safeSetState(() {
        _messages.add(message);
      });

      _scrollToBottomDelayed();
    });

    _socket!.on('chat:conversationUpdated', (_) {
      if (!_canUseState) return;

      if (!_hasSelectedConversation && !_openedFromRestaurant) {
        _loadConversationsForCurrentUser();
      }
    });

    _socket!.on('chat:error', (data) {
      if (!_canUseState) return;

      _safeSetState(() {
        _error = data.toString();
      });
    });

    _socket!.connect();
  }

  Future<void> _openConversationFromRestaurant() async {
    if (_currentUserId == null || widget.restaurantId == null) return;

    _safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversation = await _createOrGetConversation(
        customerId: _currentUserId!,
        restaurantId: widget.restaurantId!,
      );

      if (!_canUseState) return;

      _safeSetState(() {
        _selectedConversation = conversation;
      });

      _socket?.emit('chat:joinConversation', {
        'conversationId': conversation.id,
      });

      await _loadConversationMessages(conversation.id);
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversationsForCurrentUser() async {
    if (_currentUserId == null) return;

    _safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      late final Uri uri;

      if (_isEmployee) {
        if (_currentRestaurantId == null || _currentRestaurantId!.isEmpty) {
          throw Exception(
            'No s’ha pogut obtenir el restaurantId de l’empleat actual.',
          );
        }

        uri = Uri.parse(
          '$_apiBaseUrl/chat/conversations/restaurant/$_currentRestaurantId',
        );
      } else {
        uri = Uri.parse(
          '$_apiBaseUrl/chat/conversations/customer/$_currentUserId',
        );
      }

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Error carregant converses: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final rawData =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      final List<dynamic> list = rawData is List ? rawData : [];

      if (!_canUseState) return;

      _safeSetState(() {
        _conversations
          ..clear()
          ..addAll(
            list.map(
              (item) => _ChatConversation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      });
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<_ChatConversation> _createOrGetConversation({
    required String customerId,
    required String restaurantId,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/chat/conversations');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'restaurantId': restaurantId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error creant conversa: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawData =
        decoded is Map<String, dynamic> ? decoded['data'] : decoded;

    return _ChatConversation.fromJson(
      Map<String, dynamic>.from(rawData as Map),
    );
  }

  Future<void> _selectConversation(_ChatConversation conversation) async {
    if (_selectedConversation != null) {
      _socket?.emit('chat:leaveConversation', {
        'conversationId': _selectedConversation!.id,
      });
    }

    _safeSetState(() {
      _selectedConversation = conversation;
      _messages.clear();
      _error = null;
    });

    _socket?.emit('chat:joinConversation', {
      'conversationId': conversation.id,
    });

    await _loadConversationMessages(conversation.id);
  }

  Future<void> _loadConversationMessages(String conversationId) async {
    _safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        '$_apiBaseUrl/chat/conversations/$conversationId/messages',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Error carregant missatges: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final rawData =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      final List<dynamic> list = rawData is List ? rawData : [];

      if (!_canUseState) return;

      _safeSetState(() {
        _messages
          ..clear()
          ..addAll(
            list.map(
              (item) => _ChatMessage.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      });

      _scrollToBottomDelayed();
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _selectedConversation == null || _currentUserId == null) {
      return;
    }

    _safeSetState(() {
      _isSending = true;
      _error = null;
    });

    try {
      if (_socketConnected && _socket != null) {
        _socket!.emit('chat:sendMessage', {
          'conversationId': _selectedConversation!.id,
          'senderId': _currentUserId,
          'senderRole': _senderRole,
          'contenido': text,
        });
      } else {
        final createdMessage = await _createMessageRest(
          conversationId: _selectedConversation!.id,
          senderId: _currentUserId!,
          senderRole: _senderRole,
          contenido: text,
        );

        if (!_canUseState) return;

        _safeSetState(() {
          _messages.add(createdMessage);
        });
      }

      _messageController.clear();
      _scrollToBottomDelayed();
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
      });
    } finally {
      _safeSetState(() {
        _isSending = false;
      });
    }
  }

  Future<_ChatMessage> _createMessageRest({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String contenido,
  }) async {
    final uri = Uri.parse(
      '$_apiBaseUrl/chat/conversations/$conversationId/messages',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': senderId,
        'senderRole': senderRole,
        'contenido': contenido,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error enviant missatge: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawData =
        decoded is Map<String, dynamic> ? decoded['data'] : decoded;

    return _ChatMessage.fromJson(
      Map<String, dynamic>.from(rawData as Map),
    );
  }

  void _backToConversations() {
    if (_openedFromRestaurant) {
      Navigator.pop(context);
      return;
    }

    if (_selectedConversation != null) {
      _socket?.emit('chat:leaveConversation', {
        'conversationId': _selectedConversation!.id,
      });
    }

    _safeSetState(() {
      _selectedConversation = null;
      _messages.clear();
    });

    _loadConversationsForCurrentUser();
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

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFFF7A1A);
    const Color dark = Color(0xFF0F172A);
    const Color grey = Color(0xFF64748B);

    final title = _hasSelectedConversation
        ? (_isEmployee
            ? _selectedConversation!.customerName
            : _selectedConversation!.restaurantName)
        : (_isEmployee ? 'Xats del restaurant' : 'Els teus xats');

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.74,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF7),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_hasSelectedConversation)
                  IconButton(
                    onPressed: _backToConversations,
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFE9D9),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: orange,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  _socketConnected
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  color: _socketConnected ? Colors.green : Colors.grey,
                  size: 20,
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasSelectedConversation
                      ? _buildMessages(orange: orange, dark: dark, grey: grey)
                      : _buildConversationList(
                          orange: orange,
                          dark: dark,
                          grey: grey,
                        ),
            ),
            if (_hasSelectedConversation) ...[
              const SizedBox(height: 8),
              _buildMessageInput(orange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList({
    required Color orange,
    required Color dark,
    required Color grey,
  }) {
    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, color: orange, size: 52),
              const SizedBox(height: 14),
              Text(
                _isEmployee
                    ? 'Encara no hi ha xats'
                    : 'Encara no tens converses',
                style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEmployee
                    ? 'Quan un client iniciï una conversa amb el restaurant, apareixerà aquí.'
                    : 'Obre un restaurant des de Discover i prem el botó de xat per començar una conversa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];

        final title = _isEmployee
            ? conversation.customerName
            : conversation.restaurantName;

        final subtitle =
            conversation.lastMessageText ?? 'Sense missatges encara';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _selectConversation(conversation),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFE9D9),
              child: Icon(
                _isEmployee ? Icons.person_rounded : Icons.restaurant_rounded,
                color: orange,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: dark,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }

  Widget _buildMessages({
    required Color orange,
    required Color dark,
    required Color grey,
  }) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Encara no hi ha missatges.\nEscriu el primer missatge.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == _currentUserId;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isMine ? orange : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              message.contenido,
              style: TextStyle(
                color: isMine ? Colors.white : dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(Color orange) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escriu un missatge...',
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
            onPressed: _isSending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSending
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
    );
  }
}

class _ChatConversation {
  final String id;
  final String customerId;
  final String restaurantId;
  final String customerName;
  final String restaurantName;
  final String? lastMessageText;

  _ChatConversation({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.customerName,
    required this.restaurantName,
    this.lastMessageText,
  });

  factory _ChatConversation.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'];
    final customer = json['customer'];
    final lastMessage = json['lastMessage'];

    return _ChatConversation(
      id: _extractId(json),
      customerId: _extractIdFromValue(customer),
      restaurantId: _extractIdFromValue(restaurant),
      customerName: _extractPersonName(customer, fallback: 'Client'),
      restaurantName: _extractRestaurantName(restaurant),
      lastMessageText:
          lastMessage is Map ? lastMessage['contenido']?.toString() : null,
    );
  }
}

class _ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String contenido;

  _ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.contenido,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      id: _extractId(json),
      conversationId: _extractIdFromValue(json['conversation']),
      senderId: _extractIdFromValue(json['sender']),
      senderRole: json['senderRole']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
    );
  }
}

String _extractId(Map<String, dynamic> json) {
  return json['_id']?.toString() ?? json['id']?.toString() ?? '';
}

String _extractIdFromValue(dynamic value) {
  if (value == null) return '';

  if (value is String) return value;

  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }

  return value.toString();
}

String _extractRestaurantName(dynamic value) {
  if (value is Map) {
    final profile = value['profile'];

    if (profile is Map && profile['name'] != null) {
      return profile['name'].toString();
    }

    if (value['name'] != null) {
      return value['name'].toString();
    }
  }

  return 'Restaurant';
}

String _extractPersonName(dynamic value, {required String fallback}) {
  if (value is Map) {
    final profile = value['profile'];

    if (profile is Map && profile['name'] != null) {
      return profile['name'].toString();
    }

    if (value['name'] != null) {
      return value['name'].toString();
    }

    if (value['email'] != null) {
      return value['email'].toString();
    }
  }

  return fallback;
}