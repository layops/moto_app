import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/color_schemes.dart';
import '../../services/group/group_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/post/post_item.dart';

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
                          return PostItem(post: post);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
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
  void initState() {
    super.initState();
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // TextField değiştiğinde UI'yi güncelle
    });
  }

  bool get _canPost {
    final hasText = _contentController.text.trim().isNotEmpty;
    final hasImage = _selectedImage != null;
    final canPost = hasText || hasImage;
    
    // Debug için
    print('Post validation - Text: $hasText, Image: $hasImage, CanPost: $canPost');
    print('Text content: "${_contentController.text.trim()}"');
    
    return canPost;
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
              onChanged: (value) {
                setState(() {
                  // TextField değiştiğinde UI'yi güncelle
                });
              },
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
          onPressed: _canPost
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
