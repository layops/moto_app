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
    IconData icon;
    
    switch (type) {
      case SearchResultType.users:
        message = '"$query" için kullanıcı bulunamadı';
        icon = Icons.person_search;
        break;
      case SearchResultType.groups:
        message = '"$query" için grup bulunamadı';
        icon = Icons.group;
        break;
    }

    return Center(
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
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    final profilePhotoUrl = user['profile_photo_url'];
    final userId = user['id'];
    
    // Debug için kullanıcı verilerini yazdır
    print('Search Results - User ID: $userId');
    print('Search Results - Profile Photo URL: $profilePhotoUrl');
    print('Search Results - User Data: $user');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
              ? NetworkImage(profilePhotoUrl)
              : null,
          child: (profilePhotoUrl == null || profilePhotoUrl.isEmpty)
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18),
                )
              : null,
        ),
        title: Text(
          fullName.isNotEmpty ? fullName : username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: fullName.isNotEmpty
            ? Text('@$username')
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToUserProfile(context, userId),
      ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Map<String, dynamic> group) {
    final name = group['name'] ?? 'Bilinmeyen Grup';
    final description = group['description'] ?? '';
    final memberCount = group['member_count'] ?? 0;
    final profilePictureUrl = group['profile_picture_url'];
    final groupId = group['id'];
    
    // Debug için grup verilerini yazdır
    print('Search Results - Group ID: $groupId');
    print('Search Results - Profile Picture URL: $profilePictureUrl');
    print('Search Results - Group Data: $group');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
              ? NetworkImage(profilePictureUrl)
              : null,
          child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
              ? const Icon(Icons.group, size: 24)
              : null,
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

  void _navigateToUserProfile(BuildContext context, int userId) {
    // userId'den username'i almak için API çağrısı yapmamız gerekiyor
    // Şimdilik basit bir çözüm olarak userId'yi string'e çeviriyoruz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(username: userId.toString()),
      ),
    );
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

