import 'package:flutter/material.dart';
import '../../../widgets/post/post_item.dart';

class PostsTab extends StatelessWidget {
  final List<dynamic> posts;
  final ThemeData theme;
  final String username;
  final String? avatarUrl;
  final String? displayName;
  final String? error;

  const PostsTab({
    super.key,
    required this.posts,
    required this.theme,
    required this.username,
    this.avatarUrl,
    this.displayName,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {},
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
        final originalPost = posts[index];

        // Önce post verisini güvenli bir şekilde kopyala
        final Map<String, dynamic> post = {};

        if (originalPost is Map<String, dynamic>) {
          post.addAll(originalPost);
        } else {
          // Eğer post bir Map değilse, içeriği 'content' alanına koy
          post['content'] = originalPost.toString();
        }

        // Author bilgisini güvenli şekilde işle
        dynamic authorData = post['author'];
        Map<String, dynamic> authorMap = {};

        if (authorData is Map<String, dynamic>) {
          authorMap.addAll(authorData);
        } else if (authorData != null) {
          // Author bilgisi beklenmeyen bir türdeyse, logla ve boş bırak
          print('Beklenmeyen author veri türü: ${authorData.runtimeType}');
        }

        // Eksik author bilgilerini doldur
        if (authorMap['username'] == null) {
          authorMap['username'] = username;
        }
        if (authorMap['profile_photo'] == null && avatarUrl != null) {
          authorMap['profile_photo'] = avatarUrl;
        }
        if (authorMap['display_name'] == null) {
          authorMap['display_name'] = displayName ?? username;
        }

        post['author'] = authorMap;

        return PostItem(post: post);
      },
    );
  }
}
