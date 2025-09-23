import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/chat_websocket_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/new_message_dialog.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';

class ChatDetailPage extends StatefulWidget {
  final User otherUser;
  final VoidCallback? onMessageSent;
  final VoidCallback? onMessagesRead;

  const ChatDetailPage({
    super.key,
    required this.otherUser,
    this.onMessageSent,
    this.onMessagesRead,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final ChatWebSocketService _webSocketService = ServiceLocator.chatWebSocket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  int? _currentUserId;
  Set<int> _readMessageIds = {}; // Okunan mesaj ID'lerini tut
  bool _hasMarkedAsRead = false; // İlk yüklemede okundu işaretleme kontrolü

  // Real-time chat özellikleri
  bool _isConnected = false;
  String? _typingUser;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getCurrentUserId();
    await _loadMessages();
    _initializeWebSocket();
  }

  /// WebSocket bağlantısını başlat
  void _initializeWebSocket() {
    if (_currentUserId == null) return;

    // WebSocket mesaj dinleyicilerini başlat
    _webSocketService.messageStream.listen(_handleWebSocketMessage);
    _webSocketService.connectionStatusStream.listen(_handleConnectionStatus);
    _webSocketService.typingStream.listen(_handleTypingIndicator);

    // Özel sohbet WebSocket bağlantısını başlat
    _webSocketService.connectToPrivateChat(_currentUserId!, widget.otherUser.id);
  }

  /// WebSocket mesajlarını işle
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    // Mesaj ID'sini al (message_id öncelikli, yoksa id kullan)
    final messageId = message['message_id'] ?? message['id'] ?? DateTime.now().millisecondsSinceEpoch;
    
    // Aynı mesajın zaten listede olup olmadığını kontrol et
    if (_messages.any((m) => m.id == messageId)) {
      print('⚠️ Aynı mesaj zaten listede, eklenmedi: $messageId');
      return;
    }

    // Yeni mesajı listeye ekle
    final newMessage = PrivateMessage(
      id: messageId,
      sender: User.fromJson(message['sender'] ?? {}),
      receiver: User.fromJson(message['receiver'] ?? {}),
      message: message['message'] ?? '',
      timestamp: DateTime.tryParse(message['timestamp'] ?? '') ?? DateTime.now(),
      isRead: message['is_read'] ?? false,
    );

    setState(() {
      _messages.add(newMessage);
    });
    _scrollToBottom();

    // Parent widget'a mesaj alındığını bildir
    widget.onMessageSent?.call();
  }

  /// Bağlantı durumunu işle
  void _handleConnectionStatus(bool isConnected) {
    if (!mounted) return;

    setState(() {
      _isConnected = isConnected;
    });

    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real-time mesajlaşma aktif'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Typing indicator'ı işle
  void _handleTypingIndicator(String username) {
    if (!mounted) return;

    setState(() {
      _typingUser = username;
    });

    // 3 saniye sonra typing indicator'ı temizle
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _typingUser = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa açıldığında mesajları okundu olarak işaretle
    // _currentUserId set edildikten sonra çağır
    if (_currentUserId != null) {
      _markMessagesAsRead();
    }
  }

  Future<void> _getCurrentUserId() async {
    try {
      final currentUser = await ServiceLocator.user.getCurrentUsername();
      if (currentUser != null) {
        final profileData = await ServiceLocator.profile.getProfile(currentUser);
        if (mounted) {
          setState(() {
            _currentUserId = profileData?['id'];
          });
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    
    try {
      // Sadece diğer kullanıcıdan gelen okunmamış mesajları işaretle
      final unreadMessages = _messages.where((message) => 
        message.sender.id == widget.otherUser.id && 
        message.receiver.id == _currentUserId && 
        !message.isRead
      ).toList();
      
      // Her okunmamış mesajı işaretle
      for (final message in unreadMessages) {
        try {
          await _chatService.markMessageAsRead(message.id);
        } catch (e) {
          // Hata durumunda sessizce devam et
        }
      }
      
      // Local state'i güncelle
      if (mounted) {
        setState(() {
          for (final message in unreadMessages) {
            _readMessageIds.add(message.id);
          }
        });
        
        // Parent widget'a mesajların okunduğunu bildir
        widget.onMessagesRead?.call();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _webSocketService.disconnect();
    // Dispose sırasında callback çağırmayalım çünkü parent widget da dispose ediliyor olabilir
    super.dispose();
  }

  /// Text değişikliği handler'ı - typing indicator için
  void _onTextChanged(String text) {
    if (text.isNotEmpty && _isConnected) {
      _webSocketService.sendTypingIndicator();
    }
  }

  /// Typing indicator widget'ı
  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_typingUser yazıyor...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Room messages endpoint'ini kullan (frontend'in beklediği format)
      final messages = await _chatService.getRoomMessages(_currentUserId!, widget.otherUser.id);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
        
        // Mesajlar yüklendikten sonra okundu olarak işaretle (sadece ilk yüklemede)
        if (!_hasMarkedAsRead) {
          _markMessagesAsRead();
          _hasMarkedAsRead = true;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // WebSocket bağlantısı varsa önce WebSocket ile gönder
      if (_isConnected) {
        await _webSocketService.sendPrivateMessage(messageText, widget.otherUser.id);
        
        // Optimistic update - mesajı hemen UI'a ekle
        final optimisticMessage = PrivateMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: User(
            id: _currentUserId!,
            username: 'Sen', // TODO: Gerçek kullanıcı adını al
            firstName: null,
            lastName: null,
            profilePicture: null,
          ),
          receiver: widget.otherUser,
          message: messageText,
          timestamp: DateTime.now(),
          isRead: false,
        );

        setState(() {
          _messages.add(optimisticMessage);
          _messageController.clear();
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        // WebSocket yoksa HTTP API ile gönder (room messages endpoint'i kullan)
        final newMessage = await _chatService.sendRoomMessage(
          user1Id: _currentUserId!,
          user2Id: widget.otherUser.id,
          message: messageText,
        );
        
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
          _isSending = false;
        });
        _scrollToBottom();
      }
      
      // MessagesPage'e mesaj gönderildiğini bildir
      widget.onMessageSent?.call();
      
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editMessage(PrivateMessage message) async {
    final newContent = await _showEditDialog(message.message);
    if (newContent != null && newContent != message.message) {
      try {
        final updatedMessage = await _chatService.editPrivateMessage(
          messageId: message.id,
          message: newContent,
        );
        
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _messages[index] = updatedMessage;
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj düzenlenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(PrivateMessage message) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      try {
        await _chatService.deletePrivateMessage(message.id);
        
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.id == message.id);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj silinemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: widget.otherUser.profilePicture != null
                  ? NetworkImage(widget.otherUser.profilePicture!)
                  : null,
              child: widget.otherUser.profilePicture == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '@${widget.otherUser.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Bağlantı durumu göstergesi
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // TODO: Chat options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),
          // Typing Indicator
          if (_typingUser != null)
            _buildTypingIndicator(),
          // Message Input
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
            onTextChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Mesajlar yüklenemedi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMessages,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.message_outlined,
                size: 80,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz mesaj yok',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.otherUser.displayName} ile konuşmaya başlayın',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFirstInGroup = index == 0 || 
            _messages[index - 1].sender.id != message.sender.id ||
            message.timestamp.difference(_messages[index - 1].timestamp).inMinutes >= 5;
        final isLastInGroup = index == _messages.length - 1 ||
            _messages[index + 1].sender.id != message.sender.id ||
            _messages[index + 1].timestamp.difference(message.timestamp).inMinutes >= 5;
        
        final isMe = _currentUserId != null && message.sender.id == _currentUserId;
        
        return MessageBubble(
          message: message,
          isMe: isMe,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          isRead: _isMessageRead(message),
          onLongPress: isMe ? () => _showMessageOptions(message) : null,
        );
      },
    );
  }

  bool _isMessageRead(PrivateMessage message) {
    return message.isRead || _readMessageIds.contains(message.id);
  }




  void _showMessageOptions(PrivateMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _editMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEditDialog(String currentContent) async {
    final controller = TextEditingController(text: currentContent);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Mesajınızı düzenleyin...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}
