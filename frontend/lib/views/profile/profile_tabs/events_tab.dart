import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class EventsTab extends StatelessWidget {
  final List<dynamic>? events;
  final ThemeData theme;

  const EventsTab({super.key, required this.events, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (events == null || events!.isEmpty) {
      return Center(
        child: Text('Henüz etkinlik yok', style: theme.textTheme.bodyLarge),
      );
    }
    return ListView.builder(
      itemCount: events!.length,
      itemBuilder: (context, index) {
        final event = events![index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: ThemeConstants.paddingMedium,
            child: Text(event['title'] ?? ''),
          ),
        );
      },
    );
  }
}
