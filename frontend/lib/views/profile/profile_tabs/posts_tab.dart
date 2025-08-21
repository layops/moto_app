import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class PostsTab extends StatelessWidget {
  final List<dynamic>? posts;
  final ThemeData theme;

  const PostsTab({super.key, required this.posts, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (posts == null || posts!.isEmpty) {
      return Center(
        child: Text('Henüz gönderi yok', style: theme.textTheme.bodyLarge),
      );
    }
    return ListView.builder(
      itemCount: posts!.length,
      itemBuilder: (context, index) {
        final post = posts![index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: ThemeConstants.paddingMedium,
            child: Text(post['content'] ?? ''),
          ),
        );
      },
    );
  }
}
