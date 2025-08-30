// post_item.dart
import 'package:flutter/material.dart';
import '../../views/profile/profile_page.dart';

class PostItem extends StatelessWidget {
  final dynamic post;
  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // API'den gelen veri yapısına göre düzenleme
    final authorData = post['author'] as Map<String, dynamic>?;
    final username = authorData?['username']?.toString() ?? 'Bilinmeyen';
    final avatarUrl = authorData?['avatar']?.toString();
    final imageUrl = post['image']?.toString();
    final routeData = post['route'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rota başlığı
            Text(
              routeData['title'] ?? 'Rota İsmi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Rota bilgileri
            Row(
              children: [
                const Icon(Icons.add_road_sharp, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  routeData['distance'] ?? '0 km',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  routeData['duration'] ?? '0s',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(routeData['difficulty']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    routeData['difficulty'] ?? 'Bilinmiyor',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDifficultyTextColor(routeData['difficulty']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kullanıcı bilgileri
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${post['bikeModel'] ?? 'Motosiklet'} • ${post['timeAgo'] ?? 'Şimdi'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gönderi içeriği
            if (post['content'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  post['content'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            // Gönderi görseli
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),

            // Etkileşim butonları
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 20),
                    onPressed: () {},
                  ),
                  Text(post['likes']?.toString() ?? '0'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, size: 20),
                    onPressed: () {},
                  ),
                  Text(post['comments']?.toString() ?? '0'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'kolay':
        return Colors.green[100]!;
      case 'moderate':
        return Colors.orange[100]!;
      case 'expert':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getDifficultyTextColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'kolay':
        return Colors.green[800]!;
      case 'moderate':
        return Colors.orange[800]!;
      case 'expert':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  // ignore: unused_element
  void _openProfile(BuildContext context, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(username: username)),
    );
  }
}
