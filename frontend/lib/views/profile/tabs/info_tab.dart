import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const InfoTab({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.email, color: theme.colorScheme.primary),
          title: const Text('Email'),
          subtitle: Text(profileData['email'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
          title: const Text('Üyelik Tarihi'),
          subtitle: Text(profileData['joined'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
          title: const Text('Konum'),
          subtitle: Text(profileData['location'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.motorcycle, color: theme.colorScheme.primary),
          title: const Text('Motor Modeli'),
          subtitle: Text(profileData['motor'] ?? 'Bilgi yok'),
        ),
      ],
    );
  }
}
