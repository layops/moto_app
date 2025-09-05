// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\group_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';

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
  List<dynamic> _messages = [];
  List<dynamic> _joinRequests = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(authService: widget.authService);
    _isMember = _checkMembership();
    _isOwner = _checkOwnership();
    _isModerator = _checkModeratorStatus();
    _loadGroupData();
  }

  bool _checkMembership() {
    final members = widget.groupData['members'] as List<dynamic>? ?? [];
    // Şimdilik basit bir kontrol, gerçek uygulamada token'dan user ID alınabilir
    return false; // Geçici olarak false döndürüyoruz
  }

  bool _checkOwnership() {
    // Şimdilik basit bir kontrol, gerçek uygulamada token'dan user ID alınabilir
    return false; // Geçici olarak false döndürüyoruz
  }

  bool _checkModeratorStatus() {
    final moderators = widget.groupData['moderators'] as List<dynamic>? ?? [];
    // Şimdilik basit bir kontrol, gerçek uygulamada token'dan user ID alınabilir
    return false; // Geçici olarak false döndürüyoruz
  }

  Future<void> _loadGroupData() async {
    setState(() => _loading = true);
    try {
      if (_isMember || _isOwner || _isModerator) {
        final posts = await _groupService.getGroupPosts(widget.groupId);
        final messages = await _groupService.getGroupMessages(widget.groupId);
        setState(() {
          _posts = posts;
          _messages = messages;
        });
      }
      
      if (_isOwner || _isModerator) {
        final joinRequests = await _groupService.getJoinRequests(widget.groupId);
        setState(() {
          _joinRequests = joinRequests.where((req) => req['status'] == 'pending').toList();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupData['name'] ?? 'Grup Detayları'),
        backgroundColor: AppColorSchemes.surfaceColor,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
        actions: [
          if (_isOwner || _isModerator)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showGroupSettings(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hata: $_error'),
                      ElevatedButton(
                        onPressed: _loadGroupData,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: ThemeConstants.paddingLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grup başlık bölümü
                      _buildGroupHeader(),
                      const SizedBox(height: 24),

                      // Katılım talepleri (sadece owner/moderator için)
                      if (_joinRequests.isNotEmpty) ...[
                        _buildJoinRequestsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Grup aksiyon butonları
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // Grup içeriği bölümleri
                      const Text('Grup İçeriği',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildContentTabs(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorSchemes.surfaceColor,
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Grup profil fotoğrafı
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.groupData['profile_picture_url'] != null
                    ? NetworkImage(widget.groupData['profile_picture_url'])
                    : null,
                child: widget.groupData['profile_picture_url'] == null
                    ? const Icon(Icons.group, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupData['name'] ?? 'Grup Adı Yok',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.groupData['description'] ?? 'Açıklama Yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColorSchemes.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.people,
                text: '${widget.groupData['member_count'] ?? '0'} üye',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.public,
                text: widget.groupData['join_type'] == 'public' ? 'Herkese Açık' : 'Özel',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Katılım Talepleri (${_joinRequests.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_joinRequests.take(3).map((request) => _buildJoinRequestItem(request))),
          if (_joinRequests.length > 3)
            TextButton(
              onPressed: () => _showAllJoinRequests(),
              child: Text('Tümünü Gör (${_joinRequests.length})'),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestItem(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: request['user']['profile_picture'] != null
                ? NetworkImage(request['user']['profile_picture'])
                : null,
            child: request['user']['profile_picture'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['user']['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (request['message'] != null && request['message'].isNotEmpty)
                  Text(
                    request['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColorSchemes.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _approveJoinRequest(request['id']),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _rejectJoinRequest(request['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isMember) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePostDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Post Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorSchemes.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showChatDialog(),
              icon: const Icon(Icons.chat),
              label: const Text('Mesajlaş'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorSchemes.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.groupData['join_type'] == 'public' ? 'Gruba Katıl' : 'Katılım Talebi Gönder'),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareGroup(),
            style: IconButton.styleFrom(
              backgroundColor: AppColorSchemes.lightBackground,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContentTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Gönderiler'),
              Tab(text: 'Mesajlar'),
              Tab(text: 'Üyeler'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildPostsTab(),
                _buildMessagesTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return _buildPlaceholderContent('Henüz gönderi yok');
    }
    
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: post['author']['profile_picture'] != null
                          ? NetworkImage(post['author']['profile_picture'])
                          : null,
                      child: post['author']['profile_picture'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['author']['username'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(post['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColorSchemes.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isOwner || _isModerator) // Geçici olarak sadece owner/moderator kontrolü
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Sil'),
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
                Text(post['content']),
                if (post['image'] != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post['image'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    if (_messages.isEmpty) {
      return _buildPlaceholderContent('Henüz mesaj yok');
    }
    
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isOwnMessage = false; // Geçici olarak false, gerçek uygulamada token'dan user ID alınabilir
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwnMessage) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: message['sender']['profile_picture'] != null
                      ? NetworkImage(message['sender']['profile_picture'])
                      : null,
                  child: message['sender']['profile_picture'] == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOwnMessage ? AppColorSchemes.primaryColor : AppColorSchemes.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isOwnMessage)
                        Text(
                          message['sender']['username'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColorSchemes.textSecondary,
                          ),
                        ),
                      Text(
                        message['content'],
                        style: TextStyle(
                          color: isOwnMessage ? Colors.white : AppColorSchemes.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(message['created_at']),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwnMessage ? Colors.white70 : AppColorSchemes.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOwnMessage) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: message['sender']['profile_picture'] != null
                      ? NetworkImage(message['sender']['profile_picture'])
                      : null,
                  child: message['sender']['profile_picture'] == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    final members = widget.groupData['members'] as List<dynamic>? ?? [];
    final moderators = widget.groupData['moderators'] as List<dynamic>? ?? [];
    final owner = widget.groupData['owner'];
    
    return ListView(
      children: [
        // Grup sahibi
        _buildMemberItem(owner, 'Sahip'),
        // Moderatörler
        ...moderators.map((moderator) => _buildMemberItem(moderator, 'Moderatör')),
        // Üyeler
        ...members.map((member) => _buildMemberItem(member, 'Üye')),
      ],
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorSchemes.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member['profile_picture'] != null
                ? NetworkImage(member['profile_picture'])
                : null,
            child: member['profile_picture'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColorSchemes.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if ((_isOwner || _isModerator) && role == 'Üye')
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Gruptan Çıkar'),
                ),
                if (_isOwner)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Moderatör Yap'),
                  ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  _removeMember(member['id']);
                } else if (value == 'promote') {
                  _promoteToModerator(member['id']);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColorSchemes.lightBackground,
    );
  }

  Widget _buildPlaceholderContent(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: AppColorSchemes.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // --- HELPER METHODS ---

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return dateString;
    }
  }

  // --- ACTION METHODS ---

  Future<void> _joinGroup() async {
    try {
      if (widget.groupData['join_type'] == 'public') {
        // Direkt katıl
        await _groupService.joinGroup(widget.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruba başarıyla katıldınız!')),
        );
        _loadGroupData();
      } else {
        // Katılım talebi gönder
        await _groupService.sendJoinRequest(widget.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılım talebi gönderildi!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _approveJoinRequest(int requestId) async {
    try {
      await _groupService.approveJoinRequest(widget.groupId, requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Katılım talebi onaylandı!')),
      );
      _loadGroupData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _rejectJoinRequest(int requestId) async {
    try {
      await _groupService.rejectJoinRequest(widget.groupId, requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Katılım talebi reddedildi!')),
      );
      _loadGroupData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      await _groupService.deleteGroupPost(widget.groupId, postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post silindi!')),
      );
      _loadGroupData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _removeMember(int memberId) async {
    // Bu metod backend'de implement edilmeli
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Üye çıkarma özelliği yakında eklenecek!')),
    );
  }

  Future<void> _promoteToModerator(int memberId) async {
    // Bu metod backend'de implement edilmeli
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moderatör yapma özelliği yakında eklenecek!')),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(
        groupId: widget.groupId,
        groupService: _groupService,
        onPostCreated: _loadGroupData,
      ),
    );
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => _ChatDialog(
        groupId: widget.groupId,
        groupService: _groupService,
        messages: _messages,
        onMessageSent: _loadGroupData,
      ),
    );
  }

  void _showGroupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grup ayarları yakında eklenecek!')),
    );
  }

  void _showAllJoinRequests() {
    showDialog(
      context: context,
      builder: (context) => _JoinRequestsDialog(
        groupId: widget.groupId,
        groupService: _groupService,
        joinRequests: _joinRequests,
        onRequestHandled: _loadGroupData,
      ),
    );
  }

  void _shareGroup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım özelliği yakında eklenecek!')),
    );
  }
}

// --- DIALOG WIDGETS ---

class _CreatePostDialog extends StatefulWidget {
  final int groupId;
  final GroupService groupService;
  final VoidCallback onPostCreated;

  const _CreatePostDialog({
    required this.groupId,
    required this.groupService,
    required this.onPostCreated,
  });

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _loading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post Oluştur'),
      content: Column(
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
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickImage,
              ),
              if (_selectedImage != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedImage = null),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _createPost,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Paylaş'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir içerik girin!')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.groupService.createGroupPost(
        widget.groupId,
        _contentController.text.trim(),
        image: _selectedImage,
      );
      Navigator.pop(context);
      widget.onPostCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post başarıyla oluşturuldu!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}

class _ChatDialog extends StatefulWidget {
  final int groupId;
  final GroupService groupService;
  final List<dynamic> messages;
  final VoidCallback onMessageSent;

  const _ChatDialog({
    required this.groupId,
    required this.groupService,
    required this.messages,
    required this.onMessageSent,
  });

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _messageController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Grup Mesajları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColorSchemes.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender']['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(message['content']),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _sendMessage,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      await widget.groupService.sendGroupMessage(
        widget.groupId,
        _messageController.text.trim(),
      );
      _messageController.clear();
      widget.onMessageSent();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}

class _JoinRequestsDialog extends StatelessWidget {
  final int groupId;
  final GroupService groupService;
  final List<dynamic> joinRequests;
  final VoidCallback onRequestHandled;

  const _JoinRequestsDialog({
    required this.groupId,
    required this.groupService,
    required this.joinRequests,
    required this.onRequestHandled,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Katılım Talepleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: joinRequests.length,
                itemBuilder: (context, index) {
                  final request = joinRequests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColorSchemes.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: request['user']['profile_picture'] != null
                              ? NetworkImage(request['user']['profile_picture'])
                              : null,
                          child: request['user']['profile_picture'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['user']['username'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (request['message'] != null && request['message'].isNotEmpty)
                                Text(
                                  request['message'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColorSchemes.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveRequest(context, request['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(context, request['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, int requestId) async {
    try {
      await groupService.approveJoinRequest(groupId, requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Katılım talebi onaylandı!')),
      );
      onRequestHandled();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, int requestId) async {
    try {
      await groupService.rejectJoinRequest(groupId, requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Katılım talebi reddedildi!')),
      );
      onRequestHandled();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}
