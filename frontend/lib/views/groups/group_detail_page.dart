import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'members_page.dart';
import 'group_messages_page.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> groupData;
  final AuthService authService;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupData,
    required this.authService,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late GroupService _groupService;
  late bool _isMember;
  late bool _isOwner;
  late bool _isModerator;
  List<dynamic> _posts = [];
  bool _loading = false;
  String? _error;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
    _isMember = false;
    _isOwner = false;
    _isModerator = false;
    _checkUserStatus();
    _loadPosts();
  }

  Future<void> _checkUserStatus() async {
    try {
      final currentUsername = await widget.authService.getCurrentUsername();
      if (currentUsername == null) return;

      final groupOwner = widget.groupData['owner']?['username'];
      final groupMembers = List<Map<String, dynamic>>.from(
        widget.groupData['members'] ?? [],
      );

      setState(() {
        _isOwner = currentUsername == groupOwner;
        _isMember = groupMembers.any((member) => member['username'] == currentUsername);
        _isModerator = false; // Şimdilik moderator özelliği yok
      });
    } catch (e) {
      print('Kullanıcı durumu kontrol edilemedi: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _groupService.getGroupPosts(widget.groupId);
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      print('Postlar yüklenemedi: $e');
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

  void _navigateToGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupMessagesPage(
          groupId: widget.groupId,
          groupData: widget.groupData,
          authService: widget.authService,
        ),
      ),
    );
  }

  void _navigateToMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembersPage(
          groupData: widget.groupData,
          isOwner: _isOwner,
          isModerator: _isModerator,
          authService: widget.authService,
        ),
      ),
    );
  }

  void _inviteMembers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Davet özelliği yakında eklenecek!')),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruptan Ayrıl'),
        content: const Text('Bu gruptan ayrılmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gruptan ayrıldınız')),
              );
            },
            child: Text('Ayrıl', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showGroupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grup ayarları yakında eklenecek!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupData['name'] ?? 'Grup',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => _showGroupSettings(),
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
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          _checkUserStatus();
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Modern grup header
                      _buildModernGroupHeader(),
                      const SizedBox(height: 32),

                      // About bölümü
                      _buildAboutSection(),
                      const SizedBox(height: 32),

                      // Members bölümü
                      _buildMembersSection(),
                      const SizedBox(height: 32),

                      // Posts bölümü
                      _buildPostsSection(),
                      const SizedBox(height: 24), // Alt boşluk
                    ],
                  ),
                ),
    );
  }

  Widget _buildModernGroupHeader() {
    final groupName = widget.groupData['name'] ?? 'Grup Adı';
    final memberCount = widget.groupData['member_count'] ?? 0;
    final profilePictureUrl = widget.groupData['profile_picture_url'];
    
    return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
            children: [
                // Grup logosu
                Center(
                    child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2D5A27), // Koyu yeşil
                            border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: profilePictureUrl != null
                            ? ClipOval(
                                child: Image.network(
                                    profilePictureUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
                                ),
                            )
                            : _buildDefaultLogo(),
                    ),
                ),
                const SizedBox(height: 24),
                
                            // Butonlar - yan yana
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                    _buildActionButton(
                                        icon: Icons.chat_bubble_outline,
                                        label: 'Message',
                                        onTap: _navigateToGroupChat,
                                        color: Theme.of(context).colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.post_add,
                                        label: 'Post',
                                        onTap: _createPost,
                                        color: Theme.of(context).colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.person_add,
                                        label: 'Invite',
                                        onTap: _inviteMembers,
                                        color: Theme.of(context).colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.exit_to_app,
                                        label: 'Leave',
                                        onTap: _isMember ? _leaveGroup : null,
                                        color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                            ),
          const SizedBox(height: 24),
          
          // Grup adı - ortalanmış
          Center(
            child: Text(
              groupName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          
          // Üye sayısı - ortalanmış
          Center(
            child: Text(
              '$memberCount members',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
    ),
);
  }

  Widget _buildDefaultLogo() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.group,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final description = widget.groupData['description'] ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description.isNotEmpty 
                ? description 
                : 'No description available.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final members = List<Map<String, dynamic>>.from(widget.groupData['members'] ?? []);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToMembers(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Üye listesi
          _buildMembersList(members),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<Map<String, dynamic>> members) {
    if (members.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'No members yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      children: members.take(3).map((member) => _buildModernMemberItem(member)).toList(),
    );
  }

  Widget _buildModernMemberItem(Map<String, dynamic> member) {
    final username = member['username'] ?? 'Unknown';
    final isOwner = member['username'] == widget.groupData['owner']?['username'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  isOwner ? 'Owner' : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Postları göster
          _buildPostsList(),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.post_add,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No posts yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _posts.take(3).map((post) => _buildPostCard(post)).toList(),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post başlığı - kullanıcı bilgileri
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: post['author']?['profile_picture'] != null
                      ? NetworkImage(post['author']['profile_picture'])
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: post['author']?['profile_picture'] == null
                      ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author']?['username'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTime(post['created_at']),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Post içeriği
            if (post['content'] != null && post['content'].isNotEmpty)
              Text(
                post['content'],
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            
            // Post resmi
            if (post['image'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
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
          ],
        ),
      ),
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
