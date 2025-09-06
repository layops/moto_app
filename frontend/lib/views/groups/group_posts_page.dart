import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/color_schemes.dart';
import '../../services/group/group_service.dart';
import '../../services/auth/auth_service.dart';

class GroupPostsPage extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> groupData;
  final AuthService authService;

  const GroupPostsPage({
    Key? key,
    required this.groupId,
    required this.groupData,
    required this.authService,
  }) : super(key: key);

  @override
  State<GroupPostsPage> createState() => _GroupPostsPageState();
}

class _GroupPostsPageState extends State<GroupPostsPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  late GroupService _groupService;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final posts = await _groupService.getGroupPosts(widget.groupId);
      
      setState(() {
        _posts = List<Map<String, dynamic>>.from(posts);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
        _loading = false;
      });
    }
  }

  Future<void> _createPost() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreatePostDialog(
        groupName: widget.groupData['name'] ?? 'Group',
      ),
    );

    if (result != null) {
      try {
        await _groupService.createGroupPost(
          widget.groupId,
          result['content'],
          image: result['image'],
        );
        _loadPosts(); // Postları yeniden yükle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post başarıyla oluşturuldu!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post oluşturulamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.groupData['name']} Posts',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _createPost,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hata: $_error', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz post yok',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'İlk postu siz oluşturun!',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _createPost,
                            icon: const Icon(Icons.add),
                            label: const Text('Post Oluştur'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return _buildPostCard(post);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post başlığı - kullanıcı bilgileri
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post['author']?['profile_picture'] != null
                      ? NetworkImage(post['author']['profile_picture'])
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: post['author']?['profile_picture'] == null
                      ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author']?['username'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatTime(post['created_at']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post['author']?['username'] == widget.authService.getCurrentUsername())
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post['id']);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post içeriği
            if (post['content'] != null && post['content'].isNotEmpty)
              Text(
                post['content'],
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            
            // Post resmi
            if (post['image'] != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surface,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Post etkileşim butonları
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    // Like functionality
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.comment_outlined,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    // Comment functionality
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    // Share functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Postu Sil'),
        content: const Text('Bu postu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _groupService.deleteGroupPost(widget.groupId, postId);
        _loadPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post silinemedi: $e')),
        );
      }
    }
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

class _CreatePostDialog extends StatefulWidget {
  final String groupName;

  const _CreatePostDialog({required this.groupName});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.groupName} için Post Oluştur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Ne düşünüyorsunuz?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            // Seçilen resim
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Resim seçme butonu
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_selectedImage != null ? 'Resmi Değiştir' : 'Resim Ekle'),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _contentController.text.trim().isNotEmpty || _selectedImage != null
              ? () {
                  Navigator.pop(context, {
                    'content': _contentController.text.trim(),
                    'image': _selectedImage,
                  });
                }
              : null,
          child: const Text('Paylaş'),
        ),
      ],
    );
  }
}
