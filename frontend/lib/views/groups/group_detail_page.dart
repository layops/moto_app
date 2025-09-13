import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/group/group_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'package:motoapp_frontend/widgets/post/post_item.dart';
import 'group_messages_page.dart';
import 'group_settings_page.dart';
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
  String? _currentUsername;
  List<dynamic> _posts = [];
  bool _loading = false;
  String? _error;
  bool _requestSent = false;
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
      _currentUsername = await widget.authService.getCurrentUsername();
      if (_currentUsername == null) return;

      final groupOwner = widget.groupData['owner']?['username'];
      final groupMembers = List<Map<String, dynamic>>.from(
        widget.groupData['members'] ?? [],
      );

      setState(() {
        _isOwner = _currentUsername == groupOwner;
        _isMember = groupMembers.any((member) => member['username'] == _currentUsername);
        _isModerator = false; // Şimdilik moderator özelliği yok
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _groupService.getGroupPosts(widget.groupId);
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      await _groupService.deleteGroupPost(widget.groupId, postId);
      setState(() {
        _posts.removeWhere((post) => post['id'] == postId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post silinemedi: $e')),
        );
      }
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

  void _showGroupSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsPage(
          groupId: widget.groupId,
          groupData: widget.groupData,
          authService: widget.authService,
        ),
      ),
    );

    // Eğer grup silindi ise önceki sayfaya dön
    if (result == 'deleted') {
      Navigator.pop(context, 'deleted');
      return;
    }

    // Eğer ayarlar güncellendi ise grup verilerini yeniden yükle
    if (result == true) {
      try {
        final updatedGroupData = await _groupService.getGroupDetails(widget.groupId);
        setState(() {
          // widget.groupData'yi güncelle
          widget.groupData.clear();
          widget.groupData.addAll(updatedGroupData);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup ayarları güncellendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup verileri yenilenemedi: $e')),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Grup bilgileri yükleniyor...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Grup Bilgileri Yüklenemedi',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _checkUserStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupData['name'] ?? 'Grup',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: colorScheme.primary,
              ),
              onPressed: () => _showGroupSettings(),
            ),
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Modern grup header
                      _buildModernGroupHeader(),
                      const SizedBox(height: 32),

                      // Katılma butonu
                      _buildJoinButton(),
                      const SizedBox(height: 24),

                      // About bölümü
                      _buildAboutSection(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupName = widget.groupData['name'] ?? 'Grup Adı';
    final memberCount = widget.groupData['member_count'] ?? 0;
    final profilePictureUrl = widget.groupData['profile_picture_url'];
    
    
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
            children: [
                // Grup logosu
                Center(
                    child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                            border: Border.all(
                              color: colorScheme.surface, 
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                        ),
                        child: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                    profilePictureUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultLogo();
                                    },
                                ),
                              )
                            : _buildDefaultLogo(),
                    ),
                ),
                const SizedBox(height: 24),
                
                            // Butonlar - yan yana
                            Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                    _buildActionButton(
                                        icon: Icons.chat_bubble_outline_rounded,
                                        label: 'Mesaj',
                                        onTap: _navigateToGroupChat,
                                        color: colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.post_add_rounded,
                                        label: 'Gönderi',
                                        onTap: _createPost,
                                        color: colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.person_add_rounded,
                                        label: 'Davet',
                                        onTap: _inviteMembers,
                                        color: colorScheme.primary,
                                    ),
                                    _buildActionButton(
                                        icon: Icons.exit_to_app_rounded,
                                        label: 'Ayrıl',
                                        onTap: _isMember ? _leaveGroup : null,
                                        color: colorScheme.error,
                                    ),
                                ],
                            ),
          const SizedBox(height: 24),
          
          // Grup adı - ortalanmış
          Center(
            child: Text(
              groupName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          
          // Üye sayısı - ortalanmış ve tıklanabilir
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MembersPage(
                      groupData: widget.groupData,
                      isOwner: widget.groupData['owner'] == _currentUsername,
                      isModerator: false, // Şimdilik false, gerekirse eklenebilir
                      authService: Provider.of<AuthService>(context, listen: false),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$memberCount üye',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          color: Theme.of(context).colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: color == colorScheme.error 
                  ? colorScheme.onError 
                  : colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color == colorScheme.error 
                      ? colorScheme.onError 
                      : colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = widget.groupData['description'] ?? '';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description.isNotEmpty 
                ? description 
                : 'Henüz açıklama eklenmemiş.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }


  Widget _buildPostsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gönderiler',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_posts.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.post_add_outlined,
                  color: colorScheme.primary.withOpacity(0.7),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Henüz gönderi yok',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'İlk gönderiyi sen paylaş!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: widget.authService.getCurrentUsername(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) {
          return Column(
            children: _posts.take(3).map((post) => PostItem(post: post)).toList(),
          );
        }

        return Column(
          children: _posts.take(3).map((post) {
            final isPostAuthor = post['author']?['username'] == currentUser;
            final isGroupOwner = widget.groupData['owner']?['username'] == currentUser;
            final canDelete = isPostAuthor || isGroupOwner;
            
            return PostItem(
              post: post,
              canDelete: canDelete,
              onDelete: canDelete ? () => _deletePost(post['id']) : null,
            );
          }).toList(),
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

  Widget _buildJoinButton() {
    final requiresApproval = widget.groupData['requires_approval'] as bool? ?? false;
    
    // Eğer kullanıcı zaten üyeyse veya sahipse buton gösterme
    if (_isMember || _isOwner) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _joinGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _getButtonText(requiresApproval),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _getButtonText(bool requiresApproval) {
    if (requiresApproval && _requestSent) {
      return 'İsteğiniz Gönderildi';
    } else {
      return 'Gruba Katıl';
    }
  }

  Future<void> _joinGroup() async {
    final requiresApproval = widget.groupData['requires_approval'] as bool? ?? false;
    
    if (requiresApproval) {
      // Onay gerektiren grup için mesaj dialog'u göster
      final message = await _showJoinRequestDialog();
      if (message == null) return; // Kullanıcı iptal etti
      
      try {
        await _groupService.joinGroup(widget.groupId, message: message);
        if (!mounted) return;
        
        setState(() {
          _requestSent = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Katılım isteği gönderildi. Onay bekleniyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek gönderilemedi: $e')),
        );
      }
    } else {
      // Onay gerektirmeyen grup için direkt katıl
      try {
        await _groupService.joinGroup(widget.groupId);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gruba başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        _checkUserStatus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılamadı: $e')),
        );
      }
    }
  }

  Future<String?> _showJoinRequestDialog() async {
    String message = '';
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Katılım İsteği'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bu gruba katılmak için grup sahibinden onay gerekiyor.'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mesaj (isteğe bağlı)',
                  hintText: 'Katılmak istediğinizi belirten bir mesaj yazabilirsiniz...',
                ),
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(message),
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
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
    final canPost = hasText; // Content zorunlu, resim opsiyonel
    
    
    return canPost;
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

