import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../views/profile/profile_page.dart';
import '../../views/posts/post_comments_page.dart';
import '../../core/theme/color_schemes.dart';
import '../../services/service_locator.dart';

class PostItem extends StatefulWidget {
  final dynamic post;
  final VoidCallback? onDelete;
  final bool canDelete;
  final Function(int postId)? onLike;
  final Function(int postId)? onComment;
  final Function(int postId)? onShare;
  
  const PostItem({
    super.key, 
    required this.post,
    this.onDelete,
    this.canDelete = false,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;
  bool _isLikeLoading = false;
  bool _isCommentLoading = false;

  @override
  void initState() {
    super.initState();
    // Backend'den gelen doğru alan adlarını kullan
    _likeCount = widget.post['likes_count'] ?? widget.post['likes'] ?? 0;
    _isLiked = widget.post['is_liked'] ?? false;
    
    // Debug için log ekle
    // debugPrint('PostItem initState - Post ID: ${widget.post['id']}');
    // debugPrint('  - Raw post data: ${widget.post}');
    // debugPrint('  - likes_count: ${widget.post['likes_count']}');
    // debugPrint('  - likes: ${widget.post['likes']}');
    // debugPrint('  - is_liked: ${widget.post['is_liked']}');
    // debugPrint('  - Final _likeCount: $_likeCount');
    // debugPrint('  - Final _isLiked: $_isLiked');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final authorData = widget.post['author'] is Map<String, dynamic>
        ? widget.post['author'] as Map<String, dynamic>
        : {};

    // Username'i güvenli şekilde al
    String username = 'Bilinmeyen';
    if (authorData.isNotEmpty && authorData['username'] != null) {
      username = authorData['username'].toString();
    } else if (widget.post['username'] != null) {
      username = widget.post['username'].toString();
    }

    final profilePhoto = authorData['profile_photo_url']?.toString() ??
        authorData['profile_picture']?.toString() ??
        widget.post['profile_photo']?.toString() ??
        widget.post['avatar']?.toString();

    final displayName = authorData['display_name']?.toString() ??
        authorData['first_name']?.toString() ??
        username;

    final imageUrl = widget.post['image_url']?.toString() ?? widget.post['image']?.toString();
    final postId = widget.post['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi header
          _buildUserHeader(context, username, profilePhoto, colorScheme),
          
          // Post içeriği
          if (widget.post['content'] != null && widget.post['content'].toString().isNotEmpty)
            _buildPostContent(context, colorScheme),

          // Post görseli
          if (imageUrl != null && imageUrl.isNotEmpty)
            _buildPostImage(context, imageUrl, colorScheme),

          // Aksiyon butonları
          _buildActionButtons(context, postId, colorScheme),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, String username, String? profilePhoto, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          if (username.isNotEmpty && username != 'Bilinmeyen') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(username: username),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                  ? NetworkImage(profilePhoto)
                  : null,
              onBackgroundImageError: profilePhoto != null && profilePhoto.isNotEmpty
                  ? (exception, stackTrace) {
                      // debugPrint('Profile photo loading failed: $exception');
                    }
                  : null,
              child: profilePhoto == null || profilePhoto.isEmpty
                  ? Icon(Icons.person, size: 20, color: colorScheme.primary)
                  : null,
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
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _formatDate(widget.post['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.canDelete && widget.onDelete != null) ...[
              Builder(
                builder: (context) {
                  return _buildDeleteButton(context, colorScheme);
                },
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  return const SizedBox.shrink();
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.post['content'].toString(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPostImage(BuildContext context, String imageUrl, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 250,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              color: colorScheme.surface,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 250,
            color: colorScheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Görsel yüklenemedi',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteDialog(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Postu Sil',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurface.withOpacity(0.6),
        size: 20,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, int postId, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _likeCount.toString(),
            color: _isLiked ? Colors.red : colorScheme.onSurface.withOpacity(0.7),
            onTap: _isLikeLoading ? null : () => _handleLike(postId),
            isLoading: _isLikeLoading,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: (widget.post['comments_count'] ?? widget.post['comments'] ?? 0).toString(),
            color: colorScheme.onSurface.withOpacity(0.7),
            onTap: _isCommentLoading ? null : () => _handleComment(postId),
            isLoading: _isCommentLoading,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Paylaş',
            color: colorScheme.onSurface.withOpacity(0.7),
            onTap: () => _handleShare(postId),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper metodları
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
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
      return '';
    }
  }

  void _handleLike(int postId) async {
    if (_isLikeLoading) return;
    
    // debugPrint('_handleLike called for post $postId');
    // debugPrint('  - Current state: _isLiked=$_isLiked, _likeCount=$_likeCount');
    
    // Loading state'i başlat
    setState(() {
      _isLikeLoading = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      // API çağrısı yap
      final result = await ServiceLocator.posts.toggleLike(postId);
      
      // debugPrint('Like toggle result: $result');
      // debugPrint('  - is_liked: ${result['is_liked']}');
      // debugPrint('  - likes_count: ${result['likes_count']}');
      
      // API'den gelen gerçek değerleri güncelle
      if (mounted) {
        setState(() {
          _isLiked = result['is_liked'] ?? _isLiked;
          _likeCount = result['likes_count'] ?? _likeCount;
          _isLikeLoading = false;
        });
        
        // debugPrint('Updated state: _isLiked=$_isLiked, _likeCount=$_likeCount');
      }
    } catch (e) {
      // debugPrint('Like toggle error: $e');
      // Hata durumunda loading state'i sıfırla
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
        
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beğeni işlemi başarısız: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Callback'i çağır
    if (widget.onLike != null) {
      widget.onLike!(postId);
    }
  }

  void _handleComment(int postId) {
    // debugPrint('_handleComment called for post $postId');
    // debugPrint('  - _isCommentLoading: $_isCommentLoading');
    // debugPrint('  - widget.onComment: ${widget.onComment != null}');
    
    if (_isCommentLoading) {
      // debugPrint('  - Comment loading, returning early');
      return;
    }
    
    HapticFeedback.lightImpact();
    
    if (widget.onComment != null) {
      // debugPrint('  - Calling widget.onComment callback');
      widget.onComment!(postId);
    } else {
      // debugPrint('  - Navigating to comments page');
      // Yorum sayfasına git
      _navigateToComments(postId);
    }
  }
  
  void _navigateToComments(int postId) {
    // debugPrint('_navigateToComments called for post $postId');
    
    final authorData = widget.post['author'] is Map<String, dynamic>
        ? widget.post['author'] as Map<String, dynamic>
        : {};
    
    String username = 'Bilinmeyen';
    if (authorData.isNotEmpty && authorData['username'] != null) {
      username = authorData['username'].toString();
    } else if (widget.post['username'] != null) {
      username = widget.post['username'].toString();
    }
    
    final postContent = widget.post['content']?.toString() ?? '';
    
    // debugPrint('  - Username: $username');
    // debugPrint('  - Post content: $postContent');
    // debugPrint('  - Navigating to PostCommentsPage');
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostCommentsPage(
            postId: postId,
            postContent: postContent,
            authorUsername: username,
          ),
        ),
      );
      // debugPrint('  - Navigation successful');
    } catch (e) {
      // debugPrint('  - Navigation error: $e');
    }
  }

  void _handleShare(int postId) {
    HapticFeedback.lightImpact();
    if (widget.onShare != null) {
      widget.onShare!(postId);
    } else {
      // Varsayılan davranış - paylaşım menüsü göster
      _showShareDialog(context, postId);
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Postu Sil',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bu postu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            child: Text(
              'Sil',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Postu Paylaş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  Icons.copy,
                  'Kopyala',
                  () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: widget.post['content'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post metni kopyalandı')),
                    );
                  },
                ),
                _buildShareOption(
                  context,
                  Icons.share,
                  'Paylaş',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Paylaşım özelliği yakında eklenecek')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
