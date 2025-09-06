// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\group_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'members_page.dart';

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
    _isMember = false;
    _isOwner = false;
    _isModerator = false;
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final currentUsername = await widget.authService.getCurrentUsername();
      if (currentUsername == null) return;

      final members = widget.groupData['members'] as List<dynamic>? ?? [];
      final owner = widget.groupData['owner'];
      final moderators = widget.groupData['moderators'] as List<dynamic>? ?? [];

      setState(() {
        _isMember = members.any((member) => member['username'] == currentUsername);
        _isOwner = owner != null && owner['username'] == currentUsername;
        _isModerator = moderators.any((moderator) => moderator['username'] == currentUsername);
      });

      _loadGroupData();
    } catch (e) {
      print('Kullanıcı durumu kontrol edilirken hata: $e');
      _loadGroupData();
    }
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
        title: const Text(
          'Group Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_isOwner || _isModerator)
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
                        onPressed: _loadGroupData,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grup başlık bölümü
                      _buildModernGroupHeader(),
                      const SizedBox(height: 32),

                      // About bölümü
                      _buildAboutSection(),
                      const SizedBox(height: 32),

                      // Members bölümü
                      _buildMembersSection(),
                      const SizedBox(height: 32),

                      // Shared Media bölümü
                      _buildSharedMediaSection(),
                      const SizedBox(height: 100), // Alt butonlar için boşluk
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomActionButtons(),
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
          // Grup logosu - ortalanmış
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorSchemes.primaryColor,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
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
    return Center(
      child: Icon(
        Icons.motorcycle,
        size: 60,
        color: Theme.of(context).colorScheme.onPrimary,
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
    final members = widget.groupData['members'] as List<dynamic>? ?? [];
    final owner = widget.groupData['owner'];
    
    // Grup sahibini üyeler listesinden çıkar
    final filteredMembers = members.where((member) => 
      member['id'] != owner['id']
    ).toList();
    
    // İlk 6 üyeyi göster
    final displayMembers = [
      owner,
      ...filteredMembers.take(5),
    ];
    
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
          ...displayMembers.map((member) => _buildModernMemberItem(member)),
        ],
      ),
    );
  }

  Widget _buildModernMemberItem(Map<String, dynamic> member) {
    final isOwner = member['id'] == widget.groupData['owner']['id'];
    final role = isOwner ? 'Admin' : 'Member';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: member['profile_picture'] != null
                ? NetworkImage(member['profile_picture'])
                : null,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: member['profile_picture'] == null
                ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['username'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildSharedMediaSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Media',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Örnek medya grid'i - gerçek uygulamada grup postlarından resimler alınabilir
          _buildMediaGrid(),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    // Gerçek grup postlarından resimler alınacak
    final mediaItems = <String>[];
    
    if (mediaItems.isEmpty) {
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
                Icons.photo_library_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No shared media yet',
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
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              mediaItems[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 40,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grup mesajları butonu
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColorSchemes.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: _navigateToGroupChat,
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                label: Text(
                  'Group Messages',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Alt butonlar
            Row(
              children: [
                // Leave Group butonu
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _isMember ? _leaveGroup : null,
                      child: Text(
                        'Leave Group',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Invite Members butonu
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColorSchemes.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _inviteMembers,
                      child: Text(
                        'Invite Members',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Leave Group',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to leave this group?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Leave group logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Left group successfully')),
              );
            },
            child: Text('Leave', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _inviteMembers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite members feature coming soon!')),
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

  void _navigateToGroupChat() {
    // Grup mesajları sayfasına yönlendirme
    // Bu sayfa henüz oluşturulmadı, şimdilik bir snackbar gösterelim
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group chat feature coming soon!')),
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
    // Grup sahibi ise sadece post oluştur butonu göster
    if (_isOwner) {
      return SizedBox(
        width: double.infinity,
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
      );
    }
    
    // Grup üyesi ise sadece post oluştur butonu göster
    if (_isMember) {
      return SizedBox(
        width: double.infinity,
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
      );
    }
    
    // Ne üye ne de sahip ise katılım talebi butonu göster
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
    return Container(
      color: const Color(0xFF1A1A1A), // Koyu tema arka plan
      child: Column(
        children: [
          // Mesajlar listesi
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı siz gönderin!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isOwnMessage = false; // Geçici olarak false, gerçek uygulamada token'dan user ID alınabilir
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isOwnMessage) ...[
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: message['sender']['profile_picture'] != null
                                    ? NetworkImage(message['sender']['profile_picture'])
                                    : null,
                                backgroundColor: Colors.grey[700],
                                child: message['sender']['profile_picture'] == null
                                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isOwnMessage 
                                      ? const Color(0xFF6B46C1) // Mor renk
                                      : const Color(0xFFEC4899), // Pembe renk
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isOwnMessage)
                                      Text(
                                        message['sender']['username'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      message['content'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                                backgroundImage: message['sender']['profile_picture'] != null
                                    ? NetworkImage(message['sender']['profile_picture'])
                                    : null,
                                backgroundColor: Colors.grey[700],
                                child: message['sender']['profile_picture'] == null
                                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Mesaj gönderme alanı
          if (_isMember || _isOwner)
            _buildModernMessageInput(),
        ],
      ),
    );
  }

  Widget _buildModernMessageInput() {
    final messageController = TextEditingController();
    bool isLoading = false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A), // Koyu gri arka plan
        border: Border(
          top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Medya butonları
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Galeri açma işlevi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Galeri özelliği yakında eklenecek!')),
                  );
                },
                icon: const Icon(Icons.photo_library, color: Colors.grey),
              ),
              IconButton(
                onPressed: () {
                  // Konum paylaşma işlevi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Konum paylaşma özelliği yakında eklenecek!')),
                  );
                },
                icon: const Icon(Icons.location_on, color: Colors.grey),
              ),
              IconButton(
                onPressed: () {
                  // Sesli mesaj işlevi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesli mesaj özelliği yakında eklenecek!')),
                  );
                },
                icon: const Icon(Icons.mic, color: Colors.grey),
              ),
            ],
          ),
          // Mesaj input alanı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty && !isLoading) {
                    await _sendMessage(value.trim(), messageController);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Gönder butonu
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6B46C1), // Mor renk
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : () async {
                if (messageController.text.trim().isNotEmpty) {
                  await _sendMessage(messageController.text.trim(), messageController);
                }
              },
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message, TextEditingController controller) async {
    setState(() {
      // Loading state'i burada yönetilebilir
    });

    try {
      await _groupService.sendGroupMessage(widget.groupId, message);
      controller.clear();
      _loadGroupData(); // Mesajları yeniden yükle
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMembersTab() {
    final members = widget.groupData['members'] as List<dynamic>? ?? [];
    final moderators = widget.groupData['moderators'] as List<dynamic>? ?? [];
    final owner = widget.groupData['owner'];
    
    // Grup sahibini üyeler listesinden çıkar
    final filteredMembers = members.where((member) => 
      member['id'] != owner['id']
    ).toList();
    
    return ListView(
      children: [
        // Grup sahibi
        _buildMemberItem(owner, 'Sahip'),
        // Moderatörler
        ...moderators.map((moderator) => _buildMemberItem(moderator, 'Moderatör')),
        // Üyeler (grup sahibi hariç)
        ...filteredMembers.map((member) => _buildMemberItem(member, 'Üye')),
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
    // Zaten üye veya sahip ise işlem yapma
    if (_isMember || _isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaten bu grubun üyesisiniz!')),
      );
      return;
    }

    try {
      if (widget.groupData['join_type'] == 'public') {
        // Direkt katıl
        await _groupService.joinGroup(widget.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruba başarıyla katıldınız!')),
        );
        // Kullanıcı durumunu yeniden kontrol et
        _checkUserStatus();
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
      // Kullanıcı durumunu ve grup verilerini yeniden yükle
      _checkUserStatus();
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
      // Sadece grup verilerini yeniden yükle (kullanıcı durumu değişmez)
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
