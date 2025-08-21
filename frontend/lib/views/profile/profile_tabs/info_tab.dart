import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const InfoTab({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final profile = profileData ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.email),
          title: Text('Email'),
          subtitle: Text(profile['email'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Üyelik Tarihi'),
          subtitle: Text(profile['joined'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Konum'),
          subtitle: Text(profile['location'] ?? 'Bilgi yok'),
        ),
        ListTile(
          leading: Icon(Icons.motorcycle),
          title: Text('Motor Modeli'),
          subtitle: Text(profile['motor'] ?? 'Bilgi yok'),
        ),
      ],
    );
  }
}
