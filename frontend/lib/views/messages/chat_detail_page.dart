import 'package:flutter/material.dart';
import '../../services/chat/chat_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/new_message_dialog.dart';

class ChatDetailPage extends StatefulWidget {
  final User otherUser;
  final VoidCallback? onMessageSent;

  const ChatDetailPage({
    super.key,
    required this.otherUser,
    this.onMessageSent,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  int? _currentUserId;
  Set<int> _readMessageIds = {}; // Okunan mesaj ID'lerini tut

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa açıldığında mesajları okundu olarak işaretle
    _markMessagesAsRead();
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
      print('❌ ChatDetail - Error getting current user ID: $e');
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
      
      print('📖 ChatDetail - Marking ${unreadMessages.length} messages as read');
      
      // Her okunmamış mesajı işaretle
      for (final message in unreadMessages) {
        try {
          await _chatService.markMessageAsRead(message.id);
          print('📖 ChatDetail - Marked message ${message.id} as read');
        } catch (e) {
          print('❌ ChatDetail - Error marking message ${message.id} as read: $e');
        }
      }
      
      // Local state'i güncelle
      if (mounted) {
        setState(() {
          for (final message in unreadMessages) {
            _readMessageIds.add(message.id);
          }
        });
      }
    } catch (e) {
      print('❌ ChatDetail - Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('💬 ChatDetail - Loading messages with user: ${widget.otherUser.username}');
      final messages = await _chatService.getConversationWithUser(widget.otherUser.id);
      print('💬 ChatDetail - Loaded ${messages.length} messages');
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
        
        // Mesajlar yüklendikten sonra okundu olarak işaretle
        _markMessagesAsRead();
      }
    } catch (e) {
      print('❌ ChatDetail - Error loading messages: $e');
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
      print('📤 ChatDetail - Sending message: "$messageText" to ${widget.otherUser.username}');
      final newMessage = await _chatService.sendPrivateMessage(
        receiverId: widget.otherUser.id,
        message: messageText,
      );
      
      print('📤 ChatDetail - Message sent successfully');
      
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
          _isSending = false;
        });
        _scrollToBottom();
        
        // MessagesPage'e mesaj gönderildiğini bildir
        widget.onMessageSent?.call();
      }
    } catch (e) {
      print('❌ ChatDetail - Error sending message: $e');
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
          // Message Input
          _buildMessageInput(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
        
        return _buildMessageBubble(message, isFirstInGroup, isLastInGroup);
      },
    );
  }

  bool _isMessageRead(PrivateMessage message) {
    return message.isRead || _readMessageIds.contains(message.id);
  }


  Widget _buildMessageBubble(PrivateMessage message, bool isFirstInGroup, bool isLastInGroup) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMe = _currentUserId != null && message.sender.id == _currentUserId;
    final isRead = _isMessageRead(message);

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastInGroup ? 12 : 2, // Grup içinde daha az boşluk
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Sadece grup başında avatar göster
            if (isFirstInGroup) ...[
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
              const SizedBox(width: 8),
            ] else ...[
              // Avatar yerine boşluk bırak
              const SizedBox(width: 40),
            ],
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? colorScheme.primary 
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20).copyWith(
                  topLeft: isMe 
                      ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                      : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                  topRight: isMe 
                      ? (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4))
                      : (isFirstInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                  bottomLeft: isMe 
                      ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                      : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                  bottomRight: isMe 
                      ? (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4))
                      : (isLastInGroup ? const Radius.circular(20) : const Radius.circular(4)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe 
                          ? colorScheme.onPrimary 
                          : colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe 
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: colorScheme.onPrimary,
                    ),
            ),
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
