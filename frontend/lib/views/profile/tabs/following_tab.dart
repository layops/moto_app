import 'package:flutter/material.dart';

class FollowingTab extends StatelessWidget {
  final List<dynamic> following;

  const FollowingTab({super.key, required this.following});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz kimseyi takip etmiyorsunuz',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: following.length,
      itemBuilder: (context, index) {
        final user = following[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user['avatarUrl'] ?? ''),
            child: user['avatarUrl'] == null
                ? Icon(Icons.person, color: theme.colorScheme.onSurface)
                : null,
          ),
          title: Text(user['username'] ?? ''),
          subtitle: Text('${user['followingCount'] ?? 0} takip'),
          trailing: OutlinedButton(
            onPressed: () {},
            child: const Text('Takibi Bırak'),
          ),
        );
      },
    );
  }
}
