import 'package:flutter/material.dart';

class MediaTab extends StatelessWidget {
  final List<dynamic> media;

  const MediaTab({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library,
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Henüz medya yok',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                )),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return Image.network(item['url'], fit: BoxFit.cover);
      },
    );
  }
}
