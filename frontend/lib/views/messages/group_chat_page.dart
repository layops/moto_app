import 'package:flutter/material.dart';
import '../../services/chat/group_chat_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';

class GroupChatPage extends StatefulWidget {
  final int groupId;
  final String groupName;
  final VoidCallback? onMessageSent;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.onMessageSent,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final GroupChatService _groupChatService = GroupChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  int? _currentUserId;
  GroupMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getCurrentUserId();
    await _loadMessages();
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

      final messages = await _groupChatService.getGroupMessages(widget.groupId);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
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
      final newMessage = await _groupChatService.sendGroupMessage(
        groupId: widget.groupId,
        content: messageText,
        replyToId: _replyingTo?.id.toString(),
      );
      
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
          _isSending = false;
          _replyingTo = null;
        });
        _scrollToBottom();
        
        // Parent widget'a mesaj gönderildiğini bildir
        widget.onMessageSent?.call();
      }
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

  Future<void> _editMessage(GroupMessage message) async {
    final newContent = await _showEditDialog(message.content);
    if (newContent != null && newContent != message.content) {
      try {
        await _groupChatService.editGroupMessage(
          groupId: widget.groupId,
          messageId: message.id,
          content: newContent,
        );
        await _loadMessages();
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

  Future<void> _deleteMessage(GroupMessage message) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      try {
        await _groupChatService.deleteGroupMessage(
          groupId: widget.groupId,
          messageId: message.id,
        );
        await _loadMessages();
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
        title: Text(widget.groupName),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showGroupOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply indicator
          if (_replyingTo != null) _buildReplyIndicator(),
          
          // Messages List
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Message Input
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
            replyTo: _replyingTo?.content,
            onCancelReply: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_replyingTo!.sender.displayName} yanıtlanıyor',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _replyingTo!.content,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
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
                Icons.group_outlined,
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
                '${widget.groupName} grubunda konuşmaya başlayın',
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
            message.createdAt.difference(_messages[index - 1].createdAt).inMinutes >= 5;
        final isLastInGroup = index == _messages.length - 1 ||
            _messages[index + 1].sender.id != message.sender.id ||
            _messages[index + 1].createdAt.difference(message.createdAt).inMinutes >= 5;
        
        return GroupMessageBubble(
          message: message,
          isMe: isMe,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          onLongPress: isMe ? () => _showMessageOptions(message) : null,
        );
      },
    );
  }



  void _showMessageOptions(GroupMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Yanıtla'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                });
              },
            ),
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

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text('Grup Bilgileri'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement group info
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: const Text('Üyeler'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement group members
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Grup Ayarları'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement group settings
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
