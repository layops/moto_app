import 'package:flutter/material.dart';
import '../../widgets/post/post_item.dart';
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
    if (loading) return _buildLoading();
    if (error != null) return _buildError(context);
    if (posts.isEmpty) return const HomeEmptyState();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
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

          // Debug için post verisini yazdır
          print('Post data: $post');

          // Author bilgisini güvenli şekilde işle
          dynamic authorData =
              post['author'] ?? post['user']; // 'author' veya 'user' anahtarı
          Map<String, dynamic> authorMap = {};

          if (authorData is Map<String, dynamic>) {
            authorMap.addAll(authorData);
          } else if (authorData is int) {
            // Author ID olarak geliyorsa, burada kullanıcı bilgilerini çekmemiz gerekebilir
            authorMap['id'] = authorData;
            authorMap['username'] = 'Kullanıcı $authorData';
            print('Author ID olarak geldi: $authorData');
          } else if (authorData != null) {
            print('Beklenmeyen author veri türü: ${authorData.runtimeType}');
          }

          // Eksik author bilgilerini doldur
          if (authorMap['username'] == null) {
            authorMap['username'] = 'Bilinmeyen';
          }
          if (authorMap['display_name'] == null) {
            authorMap['display_name'] = authorMap['username'];
          }
          if (authorMap['profile_photo'] == null &&
              authorMap['avatar'] != null) {
            authorMap['profile_photo'] = authorMap['avatar'];
          }

          post['author'] = authorMap;

          return PostItem(post: post);
        },
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text(error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => onRefresh(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
}
