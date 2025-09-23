import 'package:flutter/material.dart';
import '../../services/chat/chat_service.dart';
import '../../widgets/new_message_dialog.dart';
import 'chat_detail_page.dart';
import 'message_search_page.dart';

class MessagesPage extends StatefulWidget {
  final VoidCallback? onUnreadCountChanged;
  
  const MessagesPage({super.key, this.onUnreadCountChanged});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasLoadedOnce = false; // İlk yükleme kontrolü

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sadece ilk kez açıldığında conversations listesini yenile
    if (!_hasLoadedOnce) {
      _loadConversations();
      _hasLoadedOnce = true;
    }
  }

  @override
  void didUpdateWidget(MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget güncellendiğinde conversations listesini yenile
    // Sadece gerekli olduğunda yenile - şimdilik yenileme yapmıyoruz
  }

  Future<void> _loadConversations() async {
    try {
      if (!mounted) return;
      
      // Eğer zaten yüklenmişse ve cache geçerliyse yeniden yükleme
      if (_conversations.isNotEmpty && !_isLoading) {
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final conversations = await _chatService.getConversations();
      
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
      
      // Bottom navigation'ı güncelle
      widget.onUnreadCountChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _navigateToMessageSearch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'messages_fab',
        onPressed: () {
          _showNewMessageDialog();
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    
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
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Hata',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadConversations,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
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
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz mesajınız yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir konuşma başlatın',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;
    final lastMessage = conversation.lastMessage;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: conversation.otherUser.profilePicture != null
                  ? ClipOval(
                      child: Image.network(
                        conversation.otherUser.profilePicture!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
            ),
            if (conversation.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          conversation.otherUser.displayName,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          lastMessage?.message ?? 'Henüz mesaj yok',
          style: TextStyle(
            color: hasUnread 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessage != null)
              Text(
                _formatTime(lastMessage.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          _openConversation(conversation);
        },
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          otherUser: conversation.otherUser,
          onMessageSent: () {
            // Mesaj gönderildiğinde conversations listesini yenile
            if (mounted) {
              _loadConversations();
            }
          },
          onMessagesRead: () {
            // Mesajlar okunduğunda conversations listesini yenile
            if (mounted) {
              _loadConversations();
            }
          },
        ),
      ),
    ).then((_) {
      // ChatDetailPage'den geri döndüğünde conversations listesini yenile
      // Bu sayede okunmamış mesaj sayıları güncellenir
      if (mounted) {
        _loadConversations();
      }
    });
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => NewMessageDialog(
        onUserSelected: (user) {
          Navigator.of(context).pop();
          _startConversationWithUser(user);
        },
      ),
    );
  }

  void _startConversationWithUser(User user) {
    // Chat detail sayfasına yönlendir
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          otherUser: user,
          onMessageSent: () {
            // Mesaj gönderildiğinde conversations listesini yenile
            _loadConversations();
          },
          onMessagesRead: () {
            // Mesajlar okunduğunda conversations listesini yenile
            _loadConversations();
          },
        ),
      ),
    ).then((_) {
      // ChatDetailPage'den geri döndüğünde conversations listesini yenile
      _loadConversations();
    });
  }

  void _navigateToMessageSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MessageSearchPage(),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    // TODO: HiddenConversation modeli migration sonrası aktif edilecek
    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) => Container(
    //     padding: const EdgeInsets.all(16),
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         ListTile(
    //           leading: const Icon(Icons.visibility_off_rounded, color: Colors.orange),
    //           title: const Text('Konuşmayı Gizle', style: TextStyle(color: Colors.orange)),
    //           onTap: () {
    //             Navigator.pop(context);
    //             _hideConversation(conversation);
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  Future<void> _hideConversation(Conversation conversation) async {
    final confirmed = await _showHideConversationDialog(conversation.otherUser.displayName);
    if (confirmed == true) {
      try {
        await _chatService.hideConversation(conversation.otherUser.id);
        
        if (mounted) {
          setState(() {
            _conversations.removeWhere((c) => c.otherUser.id == conversation.otherUser.id);
          });
          
          // Bottom navigation'ı güncelle
          widget.onUnreadCountChanged?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${conversation.otherUser.displayName} ile olan konuşma gizlendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konuşma gizlenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showHideConversationDialog(String userName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Gizle'),
        content: Text('$userName ile olan konuşmanızı gizlemek istediğinizden emin misiniz?\n\nKonuşma sadece sizin listenizden gizlenecek. Mesajlar silinmeyecek ve karşı taraf konuşmayı görmeye devam edecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Gizle'),
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
