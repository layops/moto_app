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
        final String url = (item['url'] ?? '').toString();

        // Geçersiz/boş veya desteklenmeyen uzantıysa placeholder göster
        final bool isValidUrl = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
        final bool isPossiblyUnsupported = url.toLowerCase().endsWith('.svg') || url.toLowerCase().endsWith('.heic');

        if (!isValidUrl || isPossiblyUnsupported) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          );
        }

        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            );
          },
        );
      },
    );
  }
}
