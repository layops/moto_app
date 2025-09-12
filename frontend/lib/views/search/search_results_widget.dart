import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../models/search_models.dart';
import '../profile/profile_page.dart';
import '../groups/group_detail_page.dart';

class SearchResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final SearchResultType type;
  final String query;

  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.type,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    
    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultItem(context, item);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    String suggestion;
    IconData icon;
    
    switch (type) {
      case SearchResultType.users:
        message = '"$query" için kullanıcı bulunamadı';
        suggestion = 'Farklı bir kullanıcı adı veya isim deneyin';
        icon = Icons.person_search;
        break;
      case SearchResultType.groups:
        message = '"$query" için grup bulunamadı';
        suggestion = 'Farklı bir grup adı deneyin';
        icon = Icons.group;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              suggestion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '💡 İpucu: En az 2 karakter girin ve mevcut kullanıcı/grup adlarını deneyin',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, Map<String, dynamic> item) {
    switch (type) {
      case SearchResultType.users:
        return _buildUserItem(context, item);
      case SearchResultType.groups:
        return _buildGroupItem(context, item);
    }
  }

  Widget _buildUserItem(BuildContext context, Map<String, dynamic> user) {
    final username = user['username'] ?? 'Bilinmeyen Kullanıcı';
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    // Backend'den gelen alan adı 'profile_picture', 'profile_photo_url' değil
    final profilePhotoUrl = user['profile_picture'] ?? user['profile_photo_url'];
    final userId = user['id'];
    
    // Debug için profil fotoğrafı URL'ini log'la
    

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          child: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    profilePhotoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 18),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18),
                ),
        ),
        title: Text(
          fullName.isNotEmpty ? fullName : username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: fullName.isNotEmpty
            ? Text('@$username')
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToUserProfile(context, user),
      ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Map<String, dynamic> group) {
    final name = group['name'] ?? 'Bilinmeyen Grup';
    final description = group['description'] ?? '';
    final memberCount = group['member_count'] ?? 0;
    // Backend'den gelen alan adı 'profile_picture', 'profile_picture_url' değil
    final profilePictureUrl = group['profile_picture'] ?? group['profile_picture_url'];
    final groupId = group['id'];
    
    // Debug için grup profil fotoğrafı URL'ini log'la
    

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          child: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    profilePictureUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.group, size: 24);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                )
              : const Icon(Icons.group, size: 24),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              '$memberCount üye',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToGroupDetail(context, group),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context, Map<String, dynamic> user) {
    final username = user['username'];
    if (username != null && username.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(username: username),
        ),
      );
    } else {
      // Username yoksa hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToGroupDetail(BuildContext context, Map<String, dynamic> group) {
    // GroupDetailPage için grup verilerini geçiyoruz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(
          groupId: group['id'],
          groupData: group, // Arama sonuçlarından gelen grup verilerini geçiyoruz
          authService: ServiceLocator.auth,
        ),
      ),
    );
  }
}

