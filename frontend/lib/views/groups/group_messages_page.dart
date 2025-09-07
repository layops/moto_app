import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/color_schemes.dart';
import '../../services/group/group_service.dart';
import '../../services/auth/auth_service.dart';

class GroupMessagesPage extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> groupData;
  final AuthService authService;

  const GroupMessagesPage({
    Key? key,
    required this.groupId,
    required this.groupData,
    required this.authService,
  }) : super(key: key);

  @override
  State<GroupMessagesPage> createState() => _GroupMessagesPageState();
}

class _GroupMessagesPageState extends State<GroupMessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late GroupService _groupService;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
    _loadMessages();
    
    // Focus'u biraz gecikmeyle aç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final messages = await _groupService.getGroupMessages(widget.groupId);
      
      setState(() {
        _messages = List<Map<String, dynamic>>.from(messages);
        _loading = false;
      });
      
      // Mesajlar yüklendikten sonra en alta kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // reverse: true olduğu için 0.0 en alt
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();
      print('Seçilen dosya boyutu: $fileSize bytes');
      print('Dosya yolu: ${image.path}');
      
      if (fileSize > 0) {
        setState(() {
          _selectedImage = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçilen dosya boş veya okunamıyor')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    try {
      await _groupService.sendGroupMessage(
        widget.groupId, 
        content,
        messageType: _selectedImage != null ? 'image' : 'text',
        mediaFile: _selectedImage,
      );
      
      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
      await _loadMessages(); // Mesajları yeniden yükle
      
      // Yeni mesaj gönderildikten sonra en alta kaydır
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // reverse: true olduğu için 0.0 en alt
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupData['name'] ?? 'Group Messages',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mesajlar listesi
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Hata: $_error', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz mesaj yok',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'İlk mesajı siz gönderin!',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true, // En yeni mesajlar aşağıda
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              // Mesajları ters sırala (en yeni en son)
                              final reversedIndex = _messages.length - 1 - index;
                              final message = _messages[reversedIndex];
                              return _buildMessageBubble(message);
                            },
                          ),
          ),
          
          // Seçilen resim önizlemesi
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Resim seçildi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),

          // Mesaj gönderme alanı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onTap: () {
                      _messageFocusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return FutureBuilder<String?>(
      future: widget.authService.getCurrentUsername(),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data;
        final isOwnMessage = message['sender']?['username'] == currentUsername;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 18,
              backgroundImage: message['sender']?['profile_picture'] != null
                  ? NetworkImage(message['sender']['profile_picture'])
                  : null,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: message['sender']?['profile_picture'] == null
                  ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOwnMessage 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: isOwnMessage 
                    ? null 
                    : Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage)
                    Text(
                      message['sender']?['username'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (!isOwnMessage) const SizedBox(height: 4),
                  
                  // Medya gösterimi
                  if (message['message_type'] == 'image' && message['file_url'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message['file_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  
                  // Mesaj içeriği (sadece text mesajlar için)
                  if (message['content'] != null && message['content'].toString().isNotEmpty)
                    Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: isOwnMessage 
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwnMessage 
                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundImage: message['sender']?['profile_picture'] != null
                  ? NetworkImage(message['sender']['profile_picture'])
                  : null,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: message['sender']?['profile_picture'] == null
                  ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                  : null,
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Şimdi';
      }
    } catch (e) {
      return '';
    }
  }
}
