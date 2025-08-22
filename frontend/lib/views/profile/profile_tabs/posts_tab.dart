import 'package:flutter/material.dart';
import '../../../widgets/post/post_item.dart';

class PostsTab extends StatelessWidget {
  final List<dynamic> posts;
  final ThemeData theme;
  final String username;
  final String? avatarUrl;
  final String? error;

  const PostsTab({
    super.key,
    required this.posts,
    required this.theme,
    required this.username,
    this.avatarUrl,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    // Hata durumunu kontrol et
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              error!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Yeniden yükleme işlevi için bir callback ekleyebilirsiniz
              },
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz gönderi yok',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        // Post verisini kopyala ve author bilgilerini düzelt
        final post = Map<String, dynamic>.from(posts[index]);
        if (post['author'] == null) {
          post['author'] = {
            'username': username,
            'avatar': avatarUrl,
          };
        }
        return PostItem(post: post);
      },
    );
  }
}
