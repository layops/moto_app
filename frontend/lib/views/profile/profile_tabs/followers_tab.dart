import 'package:flutter/material.dart';

class FollowersTab extends StatelessWidget {
  final List<dynamic> followers;
  final ThemeData? theme;

  const FollowersTab({super.key, required this.followers, this.theme});

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? Theme.of(context);

    if (followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: currentTheme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz takipçiniz yok',
                style: currentTheme.textTheme.bodyLarge?.copyWith(
                  color: currentTheme.colorScheme.onSurface.withOpacity(0.7),
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
                ? Icon(Icons.person, color: currentTheme.colorScheme.onSurface)
                : null,
          ),
          title: Text(follower['username'] ?? ''),
          subtitle: Text('${follower['followerCount'] ?? 0} takipçi'),
          trailing: ElevatedButton(
            onPressed: () {
              // Takip et/çık butonu işlevi
            },
            child: const Text('Takip Et'),
          ),
        );
      },
    );
  }
}
