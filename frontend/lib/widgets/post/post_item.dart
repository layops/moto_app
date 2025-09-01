import 'package:flutter/material.dart';
import '../../views/profile/profile_page.dart';

class PostItem extends StatelessWidget {
  final dynamic post;
  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Author verisi artık nested UserSerializer ile geliyor
    final authorData = post['author'] is Map<String, dynamic>
        ? post['author'] as Map<String, dynamic>
        : {};

    final routeData = post['route'] is Map<String, dynamic>
        ? post['route'] as Map<String, dynamic>
        : {};

    final username = authorData['username']?.toString() ??
        post['username']?.toString() ??
        'Bilinmeyen';

    /// Profil fotoğrafı backend'den gelen profile_photo_url ile alınacak
    final profilePhoto = authorData['profile_photo_url']?.toString() ??
        authorData['profile_picture']?.toString() ??
        post['profile_photo']?.toString() ??
        post['avatar']?.toString();

    final displayName = authorData['display_name']?.toString() ??
        authorData['first_name']?.toString() ??
        username;

    final imageUrl = post['image']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (routeData['title'] != null)
              Text(
                routeData['title']!.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),
            if (routeData.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.add_road_sharp,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${routeData['distance']?.toString() ?? '0'} km',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${routeData['duration']?.toString() ?? '0'} dk',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  if (routeData['difficulty'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                            routeData['difficulty']?.toString()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        routeData['difficulty']!.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDifficultyTextColor(
                              routeData['difficulty']?.toString()),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            // Kullanıcı bilgileri - Tıklanabilir hale getirildi
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
                    radius: 20,
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
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${post['bikeModel']?.toString() ?? 'Motosiklet'} • ${post['timeAgo']?.toString() ?? 'Şimdi'}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (post['content'] != null &&
                post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  post['content'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
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
      case 'orta':
        return Colors.orange[100]!;
      case 'zor':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getDifficultyTextColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'kolay':
        return Colors.green[800]!;
      case 'orta':
        return Colors.orange[800]!;
      case 'zor':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }
}
