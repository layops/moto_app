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
    final profilePicture = user['profile_picture'];
    final userId = user['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: profilePicture != null
              ? NetworkImage(profilePicture)
              : null,
          child: profilePicture == null
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
    final groupImage = group['image'];
    final groupId = group['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: groupImage != null
              ? NetworkImage(groupImage)
              : null,
          child: groupImage == null
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
        onTap: () => _navigateToGroupDetail(context, groupId),
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

  void _navigateToGroupDetail(BuildContext context, int groupId) {
    // GroupDetailPage için gerekli parametreleri sağlamamız gerekiyor
    // Şimdilik basit bir çözüm olarak boş groupData ile oluşturuyoruz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(
          groupId: groupId,
          groupData: {}, // Boş data ile başlatıyoruz, sayfa kendi verilerini yükleyecek
          authService: ServiceLocator.auth,
        ),
      ),
    );
  }
}

