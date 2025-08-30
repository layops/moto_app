import 'package:flutter/material.dart';
import '../../views/profile/profile_page.dart';
import '../../core/theme/color_schemes.dart';

class PostItem extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              routeData['title']?.toString() ?? 'Rota İsmi',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Rota bilgileri
            Row(
              children: [
                Icon(Icons.add_road_sharp,
                    size: 16, color: AppColorSchemes.textSecondary),
                const SizedBox(width: 4),
                Text(
                  routeData['distance']?.toString() ?? '0 km',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColorSchemes.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer,
                    size: 16, color: AppColorSchemes.textSecondary),
                const SizedBox(width: 4),
                Text(
                  routeData['duration']?.toString() ?? '0s',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColorSchemes.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getDifficultyColor(context, routeData['difficulty']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    routeData['difficulty']?.toString() ?? 'Bilinmiyor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyTextColor(
                          context, routeData['difficulty']),
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
                      ? Icon(Icons.person,
                          size: 20, color: theme.colorScheme.onSurface)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorSchemes.textPrimary,
                        ),
                      ),
                      Text(
                        '${post['bikeModel'] ?? 'Motosiklet'} • ${post['timeAgo'] ?? 'Şimdi'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColorSchemes.textSecondary,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColorSchemes.textPrimary,
                  ),
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
                    icon: Icon(Icons.favorite_border,
                        size: 20, color: theme.colorScheme.primary),
                    onPressed: () {},
                  ),
                  Text(
                    post['likes']?.toString() ?? '0',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.comment_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    onPressed: () {},
                  ),
                  Text(
                    post['comments']?.toString() ?? '0',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.share,
                        size: 20, color: theme.colorScheme.primary),
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

  Color _getDifficultyColor(BuildContext context, String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'kolay':
      case 'easy':
        return AppColorSchemes.difficultyEasy(context).withOpacity(0.1);
      case 'moderate':
        return AppColorSchemes.difficultyModerate(context).withOpacity(0.1);
      case 'expert':
        return AppColorSchemes.difficultyExpert(context).withOpacity(0.1);
      default:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  Color _getDifficultyTextColor(BuildContext context, String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'kolay':
      case 'easy':
        return AppColorSchemes.difficultyEasy(context);
      case 'moderate':
        return AppColorSchemes.difficultyModerate(context);
      case 'expert':
        return AppColorSchemes.difficultyExpert(context);
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  void _openProfile(BuildContext context, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(username: username)),
    );
  }
}
