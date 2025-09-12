import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/color_schemes.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';

class PostCommentsPage extends StatefulWidget {
  final int postId;
  final String postContent;
  final String authorUsername;

  const PostCommentsPage({
    super.key,
    required this.postId,
    required this.postContent,
    required this.authorUsername,
  });

  @override
  State<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final comments = await ServiceLocator.posts.getPostComments(widget.postId);
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ServiceLocator.posts.createComment(
        widget.postId,
        _commentController.text.trim(),
      );

      _commentController.clear();
      await _loadComments();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenemedi: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await ServiceLocator.posts.deleteComment(widget.postId, commentId);
      await _loadComments();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum silinemedi: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yorumlar',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Post preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorUsername,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.postContent,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _buildCommentsList(colorScheme),
          ),
          
          // Comment input
          _buildCommentInput(colorScheme),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Yorumlar yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz yorum yok',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk yorumu sen yap!',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment, colorScheme);
      },
    );
  }

  Widget _buildCommentItem(dynamic comment, ColorScheme colorScheme) {
    final author = comment['author'] as Map<String, dynamic>? ?? {};
    final username = author['username']?.toString() ?? 'Bilinmeyen';
    final content = comment['content']?.toString() ?? '';
    final createdAt = comment['created_at']?.toString() ?? '';
    final commentId = comment['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: author['profile_photo_url'] != null
                ? NetworkImage(author['profile_photo_url'].toString())
                : null,
            child: author['profile_photo_url'] == null
                ? Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Yorum yaz...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _isSubmitting ? null : _submitComment,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

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
}
