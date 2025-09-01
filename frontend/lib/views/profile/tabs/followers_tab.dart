import 'package:flutter/material.dart';

class FollowersTab extends StatelessWidget {
  final List<dynamic> followers;

  const FollowersTab({super.key, required this.followers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz takipçiniz yok',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                )),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(follower['avatarUrl'] ?? ''),
            child: follower['avatarUrl'] == null
                ? Icon(Icons.person, color: theme.colorScheme.onSurface)
                : null,
          ),
          title: Text(follower['username'] ?? ''),
          subtitle: Text('${follower['followerCount'] ?? 0} takipçi'),
          trailing: ElevatedButton(
            onPressed: () {},
            child: const Text('Takip Et'),
          ),
        );
      },
    );
  }
}
