import 'package:flutter/material.dart';
import '../../views/profile/profile_page.dart';

class PostItem extends StatelessWidget {
  final dynamic post;
  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final authorData = post['author'] is Map<String, dynamic>
        ? post['author'] as Map<String, dynamic>
        : {};

    final username = authorData['username']?.toString() ??
        post['username']?.toString() ??
        'Bilinmeyen';

    final profilePhoto = authorData['profile_photo_url']?.toString() ??
        authorData['profile_picture']?.toString() ??
        post['profile_photo']?.toString() ??
        post['avatar']?.toString();

    final displayName = authorData['display_name']?.toString() ??
        authorData['first_name']?.toString() ??
        username;

    final imageUrl = post['image']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.3),
          bottom: BorderSide(color: Colors.grey, width: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgisi
          InkWell(
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      profilePhoto != null && profilePhoto.isNotEmpty
                          ? NetworkImage(profilePhoto)
                          : null,
                  onBackgroundImageError:
                      profilePhoto != null && profilePhoto.isNotEmpty
                          ? (exception, stackTrace) {
                              debugPrint(
                                  'Profile photo loading failed: $exception');
                            }
                          : null,
                  child: profilePhoto == null || profilePhoto.isEmpty
                      ? const Icon(Icons.person, size: 22)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19, // Kullanıcı adı daha büyük
                      color: Colors.black87, // Daha belirgin renk
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Post içeriği (daha belirgin ve büyük yazı)
          if (post['content'] != null && post['content'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                post['content'].toString(),
                style: const TextStyle(
                  fontSize: 15, // Metin boyutu büyütüldü
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(171, 17, 17, 17),
                  height: 1.5,
                ),
              ),
            ),

          // Post görseli
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),

          // Beğeni, yorum ve paylaşım butonları
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 22),
                  onPressed: () {},
                ),
                Text(post['likes']?.toString() ?? '0'),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, size: 22),
                  onPressed: () {},
                ),
                Text(post['comments']?.toString() ?? '0'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
