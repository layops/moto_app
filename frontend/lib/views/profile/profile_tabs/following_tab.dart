import 'package:flutter/material.dart';

class FollowingTab extends StatelessWidget {
  final List<dynamic> following;
  final ThemeData? theme;

  const FollowingTab({super.key, required this.following, this.theme});

  @override
  Widget build(BuildContext context) {
    final currentTheme = theme ?? Theme.of(context);

    if (following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled,
                size: 48,
                color: currentTheme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz kimseyi takip etmiyorsunuz',
                style: currentTheme.textTheme.bodyLarge?.copyWith(
                  color: currentTheme.colorScheme.onSurface.withOpacity(0.7),
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
                ? Icon(Icons.person, color: currentTheme.colorScheme.onSurface)
                : null,
          ),
          title: Text(user['username'] ?? ''),
          subtitle: Text('${user['followingCount'] ?? 0} takip'),
          trailing: OutlinedButton(
            onPressed: () {
              // Takibi bırak butonu işlevi
            },
            child: const Text('Takibi Bırak'),
          ),
        );
      },
    );
  }
}
