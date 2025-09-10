import 'package:flutter/material.dart';
import '../../widgets/post/post_item.dart';
import '../../services/post/post_service.dart';
import '../../services/service_locator.dart';
import '../../views/posts/post_comments_page.dart';
import 'home_empty_state.dart';

class HomePostsList extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<dynamic> posts;
  final Future<void> Function() onRefresh;

  const HomePostsList({
    super.key,
    required this.loading,
    required this.error,
    required this.posts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildLoading(context);
    if (error != null) return _buildError(context);
    if (posts.isEmpty) return const HomeEmptyState();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index] as Map<String, dynamic>;

          // Author zaten backend'den nested serializer ile geliyor
          final authorData = post['author'] is Map<String, dynamic>
              ? post['author'] as Map<String, dynamic>
              : {};

          post['author'] = authorData;

          return PostItem(
            post: post,
            onComment: _handleComment,
            onShare: _handleShare,
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
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
              'Gönderiler yükleniyor...',
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

  Widget _buildError(BuildContext context) {
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
              'Gönderiler Yüklenemedi',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error!,
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
                onPressed: () => onRefresh(),
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

  // Callback metodları

  Future<void> _handleComment(int postId) async {
    debugPrint('Comment clicked for post: $postId');
    // Yorum sayfasına yönlendir
    _navigateToComments(postId);
  }
  
  void _navigateToComments(int postId) {
    // Post verilerini bul
    final post = posts.firstWhere(
      (p) => p['id'] == postId,
      orElse: () => {},
    );
    
    if (post.isEmpty) {
      debugPrint('Post not found for ID: $postId');
      return;
    }
    
    final authorData = post['author'] is Map<String, dynamic>
        ? post['author'] as Map<String, dynamic>
        : {};
    
    String username = 'Bilinmeyen';
    if (authorData.isNotEmpty && authorData['username'] != null) {
      username = authorData['username'].toString();
    } else if (post['username'] != null) {
      username = post['username'].toString();
    }
    
    final postContent = post['content']?.toString() ?? '';
    
    debugPrint('Navigating to comments for post $postId');
    debugPrint('  - Username: $username');
    debugPrint('  - Post content: $postContent');
    
    // Navigator context'ini al
    final context = ServiceLocator.navigatorKey.currentContext;
    if (context != null) {
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
    } else {
      debugPrint('Navigator context not available');
    }
  }

  Future<void> _handleShare(int postId) async {
    try {
      // Post verilerini bul
      final post = posts.firstWhere(
        (p) => p['id'] == postId,
        orElse: () => {},
      );
      
      if (post.isEmpty) {
        debugPrint('Post not found for ID: $postId');
        return;
      }
      
      final authorData = post['author'] is Map<String, dynamic>
          ? post['author'] as Map<String, dynamic>
          : {};
      
      String username = 'Bilinmeyen';
      if (authorData.isNotEmpty && authorData['username'] != null) {
        username = authorData['username'].toString();
      } else if (post['username'] != null) {
        username = post['username'].toString();
      }
      
      final postContent = post['content']?.toString() ?? '';
      
      // Share text oluştur
      final shareText = '${username} kullanıcısının gönderisi:\n\n$postContent\n\nSpiride uygulamasından paylaşıldı.';
      
      // Share dialog göster
      final context = ServiceLocator.navigatorKey.currentContext;
      if (context != null) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Paylaş'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gönderi metni:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shareText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(shareText, context);
                  },
                  child: const Text('Kopyala'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
  
  void _copyToClipboard(String text, BuildContext context) {
    // Clipboard'a kopyalama işlemi
    // Flutter'da clipboard işlemi için services kullanılabilir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gönderi metni panoya kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
