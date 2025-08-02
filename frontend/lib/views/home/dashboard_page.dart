import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String username;

  const DashboardPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        const AssetImage('assets/images/spiride_logo.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hoşgeldin, $username!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: theme.iconTheme.color),
              title: Text('Profil', style: theme.textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 250));
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.iconTheme.color),
              title: Text('Ayarlar', style: theme.textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 250));
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: theme.iconTheme.color),
              title: Text('Çıkış', style: theme.textTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 250));
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Dashboard İçeriği Burada',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
