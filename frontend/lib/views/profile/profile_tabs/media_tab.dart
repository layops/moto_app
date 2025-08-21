import 'package:flutter/material.dart';

class MediaTab extends StatelessWidget {
  final List<dynamic>? media;
  final ThemeData theme;

  const MediaTab({super.key, required this.media, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (media == null || media!.isEmpty) {
      return Center(
        child: Text('Henüz medya yok', style: theme.textTheme.bodyLarge),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: media!.length,
      itemBuilder: (context, index) {
        final item = media![index];
        return Image.network(item['url'], fit: BoxFit.cover);
      },
    );
  }
}
